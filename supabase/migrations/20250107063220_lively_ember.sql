-- Enable the pg_net extension
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Function to notify about shift swaps
CREATE OR REPLACE FUNCTION notify_shift_swap()
RETURNS TRIGGER AS $$
BEGIN
  -- Call Edge Function directly with the hardcoded URL
  PERFORM
    pg_net.http_post(
      url := 'https://llfdsyejuhfbaujjzofw.functions.supabase.co/notify-shift-swap',
      body := json_build_object('record', row_to_json(NEW))::text,
      headers := '{"Content-Type": "application/json"}'::jsonb
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_shift_swap_created ON shift_swaps_v2;

-- Create trigger for shift swap notifications
CREATE TRIGGER on_shift_swap_created
  AFTER INSERT ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION notify_shift_swap();