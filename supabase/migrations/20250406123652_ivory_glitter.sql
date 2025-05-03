/*
  # Fix infinite swap cascade functionality
  
  1. Changes
    - Simplify swap cascade logic
    - Fix chain resolution
    - Ensure proper swap propagation
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
BEGIN
  -- Only proceed for accepted swaps
  IF NEW.status = 'accepted' THEN
    -- Initialize processed swaps with current swap
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
          -- Match either side of the swap
          (s.from_employee = NEW.to_employee AND s.from_shift = NEW.to_shift) OR
          (s.to_employee = NEW.to_employee AND s.to_shift = NEW.to_shift)
        )
      ORDER BY s.created_at ASC
      LIMIT 1;

      -- Exit if no more affected swaps
      IF NOT FOUND THEN
        EXIT;
      END IF;

      -- Add swap to processed list
      processed_swaps := array_append(processed_swaps, affected_swap.id);

      -- Update the affected swap based on which side matches
      IF affected_swap.from_employee = NEW.to_employee AND affected_swap.from_shift = NEW.to_shift THEN
        UPDATE shift_swaps_v2
        SET from_shift = NEW.from_shift
        WHERE id = affected_swap.id;
      ELSE
        UPDATE shift_swaps_v2
        SET to_shift = NEW.from_shift
        WHERE id = affected_swap.id;
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