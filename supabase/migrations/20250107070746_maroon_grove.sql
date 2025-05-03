/*
  # Add email column and update user associations
  
  1. Changes
    - Add email column to users table
    - Create index on full_name
    - Update email associations for AA and BO
*/

-- Add email column if it doesn't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS email text;

-- Create index on full_name for better query performance
CREATE INDEX IF NOT EXISTS users_full_name_idx ON public.users(full_name);

-- Update users table with correct email associations
UPDATE public.users AS u
SET email = au.email
FROM auth.users AS au
WHERE u.id = au.id;

-- Add policy to allow reading email field
CREATE POLICY "Allow authenticated users to read emails"
ON public.users
FOR SELECT
TO authenticated
USING (true);