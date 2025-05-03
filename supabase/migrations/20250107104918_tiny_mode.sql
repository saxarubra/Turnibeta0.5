-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_shift_swap_notification ON shift_swaps_v2;
DROP FUNCTION IF EXISTS handle_swap_notification CASCADE;

-- Recreate notification handler function with proper type handling
CREATE OR REPLACE FUNCTION handle_swap_notification()
RETURNS TRIGGER AS $$
DECLARE
  to_user_id uuid;
  from_user_id uuid;
  notification_type text;
  notification_message text;
BEGIN
  -- Get user IDs
  SELECT id INTO to_user_id FROM users WHERE full_name = NEW.to_employee;
  SELECT id INTO from_user_id FROM users WHERE full_name = NEW.from_employee;

  IF TG_OP = 'INSERT' THEN
    -- New swap request
    INSERT INTO notifications (
      user_id,
      type,
      swap_id,
      message
    ) VALUES (
      to_user_id,
      'swap_request',
      NEW.id,
      format('New swap request from %s for %s shift on %s', 
        NEW.from_employee, NEW.from_shift, NEW.date)
    );

  ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    -- Status change notification
    IF NEW.status = 'accepted' THEN
      INSERT INTO notifications (
        user_id,
        type,
        swap_id,
        message
      ) VALUES (
        from_user_id,
        'swap_accepted',
        NEW.id,
        format('Your swap request for %s was accepted by %s', 
          NEW.date, NEW.to_employee)
      );
    ELSIF NEW.status = 'rejected' THEN
      INSERT INTO notifications (
        user_id,
        type,
        swap_id,
        message
      ) VALUES (
        from_user_id,
        'swap_rejected',
        NEW.id,
        format('Your swap request for %s was rejected by %s', 
          NEW.date, NEW.to_employee)
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create notification trigger
CREATE TRIGGER on_shift_swap_notification
  AFTER INSERT OR UPDATE ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION handle_swap_notification();