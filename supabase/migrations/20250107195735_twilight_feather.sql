-- Drop swap history table and related objects
DROP TABLE IF EXISTS shift_swap_history CASCADE;
DROP FUNCTION IF EXISTS record_swap_history CASCADE;

-- Clear existing swaps to start fresh
TRUNCATE TABLE shift_swaps_v2 CASCADE;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can create swap requests" ON shift_swaps_v2;
DROP POLICY IF EXISTS "Users can view swap requests" ON shift_swaps_v2;
DROP POLICY IF EXISTS "Users can update swap requests" ON shift_swaps_v2;

-- Recreate policies for shift_swaps_v2
CREATE POLICY "Users can create swap requests"
  ON shift_swaps_v2
  FOR INSERT
  TO authenticated
  WITH CHECK (
    from_employee = (SELECT full_name FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Users can view swap requests"
  ON shift_swaps_v2
  FOR SELECT
  TO authenticated
  USING (
    from_employee = (SELECT full_name FROM users WHERE id = auth.uid()) OR
    to_employee = (SELECT full_name FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Users can update swap requests"
  ON shift_swaps_v2
  FOR UPDATE
  TO authenticated
  USING (
    -- Allow target employee to accept/reject pending requests
    (to_employee = (SELECT full_name FROM users WHERE id = auth.uid()) AND status = 'pending') OR
    -- Allow requesting employee to cancel their pending requests
    (from_employee = (SELECT full_name FROM users WHERE id = auth.uid()) AND status = 'pending')
  )
  WITH CHECK (
    -- Ensure status changes are valid
    status IN ('accepted', 'rejected', 'cancelled')
  );