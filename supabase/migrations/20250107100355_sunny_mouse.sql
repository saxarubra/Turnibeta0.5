/*
  # Fix notifications and swap handling
  
  1. Changes
    - Add missing trigger for notifications
    - Fix RLS policies
    - Reset data for clean start
*/

-- Reset data
TRUNCATE TABLE notifications;
TRUNCATE TABLE shift_swaps_v2;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS on_shift_swap_created ON shift_swaps_v2;
DROP TRIGGER IF EXISTS on_shift_swap_updated ON shift_swaps_v2;

-- Create triggers for notifications
CREATE TRIGGER on_shift_swap_created
  AFTER INSERT ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION create_swap_notification();

CREATE TRIGGER on_shift_swap_updated
  AFTER UPDATE ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION create_swap_notification();

-- Update RLS policies to ensure proper access
DROP POLICY IF EXISTS "Anyone can update shift swaps" ON shift_swaps_v2;

CREATE POLICY "Users can update their swap requests"
  ON shift_swaps_v2
  FOR UPDATE
  TO authenticated
  USING (
    from_employee = (SELECT full_name FROM users WHERE id = auth.uid()) OR
    to_employee = (SELECT full_name FROM users WHERE id = auth.uid())
  );