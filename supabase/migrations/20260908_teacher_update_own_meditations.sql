-- Öğretmenler yalnızca kendi meditasyon içeriklerini güncelleyebilsin.
drop policy if exists "Teachers can update own meditations"
on public.meditations;

create policy "Teachers can update own meditations"
on public.meditations
for update
to authenticated
using (
  created_by = auth.uid()
  and exists (
    select 1
    from public.profiles
    where profiles.id = auth.uid()
      and profiles.role in ('teacher', 'admin')
  )
)
with check (
  created_by = auth.uid()
);
