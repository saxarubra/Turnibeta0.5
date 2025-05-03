-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_shift_swap_notification ON shift_swaps_v2;
DROP FUNCTION IF EXISTS handle_swap_notification CASCADE;

-- Recreate notifications table with swap_id reference
DROP TABLE IF EXISTS notifications;
CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  swap_id uuid REFERENCES shift_swaps_v2(id),
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

-- Create notification handler function
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
  -- Get user IDs
  SELECT id INTO to_user_id FROM users WHERE full_name = NEW.to_employee;
  SELECT id INTO from_user_id FROM users WHERE full_name = NEW.from_employee;

  IF TG_OP = 'INSERT' THEN
    -- New swap request notification
    IF to_user_id IS NOT NULL THEN
      INSERT INTO notifications (user_id, swap_id, message)
      VALUES (
        to_user_id,
        NEW.id,
        format('Nuova richiesta di scambio da %s per il turno del %s', 
          NEW.from_employee, NEW.date)
      );
    END IF;
  ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    -- Status change notifications
    IF from_user_id IS NOT NULL THEN
      CASE NEW.status
        WHEN 'accepted' THEN
          INSERT INTO notifications (user_id, swap_id, message)
          VALUES (
            from_user_id,
            NEW.id,
            format('La tua richiesta di scambio per il %s è stata accettata da %s', 
              NEW.date, NEW.to_employee)
          );
        WHEN 'rejected' THEN
          INSERT INTO notifications (user_id, swap_id, message)
          VALUES (
            from_user_id,
            NEW.id,
            format('La tua richiesta di scambio per il %s è stata rifiutata da %s', 
              NEW.date, NEW.to_employee)
          );
        WHEN 'cancelled' THEN
          IF to_user_id IS NOT NULL THEN
            INSERT INTO notifications (user_id, swap_id, message)
            VALUES (
              to_user_id,
              NEW.id,
              format('La richiesta di scambio da %s per il %s è stata cancellata', 
                NEW.from_employee, NEW.date)
            );
          END IF;
        ELSE NULL;
      END CASE;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Create notification trigger
CREATE TRIGGER on_shift_swap_notification
  AFTER INSERT OR UPDATE ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION handle_swap_notification();