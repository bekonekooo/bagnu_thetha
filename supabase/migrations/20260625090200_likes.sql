-- Begeniler tablosu: ogretmen ve egitim icin begeni kayitlari (herkese gorunur).

create table if not exists public.likes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('teacher', 'training')),
  target_id uuid not null,
  created_at timestamptz default now(),
  unique (user_id, target_type, target_id)
);

create index if not exists likes_target_idx
  on public.likes (target_type, target_id);

create index if not exists likes_user_idx
  on public.likes (user_id);
