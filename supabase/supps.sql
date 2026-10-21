-- Overload: supplement reminder check for iOS Shortcuts. Run once in Supabase > SQL Editor,
-- after steps.sql (it reuses the same Shortcut key). Safe to run again.
--
-- The 11 PM Shortcut POSTs { p_token } to /rest/v1/rpc/overload_supp_status and gets back
--   { "remind": "yes" | "no", "taken": true | false, "supp": "creatine", "date": "YYYY-MM-DD" }
-- It shows a notification when remind is "yes". The key can only learn whether that one
-- supplement is checked for that day. It can't read workouts, body weight or anything else.
create or replace function public.overload_supp_status(p_token text, p_supp text default 'creatine', p_day text default null)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  uid   uuid;
  d     date;
  sid   text := lower(coalesce(nullif(trim(p_supp), ''), 'creatine'));
  taken boolean;
begin
  select user_id into uid
  from public.overload_step_tokens
  where token_hash = encode(sha256(convert_to(coalesce(trim(p_token), ''), 'UTF8')), 'hex');
  if uid is null then
    raise exception 'Unknown Shortcut key. Use the same key as your Overload Steps Shortcut.' using errcode = '28000';
  end if;

  begin
    d := coalesce(nullif(trim(p_day), '')::date, (now() at time zone 'America/Chicago')::date);
  exception when others then
    raise exception 'Date should look like 2026-10-21, got "%".', p_day using errcode = '22007';
  end;

  select coalesce((data -> 'taken' ->> sid)::boolean, false) into taken
  from public.overload_entries
  where user_id = uid and k = 'p:' || d::text;

  taken := coalesce(taken, false);
  return json_build_object('remind', case when taken then 'no' else 'yes' end, 'taken', taken, 'supp', sid, 'date', d);
end;
$$;

revoke all on function public.overload_supp_status(text, text, text) from public;
grant execute on function public.overload_supp_status(text, text, text) to anon, authenticated;

notify pgrst, 'reload schema';
