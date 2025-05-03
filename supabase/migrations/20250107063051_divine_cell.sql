-- Enable the pg_net extension
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Drop the existing trigger
DROP TRIGGER IF EXISTS on_shift_swap_created ON shift_swaps_v2;

-- Function to notify about shift swaps
CREATE OR REPLACE FUNCTION notify_shift_swap()
RETURNS TRIGGER AS $$
BEGIN
  -- Call Edge Function to handle notifications
  PERFORM
    pg_net.http_post(
      url := current_setting('app.settings.notify_endpoint', true)::text,
      body := json_build_object('record', row_to_json(NEW))::text,
      headers := '{"Content-Type": "application/json"}'::jsonb
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER on_shift_swap_created
  AFTER INSERT ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION notify_shift_swap();