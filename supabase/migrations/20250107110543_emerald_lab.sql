-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_shift_swap_notification ON shift_swaps_v2;
DROP FUNCTION IF EXISTS handle_swap_notification CASCADE;

-- Create notification handler function with proper error handling
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
    INSERT INTO notifications (
      user_id,
      message,
      type,
      swap_id
    ) VALUES (
      to_user_id,
      format('New swap request from %s for %s shift on %s', 
        NEW.from_employee, NEW.from_shift, NEW.date),
      'swap_request',
      NEW.id
    );
  ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    -- Status change notifications
    CASE NEW.status
      WHEN 'accepted' THEN
        INSERT INTO notifications (
          user_id,
          message,
          type,
          swap_id
        ) VALUES (
          from_user_id,
          format('Your swap request for %s was accepted by %s', 
            NEW.date, NEW.to_employee),
          'swap_accepted',
          NEW.id
        );
      WHEN 'rejected' THEN
        INSERT INTO notifications (
          user_id,
          message,
          type,
          swap_id
        ) VALUES (
          from_user_id,
          format('Your swap request for %s was rejected by %s', 
            NEW.date, NEW.to_employee),
          'swap_rejected',
          NEW.id
        );
      WHEN 'cancelled' THEN
        INSERT INTO notifications (
          user_id,
          message,
          type,
          swap_id
        ) VALUES (
          to_user_id,
          format('Swap request from %s for %s was cancelled', 
            NEW.from_employee, NEW.date),
          'swap_cancelled',
          NEW.id
        );
      ELSE NULL;
    END CASE;
  END IF;

  RETURN NEW;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE WARNING 'User not found for employee code';
    RETURN NEW;
  WHEN TOO_MANY_ROWS THEN
    RAISE WARNING 'Multiple users found for employee code';
    RETURN NEW;
END;
$$;

-- Create notification trigger
CREATE TRIGGER on_shift_swap_notification
  AFTER INSERT OR UPDATE ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION handle_swap_notification();