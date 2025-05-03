-- Create shift_swaps_v2 table
create table public.shift_swaps_v2 (
  id uuid default gen_random_uuid() primary key,
  date date not null,
  from_employee text not null,
  to_employee text not null,
  from_shift text not null,
  to_shift text not null,
  status text not null check (status in ('pending', 'authorized', 'rejected', 'accepted', 'cancelled')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create updated_at trigger
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$ language plpgsql;

create trigger handle_shift_swaps_v2_updated_at
  before update on public.shift_swaps_v2
  for each row
  execute function public.handle_updated_at();

-- Enable RLS
alter table public.shift_swaps_v2 enable row level security;

-- Create policies
create policy "Enable read access for all users" on public.shift_swaps_v2
  for select using (true);

create policy "Enable insert for authenticated users" on public.shift_swaps_v2
  for insert with check (auth.role() = 'authenticated');

create policy "Enable update for authenticated users" on public.shift_swaps_v2
  for update using (auth.role() = 'authenticated'); 