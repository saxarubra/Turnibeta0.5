/*
  # Update shifts table structure for employee codes

  1. Changes
    - Make user_id nullable
    - Add employee_code and shift_code columns
    - Add unique constraint for employee_code and start_time
    - Insert shift schedule data
*/

-- Modify shifts table
ALTER TABLE shifts ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS employee_code text;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS shift_code text;
ALTER TABLE shifts DROP CONSTRAINT IF EXISTS unique_shift_time_employee;
ALTER TABLE shifts ADD CONSTRAINT unique_shift_time_employee UNIQUE (start_time, employee_code);

-- Clear existing data safely
TRUNCATE TABLE shift_swaps CASCADE;
TRUNCATE TABLE shifts CASCADE;

-- Insert complete shift schedule
DO $$
DECLARE
  shift_times text[][];
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
  
  -- Insert shifts for each employee and day
  FOR i IN 1..array_length(shift_times, 1) LOOP
    FOR day IN 1..7 LOOP
      base_date := '2024-05-12'::date + (day - 1);
      
      INSERT INTO shifts (
        start_time,
        end_time,
        status,
        shift_code,
        employee_code
      ) VALUES (
        base_date + interval '0 hour',
        base_date + interval '8 hour',
        'scheduled',
        shift_times[i][day + 1],
        shift_times[i][1]
      );
    END LOOP;
  END LOOP;
END $$;