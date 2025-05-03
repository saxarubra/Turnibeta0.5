/*
  # Improve swap cascade functionality
  
  1. Changes
    - Remove iteration limit for swap chains
    - Improve swap cascade trigger
    - Fix swap chain resolution
*/

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_swap_cascade ON shift_swaps_v2;
DROP FUNCTION IF EXISTS handle_swap_cascade CASCADE;

-- Create function to handle swap cascading
CREATE OR REPLACE FUNCTION handle_swap_cascade()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  affected_swap record;
  processed_swaps uuid[];
  current_from_employee text;
  current_from_shift text;
  current_to_employee text;
  current_to_shift text;
BEGIN
  -- Only proceed for accepted swaps
  IF NEW.status = 'accepted' THEN
    -- Initialize cascade with the current swap
    current_from_employee := NEW.from_employee;
    current_from_shift := NEW.from_shift;
    current_to_employee := NEW.to_employee;
    current_to_shift := NEW.to_shift;
    processed_swaps := ARRAY[NEW.id];

    -- Start cascade loop
    LOOP
      -- Find affected swap where our to_shift is someone else's from_shift
      -- and hasn't been processed yet
      SELECT * INTO affected_swap
      FROM shift_swaps_v2
      WHERE date = NEW.date
        AND status = 'pending'
        AND id != ALL(processed_swaps)
        AND (
          -- Match either the from_employee/from_shift or to_employee/to_shift
          (from_employee = current_to_employee AND from_shift = current_to_shift) OR
          (to_employee = current_from_employee AND to_shift = current_from_shift)
        )
      ORDER BY created_at ASC
      LIMIT 1;
        
      -- Exit if no more affected swaps
      IF NOT FOUND THEN
        EXIT;
      END IF;

      -- Add swap to processed list
      processed_swaps := array_append(processed_swaps, affected_swap.id);
      
      -- Update the affected swap with the cascaded shifts
      IF affected_swap.from_employee = current_to_employee AND affected_swap.from_shift = current_to_shift THEN
        -- Update from_shift to use the original shift
        UPDATE shift_swaps_v2
        SET from_shift = current_from_shift
        WHERE id = affected_swap.id;
        
        -- Update cascade variables
        current_from_employee := affected_swap.from_employee;
        current_from_shift := current_from_shift;
        current_to_employee := affected_swap.to_employee;
        current_to_shift := affected_swap.to_shift;
      ELSE
        -- Update to_shift to use the original shift
        UPDATE shift_swaps_v2
        SET to_shift = current_from_shift
        WHERE id = affected_swap.id;
        
        -- Update cascade variables
        current_from_employee := affected_swap.from_employee;
        current_from_shift := affected_swap.from_shift;
        current_to_employee := affected_swap.to_employee;
        current_to_shift := current_from_shift;
      END IF;
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for swap cascading
CREATE TRIGGER on_swap_cascade
  AFTER UPDATE ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION handle_swap_cascade();