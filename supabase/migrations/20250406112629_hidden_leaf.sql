/*
  # Semplifica sistema di scambio turni
  
  1. Changes
    - Semplifica le policy per gli scambi
    - Rimuove restrizioni non necessarie
    - Permette agli admin di gestire liberamente gli scambi
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can create swap requests" ON shift_swaps_v2;
DROP POLICY IF EXISTS "Users can view swap requests" ON shift_swaps_v2;
DROP POLICY IF EXISTS "Users can update swap requests" ON shift_swaps_v2;
DROP POLICY IF EXISTS "Admins can delete swaps" ON shift_swaps_v2;

-- Create simplified policies
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
  USING (true);

CREATE POLICY "Anyone can delete swaps"
  ON shift_swaps_v2
  FOR DELETE
  TO authenticated
  USING (true);