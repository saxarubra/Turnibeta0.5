/*
  # Enhance shift swap history tracking

  1. Changes
    - Add additional fields for better tracking
    - Add indexes for performance
    - Update trigger function to include more metadata
  
  2. Security
    - Maintain existing RLS policies
    - Keep SECURITY DEFINER for trigger function
*/

-- Add additional fields to shift_swap_history
ALTER TABLE shift_swap_history
ADD COLUMN IF NOT EXISTS action_type text NOT NULL DEFAULT 'update',
ADD COLUMN IF NOT EXISTS changed_by uuid DEFAULT auth.uid(),
ADD COLUMN IF NOT EXISTS previous_status text;

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_shift_swap_history_swap_id ON shift_swap_history(swap_id);
CREATE INDEX IF NOT EXISTS idx_shift_swap_history_date ON shift_swap_history(date);
CREATE INDEX IF NOT EXISTS idx_shift_swap_history_status ON shift_swap_history(status);

-- Update the trigger function to include more metadata
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