-- Supabase Table Setup for Missing Features (Phase 2 & Profile Edit)

-- 1. Create the `comments` table
create table if not exists comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references posts(id) on delete cascade not null,
  author_id uuid references profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamptz default now()
);

-- Enable RLS for comments
alter table comments enable row level security;

-- Policies for comments
create policy "comments_public_read" on comments
  for select using (true);

create policy "comments_authenticated_insert" on comments
  for insert with check (auth.uid() is not null and author_id = (select id from profiles where firebase_uid = auth.uid()::text));

-- 2. Create the `post_saves` table
create table if not exists post_saves (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  post_id uuid references posts(id) on delete cascade not null,
  created_at timestamptz default now(),
  unique(user_id, post_id)
);

-- Enable RLS for post_saves
alter table post_saves enable row level security;

-- Policies for post_saves
create policy "post_saves_own_read" on post_saves
  for select using (user_id = auth.uid());

create policy "post_saves_own_insert" on post_saves
  for insert with check (user_id = auth.uid());

create policy "post_saves_own_delete" on post_saves
  for delete using (user_id = auth.uid());

-- 3. Storage Bucket for Avatars
insert into storage.buckets (id, name, public) 
values ('avatars', 'avatars', true) 
on conflict (id) do nothing;

create policy "Avatar images are publicly accessible."
  on storage.objects for select
  using ( bucket_id = 'avatars' );

create policy "Users can upload their own avatars."
  on storage.objects for insert
  with check ( bucket_id = 'avatars' and auth.uid() = owner );

create policy "Users can update their own avatars."
  on storage.objects for update
  using ( auth.uid() = owner );

create policy "Users can delete their own avatars."
  on storage.objects for delete
  using ( auth.uid() = owner );
