-- Denormalize sayac kolonlari: okuma performansi icin teachers/trainings/meditations uzerinde tutulan toplamlar.

alter table public.teachers
  add column if not exists like_count int default 0,
  add column if not exists rating_count int default 0,
  add column if not exists rating_avg numeric(3,2) default 0;

alter table public.trainings
  add column if not exists like_count int default 0,
  add column if not exists rating_count int default 0,
  add column if not exists rating_avg numeric(3,2) default 0,
  add column if not exists comment_count int default 0;

alter table public.meditations
  add column if not exists favorite_count int default 0;
