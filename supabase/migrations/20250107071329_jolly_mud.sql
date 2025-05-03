-- Create shift_swaps_v2 table if it doesn't exist
CREATE TABLE IF NOT EXISTS shift_swaps_v2 (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date date NOT NULL,
  from_employee text NOT NULL,
  to_employee text NOT NULL,
  from_shift text NOT NULL,
  to_shift text NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE shift_swaps_v2 ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_shift_swaps_v2_from_employee ON shift_swaps_v2(from_employee);
CREATE INDEX IF NOT EXISTS idx_shift_swaps_v2_to_employee ON shift_swaps_v2(to_employee);
CREATE INDEX IF NOT EXISTS idx_shift_swaps_v2_date ON shift_swaps_v2(date);

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can read shift swaps" ON shift_swaps_v2;
DROP POLICY IF EXISTS "Anyone can create shift swaps" ON shift_swaps_v2;
DROP POLICY IF EXISTS "Anyone can update shift swaps" ON shift_swaps_v2;

-- Add policies
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

CREATE POLICY "Anyone can update shift swaps"
  ON shift_swaps_v2
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);