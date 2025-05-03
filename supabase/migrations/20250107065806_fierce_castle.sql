/*
  # Add email column and update user emails

  1. Changes
    - Add email column to users table
    - Update email associations for AA and BO users
*/

-- Add email column if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS email text;

-- Update users table with correct email associations
UPDATE users 
SET email = 'alexandreani@yahoo.it'
WHERE full_name = 'AA';

UPDATE users 
SET email = 'saxarubra915@gmail.com'
WHERE full_name = 'BO';