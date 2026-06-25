-- RLS politikalari: sosyal tablolarin erisim kurallari (kisisel favori, herkese acik begeni vb.).

alter table public.favorites enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.ratings enable row level security;
alter table public.reports enable row level security;

-- favorites: tamamen kisisel
drop policy if exists favorites_select_own on public.favorites;
create policy favorites_select_own on public.favorites
  for select using (user_id = auth.uid());

drop policy if exists favorites_insert_own on public.favorites;
create policy favorites_insert_own on public.favorites
  for insert with check (user_id = auth.uid());

drop policy if exists favorites_delete_own on public.favorites;
create policy favorites_delete_own on public.favorites
  for delete using (user_id = auth.uid());

-- likes: herkes gorur, sadece kendi begenini ekler/siler
drop policy if exists likes_select_all on public.likes;
create policy likes_select_all on public.likes
  for select using (true);

drop policy if exists likes_insert_own on public.likes;
create policy likes_insert_own on public.likes
  for insert with check (user_id = auth.uid());

drop policy if exists likes_delete_own on public.likes;
create policy likes_delete_own on public.likes
  for delete using (user_id = auth.uid());

-- comments: gizli olmayanlar veya kendi yorumlarin ya da admin gorur
drop policy if exists comments_select_visible on public.comments;
create policy comments_select_visible on public.comments
  for select using (
    is_hidden = false
    or user_id = auth.uid()
    or public.is_admin()
  );

drop policy if exists comments_insert_own on public.comments;
create policy comments_insert_own on public.comments
  for insert with check (user_id = auth.uid());

drop policy if exists comments_update_own on public.comments;
create policy comments_update_own on public.comments
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists comments_update_admin on public.comments;
create policy comments_update_admin on public.comments
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists comments_delete_own on public.comments;
create policy comments_delete_own on public.comments
  for delete using (user_id = auth.uid());

drop policy if exists comments_delete_admin on public.comments;
create policy comments_delete_admin on public.comments
  for delete using (public.is_admin());

-- ratings: herkes gorur, sadece kendi puanini yonetir
drop policy if exists ratings_select_all on public.ratings;
create policy ratings_select_all on public.ratings
  for select using (true);

drop policy if exists ratings_insert_own on public.ratings;
create policy ratings_insert_own on public.ratings
  for insert with check (user_id = auth.uid());

drop policy if exists ratings_update_own on public.ratings;
create policy ratings_update_own on public.ratings
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists ratings_delete_own on public.ratings;
create policy ratings_delete_own on public.ratings
  for delete using (user_id = auth.uid());

-- reports: bildiren veya admin gorur; ekleme kendi adina; silme own+admin; guncelleme yalniz admin
drop policy if exists reports_select_own_or_admin on public.reports;
create policy reports_select_own_or_admin on public.reports
  for select using (reporter_id = auth.uid() or public.is_admin());

drop policy if exists reports_insert_own on public.reports;
create policy reports_insert_own on public.reports
  for insert with check (reporter_id = auth.uid());

drop policy if exists reports_delete_own on public.reports;
create policy reports_delete_own on public.reports
  for delete using (reporter_id = auth.uid());

drop policy if exists reports_delete_admin on public.reports;
create policy reports_delete_admin on public.reports
  for delete using (public.is_admin());

drop policy if exists reports_update_admin on public.reports;
create policy reports_update_admin on public.reports
  for update using (public.is_admin()) with check (public.is_admin());
