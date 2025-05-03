-- Drop existing function and trigger
DROP TRIGGER IF EXISTS on_shift_swap_created ON shift_swaps_v2;
DROP FUNCTION IF EXISTS notify_shift_swap;

-- Create notification function using http_request
CREATE OR REPLACE FUNCTION notify_shift_swap()
RETURNS TRIGGER AS $$
BEGIN
  -- Call Edge Function using http_request
  PERFORM
    http_request(
      'POST',
      'https://llfdsyejuhfbaujjzofw.functions.supabase.co/notify-shift-swap',
      ARRAY[http_header('Content-Type', 'application/json')],
      json_build_object('record', row_to_json(NEW))::text,
      0
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger
CREATE TRIGGER on_shift_swap_created
  AFTER INSERT ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION notify_shift_swap();