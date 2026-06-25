-- Yorumlar tablosu: ogretmen ve egitim altina yazilan yorumlar (gizleme destekli).

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('teacher', 'training')),
  target_id uuid not null,
  body text not null check (char_length(btrim(body)) between 1 and 2000),
  is_hidden boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists comments_target_idx
  on public.comments (target_type, target_id, created_at desc);

create index if not exists comments_user_idx
  on public.comments (user_id);
