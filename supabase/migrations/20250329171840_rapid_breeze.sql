/*
  # Simplify shift management system
  
  1. Changes
    - Remove rotation logic
    - Simplify shifts_schedule table
    - Update policies for better control
*/

-- Drop existing function
DROP FUNCTION IF EXISTS generate_shifts_for_week CASCADE;

-- Clear existing data
TRUNCATE TABLE shifts_schedule CASCADE;
TRUNCATE TABLE shift_swaps_v2 CASCADE;
TRUNCATE TABLE notifications CASCADE;

-- Recreate shifts_schedule table
DROP TABLE IF EXISTS shifts_schedule;
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

-- Create indexes for better performance
CREATE INDEX idx_shifts_schedule_week ON shifts_schedule(week_start_date);
CREATE INDEX idx_shifts_schedule_employee ON shifts_schedule(employee_code);

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

CREATE POLICY "Anyone can delete shifts schedule"
  ON shifts_schedule
  FOR DELETE
  TO authenticated
  USING (true);

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
  ('2024-05-12', 'BO', 'RI', '8.00', '05.55+', '05.55', '06.30', '05.55', 'NL'),
  ('2024-05-12', 'AA', 'NL', '11.30', '11.30+', '06.30', '8.00', '06.30', 'RI'),
  ('2024-05-12', 'CP', 'NL', '15.55', '11.30', '15.55', '11.30', 'RI', '11.30+'),
  ('2024-05-12', 'CT', '11.30', '15.55', '11.30', 'NL', 'RI', '05.00+', '00.00'),
  ('2024-05-12', 'CH', '00.00', '00.00', 'NL', 'RI', '06.30', '06.30', '05.55+'),
  ('2024-05-12', 'CF', '05.55+', 'NL', 'RI', '8.00', '05.55', '05.55', '05.55'),
  ('2024-05-12', 'DV', '05.55', 'RI', 'NL', '05.55+', '05.55', '05.55', '09.00'),
  ('2024-05-12', 'AD', '09.00', 'RI', '05.55', '09.00+', '09.00', '05.55', 'NL'),
  ('2024-05-12', 'DM', 'RI', '05.55', '05.55', '05.55', '05.00+', '00.00', 'NL'),
  ('2024-05-12', 'FO', 'NL', '15.55-', '15.55', '11.30', '11.30', '11.30', 'RI'),
  ('2024-05-12', 'GM', 'NL', '05.55', '05.00+', '00.00', '00.00', 'RI', '09.00'),
  ('2024-05-12', 'IT', '09.00+', '06.30', '06.30', '06.30', 'RI', 'NL', '05.55'),
  ('2024-05-12', 'CA', '06.30', '05.00+', '00.00', 'RI', 'NL', '15.55', '11.30'),
  ('2024-05-12', 'LP', '11.30', '12.45-', 'RI', 'NL', '11.30', '10.30', '06.30+'),
  ('2024-05-12', 'LG', '15.55', 'RI', '12.45-', '15.55', '15.55', '12.45', 'NL'),
  ('2024-05-12', 'MA', 'RI', '11.30-', '15.55', '12.45', '15.55', '15.55', 'NL'),
  ('2024-05-12', 'MO', 'NL', '15.55', '15.55', '11.30', '11.30', '11.30-', 'RI'),
  ('2024-05-12', 'MI', 'NL', '11.30+', '06.30', '05.00', 'NL', 'RI', '09.00'),
  ('2024-05-12', 'NF', '05.55', '05.55+', '8.00', 'NL', 'RI', '06.30', '06.30'),
  ('2024-05-12', 'PN', '06.30', '09.00', 'NL', 'RI', '15.55', '15.55', '15.55-'),
  ('2024-05-12', 'PC', '11.30', 'NL', 'RI', '15.55', '15.55', '11.30-', '15.55'),
  ('2024-05-12', 'CB', '15.55', 'RI', '15.55', '15.55', '12.45-', '15.55', 'NL'),
  ('2024-05-12', 'RS', 'RI', '14.30', '10.30', '14.30', '10.30', '8.00+', 'NL'),
  ('2024-05-12', 'SC', 'NL', '06.30', '05.00+', '00.00', '00.00', '00.00', 'RI'),
  ('2024-05-12', 'SI', 'NL', '05.55', '05.55', '05.55', '06.30+', 'RI', '14.30'),
  ('2024-05-12', 'DG', '14.30', '10.30', '06.30+', '05.00', 'RI', 'NL', '05.00'),
  ('2024-05-12', 'SG', '05.00+', '00.00', '00.00', 'RI', 'NL', '14.30', '11.30'),
  ('2024-05-12', 'TJ', '09.00', '05.00', 'RI', 'NL', '05.00', '05.00+', '00.00'),
  ('2024-05-12', 'VE', '00.00', 'RI', '14.30', '10.30', '14.30', '11.30-', 'NL');