/*
  # Add admin features and update AA role
  
  1. Changes
    - Set AA user as admin
    - Add policy for admin to delete swaps
*/

-- Update AA to be an admin
UPDATE public.users 
SET role = 'admin'
WHERE full_name = 'AA';

-- Add policy for admins to delete swaps
CREATE POLICY "Admins can delete all swaps"
  ON shift_swaps_v2
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );