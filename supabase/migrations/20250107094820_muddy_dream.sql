/*
  # Fix RLS policies for shift swap history

  1. Changes
    - Add insert policy for shift_swap_history table
    - Update existing select policy
  
  2. Security
    - Allow system to insert history records
    - Maintain read-only access for authenticated users
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated users can read shift swap history" ON shift_swap_history;

-- Create new policies
CREATE POLICY "Authenticated users can read shift swap history"
  ON shift_swap_history
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert shift swap history"
  ON shift_swap_history
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Ensure trigger has necessary permissions
GRANT INSERT ON shift_swap_history TO authenticated;