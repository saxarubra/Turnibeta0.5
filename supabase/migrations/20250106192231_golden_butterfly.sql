-- Drop existing triggers and policies
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP TRIGGER IF EXISTS update_shifts_updated_at ON shifts;
DROP TRIGGER IF EXISTS update_shift_swaps_updated_at ON shift_swaps;
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can view their shifts and admin can view all" ON shifts;
DROP POLICY IF EXISTS "Users can create their own shifts" ON shifts;
DROP POLICY IF EXISTS "Users can update their shifts if not blocked" ON shifts;
DROP POLICY IF EXISTS "Users can view their swap requests" ON shift_swaps;
DROP POLICY IF EXISTS "Users can create swap requests for their shifts" ON shift_swaps;
DROP POLICY IF EXISTS "Users can update swap requests they're involved in" ON shift_swaps;

-- Create tables
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  role text NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
  full_name text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS shifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) NOT NULL,
  start_time timestamptz NOT NULL,
  end_time timestamptz NOT NULL,
  is_blocked boolean DEFAULT false,
  status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'swap_requested', 'swapped')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT valid_shift_times CHECK (end_time > start_time)
);

CREATE TABLE IF NOT EXISTS shift_swaps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_shift_id uuid REFERENCES shifts(id) NOT NULL,
  requested_shift_id uuid REFERENCES shifts(id) NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT different_shifts CHECK (requester_shift_id != requested_shift_id)
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_swaps ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view their own data and admins can view all"
  ON users
  FOR SELECT
  USING (
    auth.uid() = id OR 
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can update their own data"
  ON users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Shifts policies
CREATE POLICY "Users can view their shifts and admin can view all"
  ON shifts
  FOR SELECT
  USING (
    user_id = auth.uid() OR 
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can create their own shifts"
  ON shifts
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their shifts if not blocked"
  ON shifts
  FOR UPDATE
  USING (
    (user_id = auth.uid() AND NOT is_blocked) OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- Shift swaps policies
CREATE POLICY "Users can view their swap requests"
  ON shift_swaps
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM shifts
      WHERE (shifts.id = requester_shift_id OR shifts.id = requested_shift_id)
      AND shifts.user_id = auth.uid()
    ) OR 
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can create swap requests for their shifts"
  ON shift_swaps
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM shifts
      WHERE shifts.id = requester_shift_id
      AND shifts.user_id = auth.uid()
      AND NOT shifts.is_blocked
    )
  );

CREATE POLICY "Users can update swap requests they're involved in"
  ON shift_swaps
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM shifts
      WHERE (shifts.id = requester_shift_id OR shifts.id = requested_shift_id)
      AND shifts.user_id = auth.uid()
      AND NOT shifts.is_blocked
    ) OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- Create functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_shifts_updated_at
  BEFORE UPDATE ON shifts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_shift_swaps_updated_at
  BEFORE UPDATE ON shift_swaps
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();