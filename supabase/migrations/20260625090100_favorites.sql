-- Favoriler tablosu: kullanicinin kisisel olarak favoriledigi icerikler (meditation/teacher/training).

create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('meditation', 'teacher', 'training')),
  target_id uuid not null,
  created_at timestamptz default now(),
  unique (user_id, target_type, target_id)
);

create index if not exists favorites_user_type_idx
  on public.favorites (user_id, target_type);

create index if not exists favorites_target_idx
  on public.favorites (target_type, target_id);
