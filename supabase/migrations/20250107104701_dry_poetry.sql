-- Create notifications table if not exists
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  type text NOT NULL CHECK (type IN ('swap_request', 'swap_accepted', 'swap_rejected', 'swap_cancelled')),
  swap_id uuid REFERENCES shift_swaps_v2(id),
  message text NOT NULL,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their notifications" ON notifications;

-- Add notification policies
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

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS on_shift_swap_notification ON shift_swaps_v2;
DROP FUNCTION IF EXISTS handle_swap_notification CASCADE;

-- Function to handle swap notifications
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
    notification_type := 'swap_request';
    notification_message := format('New swap request from %s for %s shift on %s', 
      NEW.from_employee, NEW.from_shift, NEW.date);
    
    -- Create notification for recipient
    INSERT INTO notifications (user_id, type, swap_id, message)
    VALUES (to_user_id, notification_type, NEW.id, notification_message);

  ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    -- Status change notification
    IF NEW.status = 'accepted' THEN
      notification_type := 'swap_accepted';
      notification_message := format('Your swap request for %s was accepted by %s', 
        NEW.date, NEW.to_employee);
    ELSIF NEW.status = 'rejected' THEN
      notification_type := 'swap_rejected';
      notification_message := format('Your swap request for %s was rejected by %s', 
        NEW.date, NEW.to_employee);
    END IF;

    -- Notify the requester of the status change
    INSERT INTO notifications (user_id, type, swap_id, message)
    VALUES (from_user_id, notification_type, NEW.id, notification_message);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for notifications
CREATE TRIGGER on_shift_swap_notification
  AFTER INSERT OR UPDATE ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION handle_swap_notification();