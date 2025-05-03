/*
  # Add display_order column to shifts_schedule
  
  1. Changes
    - Add display_order column to shifts_schedule table
    - Add index for better query performance
*/

-- Add display_order column
ALTER TABLE shifts_schedule 
ADD COLUMN IF NOT EXISTS display_order integer;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_shifts_schedule_display_order 
ON shifts_schedule(display_order);