-- Add friday_shift column if it doesn't exist
ALTER TABLE shifts_schedule 
ADD COLUMN IF NOT EXISTS friday_shift text;

-- Update existing rows with default values if needed
UPDATE shifts_schedule 
SET friday_shift = 'NL' 
WHERE friday_shift IS NULL; 