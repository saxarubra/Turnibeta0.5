/*
  # Add shift swaps table

  1. New Tables
    - `shift_swaps_v2`
      - `id` (uuid, primary key)
      - `date` (date)
      - `from_employee` (text)
      - `to_employee` (text)
      - `from_shift` (text)
      - `to_shift` (text)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS
    - Add policy for authenticated users to read all swaps
    - Add policy for authenticated users to create swaps
*/

CREATE TABLE IF NOT EXISTS shift_swaps_v2 (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date date NOT NULL,
  from_employee text NOT NULL,
  to_employee text NOT NULL,
  from_shift text NOT NULL,
  to_shift text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE shift_swaps_v2 ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read shift swaps"
  ON shift_swaps_v2
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anyone can create shift swaps"
  ON shift_swaps_v2
  FOR INSERT
  TO authenticated
  WITH CHECK (true);