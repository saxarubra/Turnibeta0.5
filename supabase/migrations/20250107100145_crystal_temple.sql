/*
  # Reset and simplify shift swap system
  
  1. Changes
    - Drop history tracking
    - Reset notifications
    - Keep core swap functionality
*/

-- Drop history tracking
DROP TABLE IF EXISTS shift_swap_history;
DROP FUNCTION IF EXISTS record_swap_history CASCADE;

-- Reset notifications table
TRUNCATE TABLE notifications;

-- Clear existing swaps and start fresh
TRUNCATE TABLE shift_swaps_v2;

-- Ensure notifications work properly
CREATE OR REPLACE FUNCTION create_swap_notification()
RETURNS TRIGGER AS $$
DECLARE
  to_user_id uuid;
  from_user_id uuid;
BEGIN
  -- Get user IDs
  SELECT id INTO to_user_id FROM users WHERE full_name = NEW.to_employee;
  SELECT id INTO from_user_id FROM users WHERE full_name = NEW.from_employee;

  -- Create notification for recipient
  IF to_user_id IS NOT NULL THEN
    INSERT INTO notifications (user_id, message)
    VALUES (
      to_user_id,
      format('New swap request from %s for %s', NEW.from_employee, NEW.date)
    );
  END IF;

  -- If status changes, notify requester
  IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    IF from_user_id IS NOT NULL THEN
      INSERT INTO notifications (user_id, message)
      VALUES (
        from_user_id,
        format('Your swap request for %s was %s by %s', 
               NEW.date, 
               NEW.status, 
               NEW.to_employee)
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;