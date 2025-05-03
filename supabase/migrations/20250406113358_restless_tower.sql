/*
  # Restore swap cascade functionality
  
  1. Changes
    - Drop existing policies
    - Create new policies that allow swap cascading
    - Add trigger for handling swap cascades
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can create swap requests" ON shift_swaps_v2;
DROP POLICY IF EXISTS "Users can view swap requests" ON shift_swaps_v2;
DROP POLICY IF EXISTS "Users can update swap requests" ON shift_swaps_v2;
DROP POLICY IF EXISTS "Admins can delete swaps" ON shift_swaps_v2;

-- Create simplified policies for swap cascading
CREATE POLICY "Anyone can view swaps"
  ON shift_swaps_v2
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anyone can create swaps"
  ON shift_swaps_v2
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Anyone can update swaps"
  ON shift_swaps_v2
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (status IN ('accepted', 'rejected', 'cancelled'));

-- Function to handle swap cascading
CREATE OR REPLACE FUNCTION handle_swap_cascade()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  affected_swap record;
  cascade_count integer := 0;
  max_cascades constant integer := 10;
BEGIN
  -- Only proceed for accepted swaps
  IF NEW.status = 'accepted' THEN
    -- Start cascade loop
    WHILE cascade_count < max_cascades LOOP
      -- Find affected swap where our to_shift is someone else's from_shift
      SELECT * INTO affected_swap
      FROM shift_swaps_v2
      WHERE date = NEW.date
        AND status = 'pending'
        AND from_shift = NEW.to_shift
        AND from_employee = NEW.to_employee;
        
      -- Exit if no more affected swaps
      IF NOT FOUND THEN
        EXIT;
      END IF;
      
      -- Update the affected swap
      UPDATE shift_swaps_v2
      SET from_shift = NEW.from_shift
      WHERE id = affected_swap.id;
      
      cascade_count := cascade_count + 1;
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for swap cascading
DROP TRIGGER IF EXISTS on_swap_cascade ON shift_swaps_v2;
CREATE TRIGGER on_swap_cascade
  AFTER UPDATE ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION handle_swap_cascade();