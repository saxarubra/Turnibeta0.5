/*
  # Add shift swap history tracking

  1. New Tables
    - `shift_swap_history`
      - `id` (uuid, primary key)
      - `swap_id` (uuid, references shift_swaps_v2)
      - `date` (date)
      - `from_employee` (text)
      - `to_employee` (text)
      - `from_shift` (text)
      - `to_shift` (text)
      - `status` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `shift_swap_history`
    - Add policy for authenticated users to read history
    - Add trigger to automatically record history on swap updates

  3. Changes
    - Add trigger to track swap status changes
    - Add function to record swap history
*/

-- Create shift swap history table
CREATE TABLE IF NOT EXISTS shift_swap_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  swap_id uuid REFERENCES shift_swaps_v2(id),
  date date NOT NULL,
  from_employee text NOT NULL,
  to_employee text NOT NULL,
  from_shift text NOT NULL,
  to_shift text NOT NULL,
  status text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE shift_swap_history ENABLE ROW LEVEL SECURITY;

-- Add read policy for authenticated users
CREATE POLICY "Authenticated users can read shift swap history"
  ON shift_swap_history
  FOR SELECT
  TO authenticated
  USING (true);

-- Function to record swap history
CREATE OR REPLACE FUNCTION record_swap_history()
RETURNS TRIGGER AS $$
BEGIN
  -- Record the change in history
  INSERT INTO shift_swap_history (
    swap_id,
    date,
    from_employee,
    to_employee,
    from_shift,
    to_shift,
    status
  ) VALUES (
    NEW.id,
    NEW.date,
    NEW.from_employee,
    NEW.to_employee,
    NEW.from_shift,
    NEW.to_shift,
    NEW.status
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for recording history
CREATE TRIGGER record_swap_history_trigger
  AFTER UPDATE ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION record_swap_history();