-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Anyone can read shifts schedule" ON shifts_schedule;

-- Enable RLS
ALTER TABLE shifts_schedule ENABLE ROW LEVEL SECURITY;

-- Create policies for shifts_schedule
CREATE POLICY "Anyone can read shifts schedule"
  ON shifts_schedule
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anyone can insert shifts schedule"
  ON shifts_schedule
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Grant execute permission on generate_shifts_for_week function
GRANT EXECUTE ON FUNCTION generate_shifts_for_week TO authenticated;

-- Grant necessary table permissions
GRANT SELECT, INSERT ON shifts_schedule TO authenticated;