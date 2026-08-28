-- İçerik erişimi ve görüntülenme sayaçları
alter table public.meditations
  add column if not exists is_plus_only boolean not null default false;

alter table public.meditations
  add column if not exists view_count bigint not null default 0;

alter table public.workshops
  add column if not exists is_plus_only boolean not null default false;

alter table public.workshops
  add column if not exists view_count bigint not null default 0;

-- Eski oynatma geçmişinden bilinen başlangıç değerlerini doldur.
update public.meditations as m
set view_count = source.total_views
from (
  select meditation_id, count(*)::bigint as total_views
  from public.content_play_history
  where content_type = 'meditation'
    and meditation_id is not null
  group by meditation_id
) as source
where m.id = source.meditation_id
  and coalesce(m.view_count, 0) = 0;

update public.workshops as w
set view_count = source.total_views
from (
  select workshop_id, count(*)::bigint as total_views
  from public.content_play_history
  where content_type = 'workshop_day'
    and workshop_id is not null
  group by workshop_id
) as source
where w.id = source.workshop_id
  and coalesce(w.view_count, 0) = 0;

create or replace function public.increment_meditation_view(
  target_meditation_id uuid
)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  next_view_count bigint;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.meditations as m
  set view_count = coalesce(m.view_count, 0) + 1
  where m.id = target_meditation_id
    and m.is_active = true
    and (
      m.is_plus_only = false
      or exists (
        select 1
        from public.profiles as p
        where p.id = auth.uid()
          and p.is_subscribed = true
          and (
            p.subscription_ends_at is null
            or p.subscription_ends_at > now()
          )
      )
    )
  returning m.view_count into next_view_count;

  if next_view_count is null then
    raise exception 'Meditation not found or access denied';
  end if;

  return next_view_count;
end;
$$;

create or replace function public.increment_workshop_view(
  target_workshop_id uuid
)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  next_view_count bigint;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.workshops as w
  set view_count = coalesce(w.view_count, 0) + 1
  where w.id = target_workshop_id
    and w.is_active = true
    and (
      w.is_plus_only = false
      or exists (
        select 1
        from public.profiles as p
        where p.id = auth.uid()
          and p.is_subscribed = true
          and (
            p.subscription_ends_at is null
            or p.subscription_ends_at > now()
          )
      )
    )
  returning w.view_count into next_view_count;

  if next_view_count is null then
    raise exception 'Workshop not found or access denied';
  end if;

  return next_view_count;
end;
$$;

revoke all on function public.increment_meditation_view(uuid) from public;
grant execute on function public.increment_meditation_view(uuid) to authenticated;

revoke all on function public.increment_workshop_view(uuid) from public;
grant execute on function public.increment_workshop_view(uuid) to authenticated;
