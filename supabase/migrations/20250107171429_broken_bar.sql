-- Drop existing policies
DROP POLICY IF EXISTS "Users can create swap requests" ON shift_swaps_v2;
DROP POLICY IF EXISTS "Users can view swap requests" ON shift_swaps_v2;
DROP POLICY IF EXISTS "Users can update swap requests" ON shift_swaps_v2;

-- Clear existing swaps to start fresh
TRUNCATE TABLE shift_swaps_v2 CASCADE;

-- Create comprehensive policies for shift_swaps_v2
CREATE POLICY "Users can create swap requests"
  ON shift_swaps_v2
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Only allow users to create requests from their own shifts
    from_employee = (SELECT full_name FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Users can view swap requests"
  ON shift_swaps_v2
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see requests they're involved in
    from_employee = (SELECT full_name FROM users WHERE id = auth.uid()) OR
    to_employee = (SELECT full_name FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Users can update swap requests"
  ON shift_swaps_v2
  FOR UPDATE
  TO authenticated
  USING (
    -- Allow target employee to accept/reject their pending requests
    (to_employee = (SELECT full_name FROM users WHERE id = auth.uid()) AND status = 'pending') OR
    -- Allow requesting employee to cancel their pending requests
    (from_employee = (SELECT full_name FROM users WHERE id = auth.uid()) AND status = 'pending')
  )
  WITH CHECK (
    -- Ensure status changes are valid
    status IN ('accepted', 'rejected', 'cancelled')
  );