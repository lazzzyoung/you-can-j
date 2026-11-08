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
