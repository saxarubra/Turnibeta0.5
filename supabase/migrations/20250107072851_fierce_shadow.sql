-- Clear existing swaps
TRUNCATE TABLE shift_swaps_v2;

-- Add notifications table for real-time updates
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  message text NOT NULL,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Add notification policies
CREATE POLICY "Users can view their own notifications"
  ON notifications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "System can create notifications"
  ON notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Function to create notifications for swap requests
CREATE OR REPLACE FUNCTION create_swap_notification()
RETURNS TRIGGER AS $$
DECLARE
  to_user_id uuid;
BEGIN
  -- Get the user ID for the to_employee
  SELECT id INTO to_user_id
  FROM users
  WHERE full_name = NEW.to_employee;

  -- Create notification
  IF to_user_id IS NOT NULL THEN
    INSERT INTO notifications (user_id, message)
    VALUES (
      to_user_id,
      format('New swap request from %s for %s', NEW.from_employee, NEW.date)
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for notifications
CREATE TRIGGER create_swap_notification_trigger
  AFTER INSERT ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION create_swap_notification();