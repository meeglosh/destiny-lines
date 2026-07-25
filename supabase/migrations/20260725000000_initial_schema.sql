-- Destiny Lines initial schema (CLAUDE.md §8).
-- All writes happen via Edge Functions using the service role; the client can only
-- read its own rows. No table ever stores an image, an image URL, or an object key.

-- ---------------------------------------------------------------- profiles
create table public.profiles (
  id                      uuid primary key references auth.users(id) on delete cascade,
  created_at              timestamptz default now(),
  free_readings_used      int  default 0 not null,
  subscription_status     text default 'none' not null, -- none | trial | active | expired
  subscription_expires_at timestamptz,
  original_transaction_id text unique,
  reading_credits         int  default 0 not null,      -- only used if Option B ships
  moderation_strikes      int  default 0 not null,
  cooldown_until          timestamptz
);

alter table public.profiles enable row level security;

create policy "profiles are self-readable"
  on public.profiles for select
  using (auth.uid() = id);

-- Create a profile row automatically for each new auth user (incl. anonymous).
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id) on conflict do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------- readings
create table public.readings (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  tier       text not null check (tier in ('free', 'premium')),
  content    jsonb not null
);

alter table public.readings enable row level security;

create policy "readings are self-readable"
  on public.readings for select
  using (auth.uid() = user_id);

create index readings_user_created on public.readings (user_id, created_at desc);

-- ---------------------------------------------------------------- usage_events
create table public.usage_events (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  created_at    timestamptz default now(),
  model         text not null,
  tier          text not null,
  input_tokens  int  not null,
  cached_tokens int  default 0 not null,
  output_tokens int  not null,
  cost_usd      numeric(10,6) not null
);

alter table public.usage_events enable row level security;

create policy "usage events are self-readable"
  on public.usage_events for select
  using (auth.uid() = user_id);

create index usage_events_user_created on public.usage_events (user_id, created_at desc);

-- ---------------------------------------------------------------- moderation_events
-- Never contains the image or its URL (§6.2).
create table public.moderation_events (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  gate       text not null check (gate in ('device', 'safety', 'classifier')),
  outcome    text not null check (outcome in ('passed', 'rejected')),
  reason     text
);

alter table public.moderation_events enable row level security;

create policy "moderation events are self-readable"
  on public.moderation_events for select
  using (auth.uid() = user_id);

create index moderation_events_user_created on public.moderation_events (user_id, created_at desc);
