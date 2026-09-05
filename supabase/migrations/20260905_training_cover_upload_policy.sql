drop policy if exists "Teachers can upload training covers"
on storage.objects;

create policy "Teachers can upload training covers"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'workshop-covers'
  and (storage.foldername(name))[1] = auth.uid()::text
  and exists (
    select 1
    from public.teachers as t
    where t.user_id = auth.uid()
      and coalesce(t.is_active, true) = true
  )
);
