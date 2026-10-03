-- Aula. — esquema Supabase (PostgreSQL)
-- Ejecutar en: Supabase → SQL Editor → New query → Run

-- Extensiones
create extension if not exists "pgcrypto";

-- Perfiles (1:1 con auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  phone text,
  email text,
  funko jsonb not null default '{}'::jsonb,
  is_adult boolean default false,
  created_at timestamptz not null default now(),
  constraint username_format check (username ~ '^[a-z0-9_]{3,16}$')
);

-- Bloqueos
create table if not exists public.blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint no_self_block check (blocker_id <> blocked_id)
);

-- Grupos
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

-- Canales por grupo
create table if not exists public.channels (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  slug text not null,
  created_at timestamptz not null default now(),
  unique (group_id, slug)
);

-- Mensajes de grupo
create table if not exists public.group_messages (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.channels(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  body text,
  sticker text,
  image_url text,
  anchor text,
  is_system boolean default false,
  created_at timestamptz not null default now()
);

create index if not exists group_messages_channel_ts on public.group_messages (channel_id, created_at);
create index if not exists group_messages_anchor on public.group_messages (anchor) where anchor is not null;

-- Horario del grupo
create table if not exists public.schedule_items (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  channel_id uuid references public.channels(id) on delete set null,
  item_type text not null check (item_type in ('deberes','examen','clase')),
  day_of_week smallint not null check (day_of_week between 0 and 4),
  text text not null,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

-- DMs
create table if not exists public.dm_threads (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles(id) on delete cascade,
  user_b uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_a, user_b),
  constraint dm_order check (user_a < user_b)
);

create table if not exists public.dm_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.dm_threads(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  body text,
  sticker text,
  image_url text,
  created_at timestamptz not null default now()
);

create index if not exists dm_messages_thread_ts on public.dm_messages (thread_id, created_at);

alter table public.profiles enable row level security;
alter table public.blocks enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.channels enable row level security;
alter table public.group_messages enable row level security;
alter table public.schedule_items enable row level security;
alter table public.dm_threads enable row level security;
alter table public.dm_messages enable row level security;

create policy "profiles_read" on public.profiles for select using (true);
create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);

create policy "blocks_own" on public.blocks for all using (auth.uid() = blocker_id);

create policy "members_read" on public.group_members for select using (
  exists (select 1 from public.group_members m where m.group_id = group_members.group_id and m.user_id = auth.uid())
);
create policy "members_insert" on public.group_members for insert with check (
  auth.uid() = user_id
  or exists (select 1 from public.group_members m where m.group_id = group_members.group_id and m.user_id = auth.uid())
);

create policy "groups_read" on public.groups for select using (
  exists (select 1 from public.group_members m where m.group_id = id and m.user_id = auth.uid())
);
create policy "groups_insert" on public.groups for insert with check (auth.uid() = created_by);

create policy "channels_member" on public.channels for all using (
  exists (select 1 from public.group_members m where m.group_id = channels.group_id and m.user_id = auth.uid())
);

create policy "gmsg_read" on public.group_messages for select using (
  exists (
    select 1 from public.channels c
    join public.group_members m on m.group_id = c.group_id
    where c.id = group_messages.channel_id and m.user_id = auth.uid()
  )
);
create policy "gmsg_insert" on public.group_messages for insert with check (
  auth.uid() = user_id
  and exists (
    select 1 from public.channels c
    join public.group_members m on m.group_id = c.group_id
    where c.id = channel_id and m.user_id = auth.uid()
  )
);

create policy "sched_member" on public.schedule_items for all using (
  exists (select 1 from public.group_members m where m.group_id = schedule_items.group_id and m.user_id = auth.uid())
);

create policy "dm_threads_own" on public.dm_threads for all using (
  auth.uid() = user_a or auth.uid() = user_b
);
create policy "dm_msg_own" on public.dm_messages for all using (
  exists (
    select 1 from public.dm_threads t
    where t.id = dm_messages.thread_id and (t.user_a = auth.uid() or t.user_b = auth.uid())
  )
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, email, funko)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', 'user_' || substr(new.id::text, 1, 8)),
    new.email,
    coalesce(new.raw_user_meta_data->'funko', '{}'::jsonb)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
