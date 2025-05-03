/*
  # Add function to delete auth users
  
  1. Changes
    - Add PostgreSQL function to delete auth users
    - Function is restricted to admin users only
*/

-- Create function to delete auth users
CREATE OR REPLACE FUNCTION delete_auth_user(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if the executing user is an admin
  IF NOT EXISTS (
    SELECT 1 
    FROM users 
    WHERE id = auth.uid() 
    AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only administrators can delete users';
  END IF;

  -- Delete from auth.users
  DELETE FROM auth.users WHERE id = user_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_auth_user TO authenticated;