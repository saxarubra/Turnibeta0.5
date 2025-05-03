/*
  # Fix shift swap history RLS policies
  
  1. Changes
    - Drop and recreate RLS policies for shift_swap_history
    - Add policy for trigger-based inserts
    - Ensure proper security context for history tracking
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated users can read shift swap history" ON shift_swap_history;

-- Create new policies
CREATE POLICY "Anyone can read shift swap history"
  ON shift_swap_history
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow trigger-based inserts"
  ON shift_swap_history
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow trigger-based updates"
  ON shift_swap_history
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Ensure proper permissions
GRANT ALL ON shift_swap_history TO authenticated;

-- Update trigger function to use service role
CREATE OR REPLACE FUNCTION record_swap_history()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO shift_swap_history (
    swap_id,
    date,
    from_employee,
    to_employee,
    from_shift,
    to_shift,
    status,
    action_type,
    changed_by,
    previous_status
  ) VALUES (
    NEW.id,
    NEW.date,
    NEW.from_employee,
    NEW.to_employee,
    NEW.from_shift,
    NEW.to_shift,
    NEW.status,
    CASE
      WHEN TG_OP = 'INSERT' THEN 'create'
      WHEN TG_OP = 'UPDATE' THEN 'update'
      ELSE TG_OP::text
    END,
    auth.uid(),
    CASE 
      WHEN TG_OP = 'UPDATE' THEN OLD.status
      ELSE NULL
    END
  );

  RETURN NEW;
END;
$$;