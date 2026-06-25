-- Geri doldurma: mevcut begeni/puan/yorum/favori verisinden denormalize sayaclari hesaplar.

-- teachers: begeni
update public.teachers t
set like_count = coalesce(l.cnt, 0)
from (
  select target_id, count(*) as cnt
  from public.likes
  where target_type = 'teacher'
  group by target_id
) l
where t.id = l.target_id;

update public.teachers
set like_count = 0
where id not in (
  select target_id from public.likes where target_type = 'teacher'
);

-- teachers: puan
update public.teachers t
set rating_count = coalesce(r.cnt, 0),
    rating_avg = coalesce(r.avg_score, 0),
    rating = coalesce(r.avg_score, 0)
from (
  select target_id,
         count(*) as cnt,
         round(avg(score)::numeric, 2) as avg_score
  from public.ratings
  where target_type = 'teacher'
  group by target_id
) r
where t.id = r.target_id;

-- trainings: begeni
update public.trainings tr
set like_count = coalesce(l.cnt, 0)
from (
  select target_id, count(*) as cnt
  from public.likes
  where target_type = 'training'
  group by target_id
) l
where tr.id = l.target_id;

update public.trainings
set like_count = 0
where id not in (
  select target_id from public.likes where target_type = 'training'
);

-- trainings: puan
update public.trainings tr
set rating_count = coalesce(r.cnt, 0),
    rating_avg = coalesce(r.avg_score, 0)
from (
  select target_id,
         count(*) as cnt,
         round(avg(score)::numeric, 2) as avg_score
  from public.ratings
  where target_type = 'training'
  group by target_id
) r
where tr.id = r.target_id;

-- trainings: yorum (gizli olmayan)
update public.trainings tr
set comment_count = coalesce(c.cnt, 0)
from (
  select target_id, count(*) as cnt
  from public.comments
  where target_type = 'training'
    and is_hidden = false
  group by target_id
) c
where tr.id = c.target_id;

update public.trainings
set comment_count = 0
where id not in (
  select target_id from public.comments
  where target_type = 'training' and is_hidden = false
);

-- meditations: favori
update public.meditations m
set favorite_count = coalesce(f.cnt, 0)
from (
  select target_id, count(*) as cnt
  from public.favorites
  where target_type = 'meditation'
  group by target_id
) f
where m.id = f.target_id;

update public.meditations
set favorite_count = 0
where id not in (
  select target_id from public.favorites where target_type = 'meditation'
);
