/*
  # Update shift schedule with complete data
  
  1. Changes
    - Update parse_shift_time to handle HH:MM format
    - Insert complete shift schedule for May 12-18, 2024
*/

-- Update helper function for shift times to handle HH:MM format
CREATE OR REPLACE FUNCTION parse_shift_time(shift_time text, base_date date)
RETURNS timestamptz[] AS $$
DECLARE
  start_time timestamptz;
  end_time timestamptz;
  hour_val int;
  minute_val int;
  clean_time text;
BEGIN
  -- Handle special cases
  IF shift_time IN ('NL', 'RI') THEN
    RETURN NULL;
  END IF;
  
  -- Remove any + or - suffix and convert to standard format
  clean_time := regexp_replace(shift_time, '[+-]$', '');
  
  -- Parse time (now handles both HH:MM and HH.MM formats)
  hour_val := (split_part(split_part(clean_time, ':', 1), '.', 1))::int;
  minute_val := COALESCE(
    NULLIF(split_part(clean_time, ':', 2), '')::int,
    NULLIF(split_part(clean_time, '.', 2), '')::int,
    0
  );
  
  -- Create start time
  start_time := base_date + make_time(hour_val, minute_val, 0);
  
  -- Create end time (8-hour shifts)
  end_time := start_time + interval '8 hours';
  
  RETURN ARRAY[start_time, end_time];
END;
$$ LANGUAGE plpgsql;

-- Insert complete shift schedule
DO $$
DECLARE
  shift_times text[][];
  user_id uuid;
  parsed_times timestamptz[];
  base_date date;
BEGIN
  shift_times := ARRAY[
    ['BO', 'RI', '8:00', '05:55+', '05:55', '06:30', '05:55', 'NL'],
    ['AA', 'NL', '11:30', '11:30+', '06:30', '8:00', '06:30', 'RI'],
    ['CP', 'NL', '15:55', '11:30', '15:55', '11:30', 'RI', '11:30+'],
    ['CT', '11:30', '15:55', '11:30', 'NL', 'RI', '05:00+', '00:00'],
    ['CH', '00:00', '00:00', 'NL', 'RI', '06:30', '06:30', '05:55+'],
    ['CF', '05:55+', 'NL', 'RI', '8:00', '05:55', '05:55', '05:55'],
    ['DV', '05:55', 'RI', 'NL', '05:55+', '05:55', '05:55', '09:00'],
    ['AD', '09:00', 'RI', '05:55', '09:00+', '09:00', '05:55', 'NL'],
    ['DM', 'RI', '05:55', '05:55', '05:55', '05:00+', '00:00', 'NL'],
    ['FO', 'NL', '15:55-', '15:55', '11:30', '11:30', '11:30', 'RI'],
    ['GM', 'NL', '05:55', '05:00+', '00:00', '00:00', 'RI', '09:00'],
    ['IT', '09:00+', '06:30', '06:30', '06:30', 'RI', 'NL', '05:55'],
    ['CA', '06:30', '05:00+', '00:00', 'RI', 'NL', '15:55', '11:30'],
    ['LP', '11:30', '12:45-', 'RI', 'NL', '11:30', '10:30', '06:30+'],
    ['LG', '15:55', 'RI', '12:45-', '15:55', '15:55', '12:45', 'NL'],
    ['MA', 'RI', '11:30-', '15:55', '12:45', '15:55', '15:55', 'NL'],
    ['MO', 'NL', '15:55', '15:55', '11:30', '11:30', '11:30-', 'RI'],
    ['MI', 'NL', '11:30+', '06:30', '05:00', 'NL', 'RI', '09:00'],
    ['NF', '05:55', '05:55+', '8:00', 'NL', 'RI', '06:30', '06:30'],
    ['PN', '06:30', '09:00', 'NL', 'RI', '15:55', '15:55', '15:55-'],
    ['PC', '11:30', 'NL', 'RI', '15:55', '15:55', '11:30-', '15:55'],
    ['CB', '15:55', 'RI', '15:55', '15:55', '12:45-', '15:55', 'NL'],
    ['RS', 'RI', '14:30', '10:30', '14:30', '10:30', '8:00+', 'NL'],
    ['SC', 'NL', '06:30', '05:00+', '00:00', '00:00', '00:00', 'RI'],
    ['SI', 'NL', '05:55', '05:55', '05:55', '06:30+', 'RI', '14:30'],
    ['DG', '14:30', '10:30', '06:30+', '05:00', 'RI', 'NL', '05:00'],
    ['SG', '05:00+', '00:00', '00:00', 'RI', 'NL', '14:30', '11:30'],
    ['TJ', '09:00', '05:00', 'RI', 'NL', '05:00', '05:00+', '00:00'],
    ['VE', '00:00', 'RI', '14:30', '10:30', '14:30', '11:30-', 'NL']
  ];
  
  FOR i IN 1..array_length(shift_times, 1) LOOP
    -- Get user_id for the initials
    SELECT id INTO user_id FROM public.users WHERE full_name = shift_times[i][1];
    
    IF user_id IS NOT NULL THEN
      -- Insert shifts for each day
      FOR day IN 1..7 LOOP
        base_date := '2024-05-12'::date + (day - 1);
        parsed_times := parse_shift_time(shift_times[i][day + 1], base_date);
        
        IF parsed_times IS NOT NULL THEN
          INSERT INTO shifts (user_id, start_time, end_time, status)
          VALUES (user_id, parsed_times[1], parsed_times[2], 'scheduled')
          ON CONFLICT (user_id, start_time) 
          DO UPDATE SET 
            end_time = EXCLUDED.end_time,
            status = EXCLUDED.status;
        END IF;
      END LOOP;
    END IF;
  END LOOP;
END $$;