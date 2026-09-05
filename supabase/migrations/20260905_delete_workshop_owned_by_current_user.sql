create or replace function public.delete_workshop_owned_by_current_user(
  p_workshop_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  deleted_count integer;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if not exists (
    select 1
    from public.profiles as p
    where p.id = auth.uid()
      and p.role in ('teacher', 'admin')
  ) then
    return false;
  end if;

  if not exists (
    select 1
    from public.workshops as w
    where w.id = p_workshop_id
      and w.created_by = auth.uid()
  ) then
    return false;
  end if;

  delete from public.workshop_comments
  where workshop_id = p_workshop_id;

  delete from public.workshop_likes
  where workshop_id = p_workshop_id;

  delete from public.workshop_students
  where workshop_id = p_workshop_id;

  delete from public.workshop_days
  where workshop_id = p_workshop_id;

  delete from public.workshops
  where id = p_workshop_id
    and created_by = auth.uid();

  get diagnostics deleted_count = row_count;

  return deleted_count > 0;
end;
$$;

revoke all on function public.delete_workshop_owned_by_current_user(uuid)
from public;

grant execute on function public.delete_workshop_owned_by_current_user(uuid)
to authenticated;

drop policy if exists "Teachers can delete workshop media"
on storage.objects;

create policy "Teachers can delete workshop media"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'workshop-media'
  and (storage.foldername(name))[1] = auth.uid()::text
  and exists (
    select 1
    from public.teachers as t
    where t.user_id = auth.uid()
      and coalesce(t.is_active, true) = true
  )
);

drop policy if exists "Teachers can delete workshop covers"
on storage.objects;

create policy "Teachers can delete workshop covers"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'workshop-covers'
  and (storage.foldername(name))[1] = auth.uid()::text
  and exists (
    select 1
    from public.teachers as t
    where t.user_id = auth.uid()
      and coalesce(t.is_active, true) = true
  )
);
