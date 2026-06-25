-- Sayac trigger'lari: begeni/puan/yorum/favori degisince denormalize sayaclari otomatik gunceller.

-- ---------- BEGENI SAYACI ----------
create or replace function public.refresh_like_count(p_target_type text, p_target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  select count(*) into v_count
  from public.likes
  where target_type = p_target_type
    and target_id = p_target_id;

  if p_target_type = 'teacher' then
    update public.teachers set like_count = v_count where id = p_target_id;
  elsif p_target_type = 'training' then
    update public.trainings set like_count = v_count where id = p_target_id;
  end if;
end;
$$;

create or replace function public.trg_likes_after()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public.refresh_like_count(old.target_type, old.target_id);
    return old;
  else
    perform public.refresh_like_count(new.target_type, new.target_id);
    if tg_op = 'UPDATE'
       and (old.target_type is distinct from new.target_type
            or old.target_id is distinct from new.target_id) then
      perform public.refresh_like_count(old.target_type, old.target_id);
    end if;
    return new;
  end if;
end;
$$;

drop trigger if exists likes_count_trg on public.likes;
create trigger likes_count_trg
  after insert or update or delete on public.likes
  for each row execute function public.trg_likes_after();

-- ---------- PUAN SAYACI / ORTALAMA ----------
create or replace function public.refresh_rating(p_target_type text, p_target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
  v_avg numeric(3,2);
begin
  select count(*), coalesce(round(avg(score)::numeric, 2), 0)
  into v_count, v_avg
  from public.ratings
  where target_type = p_target_type
    and target_id = p_target_id;

  if p_target_type = 'teacher' then
    update public.teachers
      set rating_count = v_count,
          rating_avg = v_avg,
          rating = v_avg
      where id = p_target_id;
  elsif p_target_type = 'training' then
    update public.trainings
      set rating_count = v_count,
          rating_avg = v_avg
      where id = p_target_id;
  end if;
end;
$$;

create or replace function public.trg_ratings_after()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public.refresh_rating(old.target_type, old.target_id);
    return old;
  else
    perform public.refresh_rating(new.target_type, new.target_id);
    if tg_op = 'UPDATE'
       and (old.target_type is distinct from new.target_type
            or old.target_id is distinct from new.target_id) then
      perform public.refresh_rating(old.target_type, old.target_id);
    end if;
    return new;
  end if;
end;
$$;

drop trigger if exists ratings_count_trg on public.ratings;
create trigger ratings_count_trg
  after insert or update or delete on public.ratings
  for each row execute function public.trg_ratings_after();

-- ---------- YORUM SAYACI (yalniz training, yalniz gizli olmayan) ----------
create or replace function public.refresh_comment_count(p_target_type text, p_target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  if p_target_type <> 'training' then
    return;
  end if;

  select count(*) into v_count
  from public.comments
  where target_type = p_target_type
    and target_id = p_target_id
    and is_hidden = false;

  update public.trainings set comment_count = v_count where id = p_target_id;
end;
$$;

create or replace function public.trg_comments_after()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public.refresh_comment_count(old.target_type, old.target_id);
    return old;
  else
    perform public.refresh_comment_count(new.target_type, new.target_id);
    if tg_op = 'UPDATE'
       and (old.target_type is distinct from new.target_type
            or old.target_id is distinct from new.target_id) then
      perform public.refresh_comment_count(old.target_type, old.target_id);
    end if;
    return new;
  end if;
end;
$$;

drop trigger if exists comments_count_trg on public.comments;
create trigger comments_count_trg
  after insert or update or delete on public.comments
  for each row execute function public.trg_comments_after();

-- ---------- FAVORI SAYACI (yalniz meditation) ----------
create or replace function public.refresh_favorite_count(p_target_type text, p_target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  if p_target_type <> 'meditation' then
    return;
  end if;

  select count(*) into v_count
  from public.favorites
  where target_type = p_target_type
    and target_id = p_target_id;

  update public.meditations set favorite_count = v_count where id = p_target_id;
end;
$$;

create or replace function public.trg_favorites_after()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public.refresh_favorite_count(old.target_type, old.target_id);
    return old;
  else
    perform public.refresh_favorite_count(new.target_type, new.target_id);
    if tg_op = 'UPDATE'
       and (old.target_type is distinct from new.target_type
            or old.target_id is distinct from new.target_id) then
      perform public.refresh_favorite_count(old.target_type, old.target_id);
    end if;
    return new;
  end if;
end;
$$;

drop trigger if exists favorites_count_trg on public.favorites;
create trigger favorites_count_trg
  after insert or update or delete on public.favorites
  for each row execute function public.trg_favorites_after();
