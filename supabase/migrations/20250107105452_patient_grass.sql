-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_shift_swap_notification ON shift_swaps_v2;
DROP FUNCTION IF EXISTS handle_swap_notification CASCADE;

-- Recreate notifications table with simplified structure
DROP TABLE IF EXISTS notifications;
CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  message text NOT NULL,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their notifications"
  ON notifications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can update their notifications"
  ON notifications
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "System can create notifications"
  ON notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

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

  -- Handle notifications based on operation type
  IF TG_OP = 'INSERT' THEN
    -- New swap request notification
    INSERT INTO notifications (user_id, message)
    VALUES (
      to_user_id,
      format('New swap request from %s for %s shift on %s', 
        NEW.from_employee, NEW.from_shift, NEW.date)
    );
  ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    -- Status change notification
    IF NEW.status = 'accepted' THEN
      INSERT INTO notifications (user_id, message)
      VALUES (
        from_user_id,
        format('Your swap request for %s was accepted by %s', 
          NEW.date, NEW.to_employee)
      );
    ELSIF NEW.status = 'rejected' THEN
      INSERT INTO notifications (user_id, message)
      VALUES (
        from_user_id,
        format('Your swap request for %s was rejected by %s', 
          NEW.date, NEW.to_employee)
      );
    END IF;
  END IF;

  RETURN NEW;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    -- Log error and continue
    RAISE WARNING 'User not found for employee code';
    RETURN NEW;
  WHEN TOO_MANY_ROWS THEN
    -- Log error and continue
    RAISE WARNING 'Multiple users found for employee code';
    RETURN NEW;
END;
$$;

-- Create notification trigger
CREATE TRIGGER on_shift_swap_notification
  AFTER INSERT OR UPDATE ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION handle_swap_notification();