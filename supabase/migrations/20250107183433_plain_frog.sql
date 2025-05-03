-- Create shifts_schedule table
CREATE TABLE shifts_schedule (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start_date date NOT NULL,
  employee_code text NOT NULL,
  sunday_shift text,
  monday_shift text,
  tuesday_shift text,
  wednesday_shift text,
  thursday_shift text,
  friday_shift text,
  saturday_shift text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE shifts_schedule ENABLE ROW LEVEL SECURITY;

-- Create index for better performance
CREATE INDEX idx_shifts_schedule_week ON shifts_schedule(week_start_date);
CREATE INDEX idx_shifts_schedule_employee ON shifts_schedule(employee_code);

-- Create policy for reading shifts
CREATE POLICY "Anyone can read shifts schedule"
  ON shifts_schedule
  FOR SELECT
  TO authenticated
  USING (true);

-- Function to generate shifts for next/previous weeks
CREATE OR REPLACE FUNCTION generate_shifts_for_week(target_date date)
RETURNS void AS $$
DECLARE
  current_shifts record;
  new_employee_code text;
  employee_codes text[];
BEGIN
  -- Get employee codes in current order
  SELECT array_agg(employee_code ORDER BY id)
  INTO employee_codes
  FROM shifts_schedule
  WHERE week_start_date = (
    SELECT MAX(week_start_date)
    FROM shifts_schedule
  );

  -- If no existing shifts, use default order
  IF employee_codes IS NULL THEN
    employee_codes := ARRAY['BO','AA','CP','CT','CH','CF','DV','AD','DM','FO'];
  END IF;

  -- Rotate employee codes based on direction
  IF target_date > (SELECT MAX(week_start_date) FROM shifts_schedule) THEN
    -- Move last to first for next week
    employee_codes := array_cat(
      ARRAY[employee_codes[array_length(employee_codes, 1)]],
      employee_codes[1:array_length(employee_codes, 1)-1]
    );
  ELSE
    -- Move first to last for previous week
    employee_codes := array_cat(
      employee_codes[2:array_length(employee_codes, 1)],
      ARRAY[employee_codes[1]]
    );
  END IF;

  -- Insert new week's shifts
  FOR i IN 1..array_length(employee_codes, 1) LOOP
    new_employee_code := employee_codes[i];
    
    -- Get shift pattern from base week
    SELECT * INTO current_shifts
    FROM shifts_schedule
    WHERE week_start_date = '2024-05-12'
    AND employee_code = new_employee_code;

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
      new_employee_code,
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

-- Insert initial week data
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
) VALUES
  ('2024-05-12', 'BO', 'RI', '8:00', '05:55+', '05:55', '06:30', '05:55', 'NL'),
  ('2024-05-12', 'AA', 'NL', '11:30', '11:30+', '06:30', '8:00', '06:30', 'RI'),
  ('2024-05-12', 'CP', 'NL', '15:55', '11:30', '15:55', '11:30', 'RI', '11:30+'),
  ('2024-05-12', 'CT', '11:30', '15:55', '11:30', 'NL', 'RI', '05:00+', '00:00'),
  ('2024-05-12', 'CH', '00:00', '00:00', 'NL', 'RI', '06:30', '06:30', '05:55+'),
  ('2024-05-12', 'CF', '05:55+', 'NL', 'RI', '8:00', '05:55', '05:55', '05:55'),
  ('2024-05-12', 'DV', '05:55', 'RI', 'NL', '05:55+', '05:55', '05:55', '09:00'),
  ('2024-05-12', 'AD', '09:00', 'RI', '05:55', '09:00+', '09:00', '05:55', 'NL'),
  ('2024-05-12', 'DM', 'RI', '05:55', '05:55', '05:55', '05:00+', '00:00', 'NL'),
  ('2024-05-12', 'FO', 'NL', '15:55-', '15:55', '11:30', '11:30', '11:30', 'RI');