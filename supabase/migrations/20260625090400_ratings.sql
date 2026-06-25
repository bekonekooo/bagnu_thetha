-- Puanlamalar tablosu: ogretmen ve egitim icin 1-5 arasi kullanici puanlari (kullanici basina tek puan).

create table if not exists public.ratings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('teacher', 'training')),
  target_id uuid not null,
  score smallint not null check (score between 1 and 5),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (user_id, target_type, target_id)
);

create index if not exists ratings_target_idx
  on public.ratings (target_type, target_id);
