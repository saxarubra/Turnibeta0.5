/*
  # Add initial shift data
  
  1. Changes
    - Add helper function for timestamp creation
    - Insert shifts for the week of May 12-18, 2024
*/

-- Helper function to create timestamp from date and time
CREATE OR REPLACE FUNCTION create_shift_time(shift_date DATE, shift_time TEXT)
RETURNS timestamptz AS $$
DECLARE
  hour_val INTEGER;
  minute_val INTEGER;
  shift_timestamp timestamptz;
BEGIN
  -- Handle special cases
  IF shift_time = 'NL' OR shift_time = 'RI' THEN
    RETURN NULL;
  END IF;
  
  -- Remove any + or - suffix
  shift_time := regexp_replace(shift_time, '[+-]$', '');
  
  -- Parse time string (format: HH.MM)
  hour_val := split_part(shift_time, '.', 1)::INTEGER;
  minute_val := COALESCE(NULLIF(split_part(shift_time, '.', 2), '')::INTEGER, 0);
  
  -- Create timestamp
  RETURN (shift_date + make_time(hour_val, minute_val, 0))::timestamptz;
END;
$$ LANGUAGE plpgsql;

-- Function to safely get or create a user
CREATE OR REPLACE FUNCTION get_or_create_user(p_email TEXT, p_full_name TEXT) 
RETURNS uuid AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- First try to find existing user
  SELECT id INTO v_user_id FROM auth.users WHERE email = p_email LIMIT 1;
  
  -- If not found, create new auth user and corresponding public user
  IF v_user_id IS NULL THEN
    -- Create auth user
    v_user_id := gen_random_uuid();
    
    INSERT INTO auth.users (
      id,
      email,
      raw_user_meta_data,
      created_at,
      updated_at
    ) VALUES (
      v_user_id,
      p_email,
      jsonb_build_object('full_name', p_full_name),
      now(),
      now()
    );
  END IF;
  
  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;