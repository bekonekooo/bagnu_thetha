-- Meditasyon güncelleme izinlerini tek ve kontrollü bir policy altında toplar.
drop policy if exists "Meditation owners can update"
on public.meditations;

drop policy if exists "Teachers can update own meditations"
on public.meditations;

drop policy if exists "content_base_update_meditations"
on public.meditations;

drop policy if exists "admins_update_meditations"
on public.meditations;

create policy "Teachers and admins can update meditations"
on public.meditations
for update
to authenticated
using (
  is_admin()
  OR (
    created_by = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'teacher'
    )
  )
)
with check (
  is_admin()
  OR created_by = auth.uid()
);
