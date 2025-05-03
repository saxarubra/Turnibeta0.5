-- Drop existing function and trigger
DROP TRIGGER IF EXISTS on_shift_swap_created ON shift_swaps_v2;
DROP FUNCTION IF EXISTS notify_shift_swap;

-- Create simplified notification function using http
CREATE OR REPLACE FUNCTION notify_shift_swap()
RETURNS TRIGGER AS $$
BEGIN
  -- Call Edge Function directly with the hardcoded URL
  PERFORM http_post(
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