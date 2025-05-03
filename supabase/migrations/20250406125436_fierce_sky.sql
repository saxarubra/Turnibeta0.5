/*
  # Improve swap cascade logic
  
  1. Changes
    - Simplify swap cascade logic
    - Fix chain propagation
    - Ensure proper shift updates
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
  swap_rec RECORD;
  original_shift text;
  current_employee text;
  current_shift text;
  processed_swaps UUID[] := ARRAY[NEW.id];
BEGIN
  -- Procedi solo per scambi accettati
  IF NEW.status = 'accepted' THEN
    -- Lo shift originale è quello di chi avvia lo scambio (from)
    original_shift := NEW.from_shift;

    -- Posizione attuale della catena
    current_employee := NEW.to_employee;
    current_shift := NEW.to_shift;

    -- Inizia la cascata di scambi
    LOOP
      -- Trova lo scambio pendente successivo che coinvolge l'impiegato attuale e il turno attuale
      SELECT * INTO swap_rec
      FROM shift_swaps_v2
      WHERE status = 'pending'
        AND date = NEW.date
        AND id != ALL(processed_swaps)
        AND from_employee = current_employee
        AND from_shift = current_shift
      ORDER BY created_at ASC
      LIMIT 1;

      -- Se non ci sono altri scambi, termina
      IF NOT FOUND THEN
        EXIT;
      END IF;

      -- Aggiorna lo shift di origine con quello originale che proviene dall'inizio della catena
      UPDATE shift_swaps_v2
      SET from_shift = original_shift
      WHERE id = swap_rec.id;

      -- Aggiungi lo scambio alla lista dei processati
      processed_swaps := array_append(processed_swaps, swap_rec.id);

      -- Aggiorna il nuovo "attuale" per continuare lungo la catena
      current_employee := swap_rec.to_employee;
      current_shift := swap_rec.to_shift;
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