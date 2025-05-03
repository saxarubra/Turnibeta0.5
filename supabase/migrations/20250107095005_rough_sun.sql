/*
  # Fix RLS policies for shift swap history

  1. Changes
    - Add security definer to history recording function
    - Update RLS policies for shift_swap_history table
  
  2. Security
    - Allow trigger function to bypass RLS
    - Maintain read-only access for authenticated users
*/

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS record_swap_history_trigger ON shift_swaps_v2;
DROP FUNCTION IF EXISTS record_swap_history;

-- Recreate function with SECURITY DEFINER
CREATE OR REPLACE FUNCTION record_swap_history()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Record the change in history
  INSERT INTO shift_swap_history (
    swap_id,
    date,
    from_employee,
    to_employee,
    from_shift,
    to_shift,
    status
  ) VALUES (
    NEW.id,
    NEW.date,
    NEW.from_employee,
    NEW.to_employee,
    NEW.from_shift,
    NEW.to_shift,
    NEW.status
  );

  RETURN NEW;
END;
$$;

-- Recreate trigger
CREATE TRIGGER record_swap_history_trigger
  AFTER UPDATE ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION record_swap_history();

-- Update RLS policies
DROP POLICY IF EXISTS "Authenticated users can read shift swap history" ON shift_swap_history;
DROP POLICY IF EXISTS "System can insert shift swap history" ON shift_swap_history;

CREATE POLICY "Authenticated users can read shift swap history"
  ON shift_swap_history
  FOR SELECT
  TO authenticated
  USING (true);