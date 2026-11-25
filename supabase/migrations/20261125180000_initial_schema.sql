
-- TravelWrapped database schema
-- Run in Supabase SQL Editor.

create extension if not exists pgcrypto;

-- User profile
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    display_name text,
    avatar_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Trips detected or created by the user
create table if not exists public.trips (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    title text,
    destination text,
    start_date date,
    end_date date,
    center_lat double precision,
    center_lng double precision,
    detection_status text not null default 'pending'
        check (detection_status in ('pending', 'suggested', 'confirmed')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (id, user_id),
    check (start_date is null or end_date is null or start_date <= end_date),
    check (center_lat is null or center_lat between -90 and 90),
    check (center_lng is null or center_lng between -180 and 180)
);

-- Uploaded photos and extracted metadata
create table if not exists public.photos (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    trip_id uuid,
    storage_path text not null unique,
    original_filename text not null,
    mime_type text not null,
    file_size bigint not null check (file_size > 0),
    captured_at timestamptz,
    latitude double precision,
    longitude double precision,
    exif_metadata jsonb not null default '{}'::jsonb,
    processing_status text not null default 'uploaded'
        check (processing_status in ('uploaded', 'processed', 'failed')),
    created_at timestamptz not null default now(),

    foreign key (trip_id, user_id)
        references public.trips(id, user_id)
        on delete set null (trip_id),

    check (latitude is null or latitude between -90 and 90),
    check (longitude is null or longitude between -180 and 180)
);

-- Generated annual recaps
create table if not exists public.recaps (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    year integer not null,
    title text,
    recap_data jsonb not null default '{}'::jsonb,
    is_public boolean not null default false,
    public_slug text unique,
    published_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, year),
    check (
        (is_public = false)
        or (is_public = true and public_slug is not null)
    )
);

-- Indexes for common queries
create index if not exists idx_trips_user
    on public.trips(user_id);

create index if not exists idx_photos_user
    on public.photos(user_id);

create index if not exists idx_photos_trip
    on public.photos(trip_id);

create index if not exists idx_photos_captured
    on public.photos(user_id, captured_at);

create index if not exists idx_recaps_user_year
    on public.recaps(user_id, year);

-- Enable Row Level Security
alter table public.profiles enable row level security;
alter table public.trips enable row level security;
alter table public.photos enable row level security;
alter table public.recaps enable row level security;

-- Profiles
create policy "Users can read own profile"
on public.profiles for select
to authenticated
using ((select auth.uid()) = id);

create policy "Users can create own profile"
on public.profiles for insert
to authenticated
with check ((select auth.uid()) = id);

create policy "Users can update own profile"
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

-- Trips
create policy "Users can manage own trips"
on public.trips for all
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- Photos
create policy "Users can manage own photos"
on public.photos for all
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- Recaps: owner-only access for now.
-- Public sharing will be handled by a controlled backend endpoint.
create policy "Users can manage own recaps"
on public.recaps for all
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- Create a private photo bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'travel-photos',
    'travel-photos',
    false,
    10485760,
    array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
    public = false,
    file_size_limit = 10485760,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

-- Storage policies: each user owns a folder named with their UUID.
create policy "Users can upload own photos"
on storage.objects for insert
to authenticated
with check (
    bucket_id = 'travel-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Users can view own photos"
on storage.objects for select
to authenticated
using (
    bucket_id = 'travel-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Users can delete own photos"
on storage.objects for delete
to authenticated
using (
    bucket_id = 'travel-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
);
