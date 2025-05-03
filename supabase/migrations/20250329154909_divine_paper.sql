/*
  # Add shift rotation functionality
  
  1. Changes
    - Add function to generate shifts for next/previous weeks
    - Function handles employee rotation and shift pattern copying
*/

-- Create function to generate shifts for a week
CREATE OR REPLACE FUNCTION generate_shifts_for_week(target_date date)
RETURNS void AS $$
DECLARE
  current_shifts record;
  current_week date;
  employee_codes text[];
  new_employee_codes text[];
  i integer;
BEGIN
  -- Get the current week's data
  SELECT DISTINCT week_start_date INTO current_week
  FROM shifts_schedule
  ORDER BY week_start_date DESC
  LIMIT 1;

  -- Get employee codes in current order
  SELECT array_agg(employee_code ORDER BY id)
  INTO employee_codes
  FROM shifts_schedule
  WHERE week_start_date = current_week;

  -- Rotate employee codes based on direction
  IF target_date > current_week THEN
    -- Move last to first for next week
    new_employee_codes := array_cat(
      ARRAY[employee_codes[array_length(employee_codes, 1)]],
      employee_codes[1:array_length(employee_codes, 1)-1]
    );
  ELSE
    -- Move first to last for previous week
    new_employee_codes := array_cat(
      employee_codes[2:array_length(employee_codes, 1)],
      ARRAY[employee_codes[1]]
    );
  END IF;

  -- Insert new week's shifts with rotated employees
  FOR i IN 1..array_length(new_employee_codes, 1) LOOP
    -- Get shift pattern from current week
    SELECT * INTO current_shifts
    FROM shifts_schedule
    WHERE week_start_date = current_week
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
      new_employee_codes[i],
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