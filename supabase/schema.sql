-- Overload Lift Log: run once in Supabase > SQL Editor.
-- One row per key: 'meta', 'w:<workout id>', 'b:<YYYY-MM-DD>'.
create table if not exists public.overload_entries (
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  k          text not null,
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, k)
);

alter table public.overload_entries enable row level security;

-- Each account can only see and change its own rows.
drop policy if exists "own rows" on public.overload_entries;
create policy "own rows" on public.overload_entries
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Live updates between phone and laptop.
alter publication supabase_realtime add table public.overload_entries;
