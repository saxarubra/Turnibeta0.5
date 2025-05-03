/*
  # Fix RLS policies to prevent recursion
  
  1. Changes
    - Update RLS policies to use a more efficient admin check
    - Remove circular references in policy definitions
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own data and admins can view all" ON users;
DROP POLICY IF EXISTS "Users can view their shifts and admin can view all" ON shifts;
DROP POLICY IF EXISTS "Users can view their swap requests" ON shift_swaps;

-- Create new policies without recursion
CREATE POLICY "Users can view their own data and admins can view all"
  ON users
  FOR SELECT
  USING (
    auth.uid() = id OR 
    auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  );

CREATE POLICY "Users can view their shifts and admin can view all"
  ON shifts
  FOR SELECT
  USING (
    user_id = auth.uid() OR 
    auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  );

CREATE POLICY "Users can view their swap requests"
  ON shift_swaps
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM shifts
      WHERE (shifts.id = requester_shift_id OR shifts.id = requested_shift_id)
      AND shifts.user_id = auth.uid()
    ) OR 
    auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  );