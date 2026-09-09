-- Öğretmen kendi meditasyonunu, admin tüm meditasyonları güncelleyebilir.
-- SECURITY DEFINER kullanılır; yetki kontrolü fonksiyonun içinde açıkça yapılır.
create or replace function public.update_owned_meditation(
  p_meditation_id uuid,
  p_title text,
  p_description text,
  p_type text,
  p_category text,
  p_duration_text text,
  p_media_url text,
  p_thumbnail_url text,
  p_is_active boolean
)
returns setof public.meditations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_updated_count integer;
begin
  if v_user_id is null then
    raise exception 'Giriş yapan kullanıcı bulunamadı.';
  end if;

  select profiles.role
    into v_role
  from public.profiles
  where profiles.id = v_user_id;

  if v_role is null or v_role not in ('teacher', 'admin') then
    raise exception 'Bu işlem için öğretmen veya admin yetkisi gerekir.';
  end if;

  return query
  update public.meditations
  set
    title = p_title,
    description = p_description,
    type = p_type,
    category = p_category,
    duration_text = p_duration_text,
    media_url = p_media_url,
    thumbnail_url = p_thumbnail_url,
    is_active = p_is_active
  where meditations.id = p_meditation_id
    and (
      v_role = 'admin'
      or meditations.created_by = v_user_id
    )
  returning meditations.*;

  get diagnostics v_updated_count = row_count;

  if v_updated_count = 0 then
    raise exception 'Meditasyon bulunamadı veya güncelleme yetkisi yok.';
  end if;
end;
$$;

revoke all on function public.update_owned_meditation(
  uuid, text, text, text, text, text, text, text, boolean
) from public;

grant execute on function public.update_owned_meditation(
  uuid, text, text, text, text, text, text, text, boolean
) to authenticated;
