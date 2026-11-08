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
