-- Drop existing function and trigger
DROP TRIGGER IF EXISTS on_shift_swap_created ON shift_swaps_v2;
DROP FUNCTION IF EXISTS notify_shift_swap;

-- Create notification function using Supabase's webhook system
CREATE OR REPLACE FUNCTION notify_shift_swap()
RETURNS TRIGGER AS $$
BEGIN
  -- The notification will be handled by Supabase's webhook system
  -- No need to make HTTP calls directly
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger
CREATE TRIGGER on_shift_swap_created
  AFTER INSERT ON shift_swaps_v2
  FOR EACH ROW
  EXECUTE FUNCTION notify_shift_swap();