-- Sikayetler tablosu: ogretmen/egitim/yorum icin kullanici bildirimleri ve moderasyon durumu.

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('teacher', 'training', 'comment')),
  target_id uuid not null,
  reason text not null check (reason in ('spam', 'harassment', 'inappropriate', 'misinformation', 'other')),
  details text check (char_length(details) <= 2000),
  status text default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  resolved_by uuid references public.profiles(id),
  resolved_at timestamptz,
  created_at timestamptz default now(),
  unique (reporter_id, target_type, target_id)
);

create index if not exists reports_status_idx
  on public.reports (status, created_at desc);

create index if not exists reports_target_idx
  on public.reports (target_type, target_id);
