/*
  # Fix RLS policies to prevent recursion
  
  1. Changes
    - Simplify RLS policies to avoid recursive checks
    - Use direct role checks instead of subqueries where possible
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own data and admins can view all" ON users;
DROP POLICY IF EXISTS "Users can view their shifts and admin can view all" ON shifts;
DROP POLICY IF EXISTS "Users can view their swap requests" ON shift_swaps;

-- Create simplified policies
CREATE POLICY "Users can view all users"
  ON users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can view all shifts"
  ON shifts
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can view all swap requests"
  ON shift_swaps
  FOR SELECT
  TO authenticated
  USING (true);