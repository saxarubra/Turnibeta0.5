-- Add status column to shift_swaps_v2 table
ALTER TABLE shift_swaps_v2 
ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'pending' 
CHECK (status IN ('pending', 'accepted', 'rejected'));

-- Add update policy for shift_swaps_v2
CREATE POLICY "Anyone can update shift swaps"
  ON shift_swaps_v2
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);