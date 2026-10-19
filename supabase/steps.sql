-- Overload: Apple Health steps via iOS Shortcuts. Run once in Supabase > SQL Editor,
-- after schema.sql. Safe to run again.
--
-- How it fits together
--   1. In Overload (signed in), Settings > Apple Health steps > Create Shortcut key.
--      That calls overload_new_steps_token(), which stores only a SHA-256 hash of the key.
--   2. Your Shortcut POSTs { p_token, p_steps } to /rest/v1/rpc/overload_log_steps
--      with the public anon key. The function checks the key and writes the day's
--      total into overload_entries as k = 's:YYYY-MM-DD', so it syncs like everything else.
--   The key can only write step counts. It can't read anything or touch your lifts.

-- One key per account. No policies, so nobody reads this table directly;
-- only the two functions below (which run as the table owner) touch it.
create table if not exists public.overload_step_tokens (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  token_hash text not null unique,
  created_at timestamptz not null default now(),
  last_used  timestamptz
);
alter table public.overload_step_tokens enable row level security;
revoke all on public.overload_step_tokens from anon, authenticated;

-- Signed-in app: make (or replace) this account's Shortcut key. Returns the key once.
create or replace function public.overload_new_steps_token()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  t text;
begin
  if auth.uid() is null then
    raise exception 'Sign in to Overload first.' using errcode = '28000';
  end if;
  t := 'ovl_' || replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
  insert into public.overload_step_tokens (user_id, token_hash)
  values (auth.uid(), encode(sha256(convert_to(t, 'UTF8')), 'hex'))
  on conflict (user_id) do update
    set token_hash = excluded.token_hash, created_at = now(), last_used = null;
  return t;
end;
$$;

-- Signed-in app: when the Shortcut last delivered steps (null if never).
create or replace function public.overload_steps_status()
returns json
language sql
security definer
set search_path = public
as $$
  select json_build_object('has_key', count(*) > 0, 'created_at', max(created_at), 'last_used', max(last_used))
  from public.overload_step_tokens where user_id = auth.uid();
$$;

-- Shortcut: write one day's step total.
--   p_token  the key from Overload
--   p_steps  the number (text or number; "8,234" works too)
--   p_day    optional, YYYY-MM-DD. Defaults to today in Central time.
create or replace function public.overload_log_steps(p_token text, p_steps text, p_day text default null)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  uid   uuid;
  d     date;
  n     integer;
  local date := (now() at time zone 'America/Chicago')::date;
begin
  select user_id into uid
  from public.overload_step_tokens
  where token_hash = encode(sha256(convert_to(coalesce(trim(p_token), ''), 'UTF8')), 'hex');
  if uid is null then
    raise exception 'Unknown Shortcut key. Make a new one in Overload settings and paste it into the Shortcut.' using errcode = '28000';
  end if;

  begin
    n := round(nullif(regexp_replace(coalesce(p_steps, ''), '[^0-9.]', '', 'g'), '')::numeric);
  exception when others then n := null;
  end;
  if n is null or n < 0 or n > 150000 then
    raise exception 'Steps should be a whole number, got "%".', p_steps using errcode = '22023';
  end if;

  begin
    d := coalesce(nullif(trim(p_day), '')::date, local);
  exception when others then
    raise exception 'Date should look like 2026-10-19, got "%".', p_day using errcode = '22007';
  end;
  if d > local + 1 or d < local - 400 then
    raise exception 'Date % is out of range.', d using errcode = '22008';
  end if;

  insert into public.overload_entries (user_id, k, data, updated_at)
  values (uid, 's:' || d::text, jsonb_build_object('date', d::text, 'steps', n, 'at', now()), now())
  on conflict (user_id, k) do update
    set data = excluded.data, updated_at = now();

  update public.overload_step_tokens set last_used = now() where user_id = uid;
  return json_build_object('ok', true, 'date', d, 'steps', n);
end;
$$;

revoke all on function public.overload_new_steps_token() from public, anon;
revoke all on function public.overload_steps_status() from public, anon;
revoke all on function public.overload_log_steps(text, text, text) from public;
grant execute on function public.overload_new_steps_token() to authenticated;
grant execute on function public.overload_steps_status() to authenticated;
grant execute on function public.overload_log_steps(text, text, text) to anon, authenticated;

notify pgrst, 'reload schema';
