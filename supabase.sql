-- You can J: run once in Supabase → SQL Editor
-- One row per user holding the whole planner as JSON. RLS: each user can only touch their own row.
create table public.planner (
  user_id uuid primary key default auth.uid() references auth.users on delete cascade,
  data jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

alter table public.planner enable row level security;

create policy "own planner" on public.planner
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- ── Reminders (v0.6). Run this part once. ──────────────────────────────
-- Devices that turned on reminders. Each user can only see/add/remove their own.
create table public.push_subs (
  endpoint text primary key,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  sub jsonb not null,
  tz text not null default 'UTC',
  created_at timestamptz not null default now()
);
alter table public.push_subs enable row level security;
create policy "own devices" on public.push_subs
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Reminders already sent, so each one goes out once. Only the server function touches it (no policies).
create table public.push_log (
  key text primary key,
  at timestamptz not null default now()
);
alter table public.push_log enable row level security;

-- Call the send-alarms function every minute. The bearer token is the public anon key (same one as in index.html).
create extension if not exists pg_cron;
create extension if not exists pg_net;
select cron.schedule('send-alarms', '* * * * *', $$
  select net.http_post(
    url := 'https://htfzxxmkdqbpzqtxfoqj.supabase.co/functions/v1/send-alarms',
    headers := '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh0Znp4eG1rZHFicHpxdHhmb3FqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM1OTczMzQsImV4cCI6MjEwOTE3MzMzNH0.ZpEI5OaEmD9FJQtaQUhTd7Sz8yyfFAo82R1zddmyQMk"}'::jsonb,
    body := '{}'::jsonb
  )
$$);

-- ── Usage log + admin dashboard (v0.9). Run this part once. ──────────────
-- What people do in the app: event names and small details, never plan titles.
-- device = random id kept in that browser; user_id = the signed-in account (null for guests/visitors).
create table public.events (
  id bigint generated always as identity primary key,
  at timestamptz not null default now(),
  device text not null check (char_length(device) <= 40),
  user_id uuid default auth.uid(),
  name text not null check (char_length(name) <= 40),
  props jsonb not null default '{}' check (pg_column_size(props) < 2000)
);
create index on public.events (at desc);
alter table public.events enable row level security;
-- anyone using the app can add events (only for themselves); nobody but admins can read them
-- ponytail: anyone with the public key could insert junk events; add rate limiting if that happens
create policy "log own events" on public.events
  for insert to anon, authenticated
  with check (user_id is null or user_id = (select auth.uid()));

-- Who may open /admin.html. Add yourself once (see the last line).
create table public.admins (user_id uuid primary key references auth.users on delete cascade);
alter table public.admins enable row level security;
create policy "see own admin row" on public.admins
  for select to authenticated using (user_id = (select auth.uid()));
create policy "admins read events" on public.events
  for select to authenticated
  using (exists (select 1 from public.admins a where a.user_id = (select auth.uid())));

-- Account numbers for the dashboard (auth.users is not readable from the browser, so this runs as owner after an admin check).
create or replace function public.admin_stats() returns json
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.admins where user_id = auth.uid()) then
    raise exception 'not allowed';
  end if;
  return json_build_object(
    'users', (select count(*) from auth.users),
    'active7', (select count(*) from auth.users where last_sign_in_at > now() - interval '7 days'),
    'devices', (select count(*) from public.push_subs),
    'signups', (select coalesce(json_object_agg(d, n), '{}') from (
      select to_char(created_at at time zone 'Asia/Seoul', 'YYYY-MM-DD') d, count(*) n
      from auth.users where created_at > now() - interval '30 days' group by 1) x)
  );
end $$;
revoke all on function public.admin_stats() from public, anon;
grant execute on function public.admin_stats() to authenticated;

-- Make yourself an admin: put the email you sign in with between the quotes and run this line.
-- insert into public.admins select id from auth.users where email = 'YOUR_SIGN_IN_EMAIL';
