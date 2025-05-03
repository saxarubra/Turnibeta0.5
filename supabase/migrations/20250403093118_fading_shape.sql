/*
  # Initial Schema Setup
  
  1. New Tables
    - `users` - Extends auth.users with role and profile info
    - `shifts_schedule` - Stores weekly shift schedules
    - `shift_swaps` - Manages shift swap requests
    - `notifications` - Handles system notifications
*/

-- Create users table extending auth.users
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  role text NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
  full_name text,
  email text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create shifts_schedule table
CREATE TABLE IF NOT EXISTS shifts_schedule (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start_date date NOT NULL,
  employee_code text NOT NULL,
  sunday_shift text,
  monday_shift text,
  tuesday_shift text,
  wednesday_shift text,
  thursday_shift text,
  friday_shift text,
  saturday_shift text,
  display_order integer,
  created_at timestamptz DEFAULT now()
);

-- Create shift_swaps table
CREATE TABLE IF NOT EXISTS shift_swaps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date date NOT NULL,
  from_employee text NOT NULL,
  to_employee text NOT NULL,
  from_shift text NOT NULL,
  to_shift text NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz DEFAULT now()
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  message text NOT NULL,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_swaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_shifts_schedule_week ON shifts_schedule(week_start_date);
CREATE INDEX IF NOT EXISTS idx_shifts_schedule_employee ON shifts_schedule(employee_code);
CREATE INDEX IF NOT EXISTS idx_shifts_schedule_display_order ON shifts_schedule(display_order);
CREATE INDEX IF NOT EXISTS idx_shift_swaps_date ON shift_swaps(date);
CREATE INDEX IF NOT EXISTS idx_shift_swaps_employees ON shift_swaps(from_employee, to_employee);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);