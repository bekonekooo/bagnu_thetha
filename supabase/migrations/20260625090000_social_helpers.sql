-- Sosyal katman yardımcı fonksiyonlari: yetki kontrolu (admin mi, ogretmen sahibi mi).

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

create or replace function public.is_my_teacher(p_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.teachers
    where id = p_id
      and user_id = auth.uid()
  );
$$;
