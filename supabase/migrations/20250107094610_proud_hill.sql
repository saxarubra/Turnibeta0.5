-- Function to create notifications for swap status changes
CREATE OR REPLACE FUNCTION notify_swap_status_change()
RETURNS TRIGGER AS $$
DECLARE
  from_user_id uuid;
  status_message text;
BEGIN
  -- Only proceed if status has changed
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Get the user ID for the from_employee
  SELECT id INTO from_user_id
  FROM users
  WHERE full_name = NEW.from_employee;

  -- Create status message based on new status
  status_message := CASE NEW.status
    WHEN 'accepted' THEN format('Your swap request for %s was accepted by %s', NEW.date, NEW.to_employee)
    WHEN 'rejected' THEN format('Your swap request for %s was rejected by %s', NEW.date, NEW.to_employee)
    ELSE NULL
  END;

  -- Create notification if status message exists
  IF status_message IS NOT NULL AND from_user_id IS NOT NULL THEN
    INSERT INTO notifications (user_id, message)
    VALUES (from_user_id, status_message);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for status change notifications
CREATE TRIGGER notify_swap_status_change_trigger
  AFTER UPDATE ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION notify_swap_status_change();