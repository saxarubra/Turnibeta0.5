/*
  # Fix swap cascade functionality with improved chain handling
  
  1. Changes
    - Improve swap chain tracking
    - Fix cascading logic
    - Handle multiple swap chains correctly
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
  original_shift text;
  current_employee text;
  current_shift text;
  chain_start_employee text;
  chain_start_shift text;
BEGIN
  -- Only proceed for accepted swaps
  IF NEW.status = 'accepted' THEN
    -- Initialize cascade with the current swap
    original_shift := NEW.from_shift;
    current_employee := NEW.to_employee;
    current_shift := NEW.to_shift;
    chain_start_employee := NEW.from_employee;
    chain_start_shift := NEW.from_shift;
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
          -- Match either the current employee's received shift or the chain start
          (s.from_employee = current_employee AND s.from_shift = current_shift) OR
          (s.from_employee = chain_start_employee AND s.from_shift = chain_start_shift)
        )
      ORDER BY s.created_at ASC
      LIMIT 1;

      -- Exit if no more affected swaps
      IF NOT FOUND THEN
        EXIT;
      END IF;

      -- Add swap to processed list
      processed_swaps := array_append(processed_swaps, affected_swap.id);

      -- Update the affected swap
      IF affected_swap.from_employee = current_employee AND affected_swap.from_shift = current_shift THEN
        -- Se lo scambio coinvolge il turno corrente
        UPDATE shift_swaps_v2
        SET from_shift = original_shift
        WHERE id = affected_swap.id;
        
        -- Aggiorna per il prossimo scambio
        current_employee := affected_swap.to_employee;
        current_shift := affected_swap.to_shift;
      ELSE
        -- Se lo scambio coinvolge il turno originale
        UPDATE shift_swaps_v2
        SET from_shift = current_shift
        WHERE id = affected_swap.id;
        
        -- Aggiorna per il prossimo scambio
        current_employee := affected_swap.to_employee;
        current_shift := affected_swap.to_shift;
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