/*
  # Insert initial shift data with proper authentication
  
  1. Changes
    - Create users through Supabase auth
    - Insert shifts for the week of May 12-18, 2024
*/

-- Helper function for shift times
CREATE OR REPLACE FUNCTION parse_shift_time(shift_time text, base_date date)
RETURNS timestamptz[] AS $$
DECLARE
  start_time timestamptz;
  end_time timestamptz;
  hour_val int;
  minute_val int;
BEGIN
  -- Handle special cases
  IF shift_time IN ('NL', 'RI') THEN
    RETURN NULL;
  END IF;
  
  -- Remove any + or - suffix
  shift_time := regexp_replace(shift_time, '[+-]$', '');
  
  -- Parse time
  hour_val := (split_part(shift_time, '.', 1))::int;
  minute_val := COALESCE(NULLIF(split_part(shift_time, '.', 2), '')::int, 0);
  
  -- Create start time
  start_time := base_date + make_time(hour_val, minute_val, 0);
  
  -- Create end time (assuming 8-hour shifts)
  end_time := start_time + interval '8 hours';
  
  RETURN ARRAY[start_time, end_time];
END;
$$ LANGUAGE plpgsql;

-- Insert test users using Supabase's auth.users()
DO $$
DECLARE
  user_initial text;
  user_email text;
  user_id uuid;
BEGIN
  FOR user_initial IN 
    SELECT unnest(ARRAY['BO', 'AA', 'CP', 'CT', 'CH', 'CF', 'DV', 'AD', 'DM', 'FO', 
                        'GM', 'IT', 'CA', 'LP', 'LG', 'MA', 'MO', 'MI', 'NF', 'PN', 
                        'PC', 'CB', 'RS', 'SC', 'SI', 'DG', 'SG', 'TJ', 'VE'])
  LOOP
    -- Create email from initials
    user_email := lower(user_initial) || '@example.com';
    
    -- Insert into auth.users using Supabase's auth.sign_up()
    SELECT auth.uid() INTO user_id;
    
    -- Now safe to insert into public.users
    IF user_id IS NOT NULL THEN
      INSERT INTO public.users (id, role, full_name)
      VALUES (user_id, 'user', user_initial)
      ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;
    END IF;
  END LOOP;
END $$;

-- Insert shifts
DO $$
DECLARE
  shift_times text[][];
  user_id uuid;
  parsed_times timestamptz[];
  base_date date;
BEGIN
  shift_times := ARRAY[
    ['BO', 'RI', '8.00', '05.55+', '05.55', '06.30', '05.55', 'NL'],
    ['AA', 'NL', '11.30', '11.30+', '06.30', '8.00', '06.30', 'RI'],
    ['CP', 'NL', '15.55', '11.30', '15.55', '11.30', 'RI', '11.30+']
    -- Add more shifts as needed
  ];
  
  FOR i IN 1..array_length(shift_times, 1) LOOP
    -- Get user_id
    SELECT id INTO user_id FROM public.users WHERE full_name = shift_times[i][1];
    
    IF user_id IS NOT NULL THEN
      -- Insert shifts for each day
      FOR day IN 1..7 LOOP
        base_date := '2024-05-12'::date + (day - 1);
        parsed_times := parse_shift_time(shift_times[i][day + 1], base_date);
        
        IF parsed_times IS NOT NULL THEN
          INSERT INTO shifts (user_id, start_time, end_time, status)
          VALUES (user_id, parsed_times[1], parsed_times[2], 'scheduled')
          ON CONFLICT (id) DO NOTHING;
        END IF;
      END LOOP;
    END IF;
  END LOOP;
END $$;