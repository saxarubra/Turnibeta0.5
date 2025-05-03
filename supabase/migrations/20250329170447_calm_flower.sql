/*
  # Update rotation logic
  
  1. Changes
    - Modify generate_shifts_for_week function to handle rotation correctly
    - Add delete policy for shifts_schedule
*/

-- Drop existing function
DROP FUNCTION IF EXISTS generate_shifts_for_week;

-- Create function to generate shifts for a week
CREATE OR REPLACE FUNCTION generate_shifts_for_week(target_date date)
RETURNS void AS $$
DECLARE
  base_week date := '2024-05-12'::date;
  weeks_diff integer;
  current_shifts record;
  employee_codes text[];
  rotated_codes text[];
  i integer;
  temp_code text;
BEGIN
  -- Delete existing data for target week if any
  DELETE FROM shifts_schedule WHERE week_start_date = target_date;

  -- Calculate weeks difference from base week
  weeks_diff := FLOOR((target_date - base_week) / 7);

  -- Get employee codes from base week in correct order
  SELECT array_agg(employee_code ORDER BY id)
  INTO employee_codes
  FROM shifts_schedule
  WHERE week_start_date = base_week;

  -- Initialize rotated codes
  rotated_codes := employee_codes;

  -- Perform rotation based on weeks difference
  IF weeks_diff > 0 THEN
    -- Forward rotation (for future weeks)
    FOR i IN 1..weeks_diff LOOP
      -- Store the last element
      temp_code := rotated_codes[array_length(rotated_codes, 1)];
      -- Shift all elements down
      FOR j IN REVERSE array_length(rotated_codes, 1)..2 LOOP
        rotated_codes[j] := rotated_codes[j-1];
      END LOOP;
      -- Move last to first
      rotated_codes[1] := temp_code;
    END LOOP;
  ELSIF weeks_diff < 0 THEN
    -- Backward rotation (for past weeks)
    FOR i IN 1..ABS(weeks_diff) LOOP
      -- Store the first element
      temp_code := rotated_codes[1];
      -- Shift all elements up
      FOR j IN 1..array_length(rotated_codes, 1)-1 LOOP
        rotated_codes[j] := rotated_codes[j+1];
      END LOOP;
      -- Move first to last
      rotated_codes[array_length(rotated_codes, 1)] := temp_code;
    END LOOP;
  END IF;

  -- Insert shifts for target week with rotated employees
  FOR i IN 1..array_length(rotated_codes, 1) LOOP
    -- Get shift pattern from base week
    SELECT * INTO current_shifts
    FROM shifts_schedule
    WHERE week_start_date = base_week
    AND employee_code = employee_codes[i];

    -- Insert new week maintaining shift pattern but with rotated employee
    INSERT INTO shifts_schedule (
      week_start_date,
      employee_code,
      sunday_shift,
      monday_shift,
      tuesday_shift,
      wednesday_shift,
      thursday_shift,
      friday_shift,
      saturday_shift
    ) VALUES (
      target_date,
      rotated_codes[i],
      current_shifts.sunday_shift,
      current_shifts.monday_shift,
      current_shifts.tuesday_shift,
      current_shifts.wednesday_shift,
      current_shifts.thursday_shift,
      current_shifts.friday_shift,
      current_shifts.saturday_shift
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;