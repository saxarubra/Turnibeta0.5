-- Drop existing constraint
ALTER TABLE shift_swaps_v2 DROP CONSTRAINT IF EXISTS shift_swaps_v2_status_check;

-- Add new constraint with cancelled status
ALTER TABLE shift_swaps_v2 
ADD CONSTRAINT shift_swaps_v2_status_check 
CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled'));

-- Add policy for swap request cancellation
CREATE POLICY "Users can cancel their own swap requests"
  ON shift_swaps_v2
  FOR UPDATE
  TO authenticated
  USING (
    from_employee = (SELECT full_name FROM users WHERE id = auth.uid()) AND
    status = 'pending'
  )
  WITH CHECK (status = 'cancelled');

-- Add email_sent column to track email status
ALTER TABLE shift_swaps_v2
ADD COLUMN IF NOT EXISTS email_sent boolean DEFAULT false;

-- Update notification handler function
CREATE OR REPLACE FUNCTION handle_swap_notification()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  to_user_id uuid;
  from_user_id uuid;
BEGIN
  -- Get user IDs with proper error handling
  SELECT id INTO STRICT to_user_id 
  FROM users 
  WHERE full_name = NEW.to_employee;

  SELECT id INTO STRICT from_user_id 
  FROM users 
  WHERE full_name = NEW.from_employee;

  IF TG_OP = 'INSERT' THEN
    -- New swap request notification
    INSERT INTO notifications (user_id, message)
    VALUES (
      to_user_id,
      format('New swap request from %s for %s shift on %s', 
        NEW.from_employee, NEW.from_shift, NEW.date)
    );
  ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    -- Status change notifications
    CASE NEW.status
      WHEN 'accepted' THEN
        -- Notify requester of acceptance
        INSERT INTO notifications (user_id, message)
        VALUES (
          from_user_id,
          format('Your swap request for %s was accepted by %s', 
            NEW.date, NEW.to_employee)
        );
      WHEN 'rejected' THEN
        -- Notify requester of rejection
        INSERT INTO notifications (user_id, message)
        VALUES (
          from_user_id,
          format('Your swap request for %s was rejected by %s', 
            NEW.date, NEW.to_employee)
        );
      WHEN 'cancelled' THEN
        -- Notify target of cancellation
        INSERT INTO notifications (user_id, message)
        VALUES (
          to_user_id,
          format('Swap request from %s for %s was cancelled', 
            NEW.from_employee, NEW.date)
        );
      ELSE NULL;
    END CASE;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;