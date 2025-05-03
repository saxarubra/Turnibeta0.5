-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can read shifts schedule" ON shifts_schedule;
DROP POLICY IF EXISTS "Anyone can insert shifts schedule" ON shifts_schedule;

-- Create shifts_schedule table if not exists
CREATE TABLE IF NOT EXISTS shifts_schedule (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start_date date NOT NULL,
  employee_code text NOT NULL,
  shift_pattern jsonb NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE shifts_schedule ENABLE ROW LEVEL SECURITY;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_shifts_schedule_week ON shifts_schedule(week_start_date);
CREATE INDEX IF NOT EXISTS idx_shifts_schedule_employee ON shifts_schedule(employee_code);

-- Create policies
CREATE POLICY "Anyone can read shifts schedule"
  ON shifts_schedule
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anyone can insert shifts schedule"
  ON shifts_schedule
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Function to get shifts for a specific week
CREATE OR REPLACE FUNCTION get_shifts_for_week(target_date date)
RETURNS TABLE (
  employee_code text,
  shift_pattern jsonb
) AS $$
BEGIN
  RETURN QUERY
  SELECT s.employee_code, s.shift_pattern
  FROM shifts_schedule s
  WHERE s.week_start_date = target_date
  ORDER BY s.id;
END;
$$ LANGUAGE plpgsql;

-- Function to rotate employees for next/previous week
CREATE OR REPLACE FUNCTION rotate_employees(
  current_week date,
  target_week date
) RETURNS text[] AS $$
DECLARE
  employee_codes text[];
BEGIN
  -- Get current employee order
  SELECT array_agg(employee_code ORDER BY id)
  INTO employee_codes
  FROM shifts_schedule
  WHERE week_start_date = current_week;

  -- Rotate based on direction
  IF target_week > current_week THEN
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

  RETURN employee_codes;
END;
$$ LANGUAGE plpgsql;

-- Function to generate shifts for a week
CREATE OR REPLACE FUNCTION generate_shifts_for_week(target_date date)
RETURNS void AS $$
DECLARE
  base_shifts record;
  rotated_employees text[];
BEGIN
  -- Get rotated employee order
  SELECT rotate_employees(
    (SELECT MAX(week_start_date) FROM shifts_schedule),
    target_date
  ) INTO rotated_employees;

  -- For each employee, get their base shift pattern and insert new week
  FOR i IN 1..array_length(rotated_employees, 1) LOOP
    SELECT shift_pattern INTO base_shifts
    FROM shifts_schedule
    WHERE week_start_date = '2024-05-12'
    AND employee_code = rotated_employees[i];

    INSERT INTO shifts_schedule (
      week_start_date,
      employee_code,
      shift_pattern
    ) VALUES (
      target_date,
      rotated_employees[i],
      base_shifts.shift_pattern
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;