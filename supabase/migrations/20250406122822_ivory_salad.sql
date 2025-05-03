/*
  # Fix infinite swap cascade functionality
  
  1. Changes
    - Improve swap cascade trigger to handle infinite chains
    - Fix swap chain resolution logic
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
  current_shift text;
  next_shift text;
  current_employee text;
  next_employee text;
BEGIN
  -- Only proceed for accepted swaps
  IF NEW.status = 'accepted' THEN
    -- Initialize cascade with the current swap
    current_shift := NEW.from_shift;
    current_employee := NEW.from_employee;
    processed_swaps := ARRAY[NEW.id];

    -- Start cascade loop
    LOOP
      -- Find next affected swap in the chain
      SELECT * INTO affected_swap
      FROM shift_swaps_v2 s
      WHERE s.date = NEW.date
        AND s.status = 'pending'
        AND s.id != ALL(processed_swaps)
        AND (
          (s.from_employee = current_employee AND s.from_shift = current_shift) OR
          (s.to_employee = current_employee AND s.to_shift = current_shift)
        )
      ORDER BY s.created_at ASC
      LIMIT 1;

      -- Exit if no more affected swaps
      IF NOT FOUND THEN
        EXIT;
      END IF;

      -- Add swap to processed list
      processed_swaps := array_append(processed_swaps, affected_swap.id);

      -- Determine the next shift and employee in the chain
      IF affected_swap.from_employee = current_employee AND affected_swap.from_shift = current_shift THEN
        next_shift := affected_swap.to_shift;
        next_employee := affected_swap.to_employee;
        
        -- Update the affected swap
        UPDATE shift_swaps_v2
        SET from_shift = NEW.to_shift
        WHERE id = affected_swap.id;
      ELSE
        next_shift := affected_swap.from_shift;
        next_employee := affected_swap.from_employee;
        
        -- Update the affected swap
        UPDATE shift_swaps_v2
        SET to_shift = NEW.to_shift
        WHERE id = affected_swap.id;
      END IF;

      -- Update current position in the chain
      current_shift := next_shift;
      current_employee := next_employee;
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