-- Clear existing swaps
TRUNCATE TABLE shift_swaps_v2 CASCADE;

-- Ensure proper policies for swap management
DROP POLICY IF EXISTS "Anyone can update shift swaps" ON shift_swaps_v2;
DROP POLICY IF EXISTS "Users can update their swap requests" ON shift_swaps_v2;

-- Create policy for swap updates
CREATE POLICY "Users can respond to swap requests"
  ON shift_swaps_v2
  FOR UPDATE
  TO authenticated
  USING (
    -- Allow target employee to accept/reject
    (to_employee = (SELECT full_name FROM users WHERE id = auth.uid()) AND status = 'pending') OR
    -- Allow requesting employee to cancel their pending requests
    (from_employee = (SELECT full_name FROM users WHERE id = auth.uid()) AND status = 'pending')
  );