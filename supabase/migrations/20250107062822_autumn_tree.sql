/*
  # Add notification trigger for shift swaps

  1. Changes
    - Add database function and trigger for shift swap notifications
    - Function will call the Edge Function to handle email notifications
*/

-- Function to notify about shift swaps
CREATE OR REPLACE FUNCTION notify_shift_swap()
RETURNS TRIGGER AS $$
BEGIN
  -- Call Edge Function to handle notifications
  PERFORM
    net.http_post(
      url := current_setting('app.settings.notify_endpoint')::text,
      body := json_build_object('record', row_to_json(NEW))::text
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for shift swap notifications
CREATE TRIGGER on_shift_swap_created
  AFTER INSERT ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION notify_shift_swap();