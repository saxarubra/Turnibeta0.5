/*
  # Database Triggers
  
  1. Changes
    - Add trigger for new user creation
    - Handle user profile creation on signup
*/

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, role, full_name, email)
  VALUES (
    new.id,
    CASE WHEN new.raw_user_meta_data->>'full_name' = 'ADMIN' THEN 'admin' ELSE 'user' END,
    new.raw_user_meta_data->>'full_name',
    new.email
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();