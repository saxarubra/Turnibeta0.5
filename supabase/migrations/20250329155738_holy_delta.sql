/*
  # Update shift schedule for March 30 - April 5, 2024
  
  1. Changes
    - Clear existing schedule data
    - Insert new schedule for specified week
*/

-- Clear existing schedule
TRUNCATE TABLE shifts_schedule CASCADE;

-- Insert new schedule
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
  ('2024-03-24', 'AA', '05.55 TGR', '05.55+ G2B', '06.30 G1T', 'NL', 'RI', '06.30 RMO', '06.30 G1A'),
  ('2024-03-24', 'AD', 'NL', '05.55 TGR', '05.55 TGR', '05.55 TGR', '06.30+ G1T', 'RI', NULL),
  ('2024-03-24', 'BO', 'NL', '11.30 MTC', '08.00 G1B', '08.00 G1B', '05.55 G1S', '06.30+ RMO', 'RI'),
  ('2024-03-24', 'CP', '11.30 G1S', '15.55 TGR', 'NL', 'RI', '15.55 TGR', '15.55 RMO', '15.55- RMO'),
  ('2024-03-24', 'CB', 'NL', '15.55- RMO', '15.55 RMO', '11.30 G2B', '11.30 G2B', '15.55 G1A', 'RI'),
  ('2024-03-24', 'CT', '05.55 G1S', 'RI', 'NL', '05.55+ G1T', '05.55 G2B', '05.55 TGR', '09.30 RM2'),
  ('2024-03-24', 'CH', '15.55 G1A', 'RI', '15.55 TGR', '15.55 TGR', '12.45- G1T', '15.55 TGR', 'NL'),
  ('2024-03-24', 'CA', 'RI', '06.30 ISO', '14.30+ ISO', '11.30 G1S', '14.30 ISO', '11.30 G2B', 'NL'),
  ('2024-03-24', 'CF', 'RI', '06.30 G1T', '09.00+ JLY', '06.30 ISO', '08.00 G1B', '08.00 G1B', 'NL'),
  ('2024-03-24', 'DG', '05.55 G2B', '11.30 G1T', '07.30 (NL) R1T', 'RI', NULL, '05.00+ ISO', '00.00 ISO'),
  ('2024-03-24', 'DV', 'NL', NULL, NULL, NULL, NULL, '00.00 ISO', 'RI'),
  ('2024-03-24', 'DM', '14.30 ISO', '11.30+ RMO', '05.55 G1S', '05.00 ISO', 'RI', 'NL', '05.00 ISO'),
  ('2024-03-24', 'FO', '05.00+ ISO', '00.00 ISO', '00.00 ISO', 'RI', 'NL', '14.30 ISO', '14.30 ISO'),
  ('2024-03-24', 'GM', '15.55 RMO', '15.55 STA', 'RI', 'NL', '15.55 G1A', '14.30 G2A', '09.30+ RM1'),
  ('2024-03-24', 'IT', '00.00 ISO', 'RI', '05.00+ ISO', '00.00 ISO', '00.00 ISO', '05.55 G1T', 'NL'),
  ('2024-03-24', 'LG', 'NL', '15.55- G1A', '11.30 MTC', '11.30 MTC', '11.30 MTC', 'RI', '14.30 G1A'),
  ('2024-03-24', 'LP', 'NL', '11.30 G2S', '11.30+ G2S', '11.30 G2S', '11.30 G2S', '06.30 G1T', 'RI'),
  ('2024-03-24', 'MA', '06.30 BRG', '07.30 R1T', '11.30 RMO', 'NL', 'RI', '05.00+ RMO', '00.00 G1B'),
  ('2024-03-24', 'MO', '09.00 JLY', '08.00 G1B', 'NL', 'RI', '07.30 R1T', '07.30 R1T', '05.55+ G1S'),
  ('2024-03-24', 'MI', '11.30 G2B', 'NL', 'RI', '14.30 ISO', '11.30- G1T', '15.55 RMO', '15.55 G1A'),
  ('2024-03-24', 'NF', '11.30 G1T', 'NL', 'RI', '15.55 G1A', '15.55 RMO', '11.30- G2S', '15.55 RMO'),
  ('2024-03-24', 'PN', '00.00 G1B', 'RI', '05.55 G1T', '06.30+ G1T', '05.55 TGR', '05.55 G1S', 'NL'),
  ('2024-03-24', 'PC', 'RI', '05.55 G2A', '05.55 G2A', '05.55 G2A', '05.00+ ISO', '00.00 G1B', 'NL'),
  ('2024-03-24', 'RS', 'NL', '05.55 G1S', '05.00+ RMO', '00.00 G1B', '00.00 G1B', 'RI', '09.00 G1T'),
  ('2024-03-24', 'SC', '06.30 ISO', '14.30 ISO', '11.30 G2B', '11.30 G1T', 'RI', 'NL', '05.55+ G2B'),
  ('2024-03-24', 'SI', '05.00+ G1A', '00.00 G1B', '00.00 G1B', 'RI', 'NL', '06.30 G1B', '11.30 G2B'),
  ('2024-03-24', 'SG', '09.00 G1T', 'RI', '05.55 G2B', '05.55 G1S', '05.55+ G1T', '12.45 G1T', '11.30 (NL) G1T'),
  ('2024-03-24', 'TJ', 'RI', '11.30- G2B', '15.55 G1A', '12.45 G1T', '15.55 RMO', '11.30 MTC', 'NL'),
  ('2024-03-24', 'VE', 'NL', '05.00+ ISO', NULL, '05.55 G2B', '06.30 ISO', '05.55 G2B', 'RI');