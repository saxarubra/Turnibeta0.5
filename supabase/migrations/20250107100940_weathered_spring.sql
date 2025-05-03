-- Create notifications table if not exists
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  message text NOT NULL,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

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

-- Update shift_swaps_v2 policies
DROP POLICY IF EXISTS "Users can update their swap requests" ON shift_swaps_v2;

CREATE POLICY "Users can update their swap requests"
  ON shift_swaps_v2
  FOR UPDATE
  TO authenticated
  USING (
    from_employee = (SELECT full_name FROM users WHERE id = auth.uid()) OR
    to_employee = (SELECT full_name FROM users WHERE id = auth.uid())
  );