/*
  # Add shift rotation functionality for arbitrary weeks
  
  1. Changes
    - Update function to handle arbitrary week jumps
    - Maintain shift patterns while rotating employees
*/

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
BEGIN
  -- Calculate weeks difference from base week
  weeks_diff := FLOOR((target_date - base_week) / 7);

  -- Get employee codes from base week
  SELECT array_agg(employee_code ORDER BY id)
  INTO employee_codes
  FROM shifts_schedule
  WHERE week_start_date = base_week;

  -- Rotate employee codes based on weeks difference
  IF weeks_diff >= 0 THEN
    -- Forward rotation
    FOR i IN 1..weeks_diff LOOP
      employee_codes := array_cat(
        ARRAY[employee_codes[array_length(employee_codes, 1)]],
        employee_codes[1:array_length(employee_codes, 1)-1]
      );
    END LOOP;
  ELSE
    -- Backward rotation
    FOR i IN 1..ABS(weeks_diff) LOOP
      employee_codes := array_cat(
        employee_codes[2:array_length(employee_codes, 1)],
        ARRAY[employee_codes[1]]
      );
    END LOOP;
  END IF;

  rotated_codes := employee_codes;

  -- Insert shifts for target week
  FOR i IN 1..array_length(rotated_codes, 1) LOOP
    -- Get shift pattern from base week
    SELECT * INTO current_shifts
    FROM shifts_schedule
    WHERE week_start_date = base_week
    AND employee_code = employee_codes[i];

    -- Insert new week maintaining shift pattern
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