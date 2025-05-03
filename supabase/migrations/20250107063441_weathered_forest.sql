-- Drop existing function and trigger
DROP TRIGGER IF EXISTS on_shift_swap_created ON shift_swaps_v2;
DROP FUNCTION IF EXISTS notify_shift_swap;

-- Create notification function using simplified HTTP request
CREATE OR REPLACE FUNCTION notify_shift_swap()
RETURNS TRIGGER AS $$
BEGIN
  -- Call Edge Function using basic HTTP request
  PERFORM
    http_post(
      'https://llfdsyejuhfbaujjzofw.functions.supabase.co/notify-shift-swap',
      json_build_object('record', row_to_json(NEW))::text,
      'application/json'
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger
CREATE TRIGGER on_shift_swap_created
  AFTER INSERT ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION notify_shift_swap();