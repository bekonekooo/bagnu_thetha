-- Öğretmen kendi atölyesini, admin tüm atölyeleri güncelleyebilir.
-- Atölye ve günlük içerikleri tek transaction içinde güncellenir.
create or replace function public.update_owned_workshop(
  p_workshop_id uuid,
  p_title text,
  p_description text,
  p_image_url text,
  p_category text,
  p_duration_days integer,
  p_price numeric,
  p_currency text,
  p_capacity integer,
  p_days jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_updated_id uuid;
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

  if p_duration_days < 1 or p_duration_days > 20 then
    raise exception 'Atölye süresi 1 ile 20 gün arasında olmalıdır.';
  end if;

  if jsonb_typeof(p_days) <> 'array'
     or jsonb_array_length(p_days) <> p_duration_days then
    raise exception 'Her atölye günü için bir içerik eklemelisin.';
  end if;

  update public.workshops
  set
    title = p_title,
    description = p_description,
    image_url = p_image_url,
    category = p_category,
    duration_days = p_duration_days,
    price = p_price,
    currency = p_currency,
    capacity = p_capacity,
    updated_at = now()
  where workshops.id = p_workshop_id
    and (
      v_role = 'admin'
      or workshops.created_by = v_user_id
    )
  returning workshops.id into v_updated_id;

  if v_updated_id is null then
    raise exception 'Atölye bulunamadı veya güncelleme yetkisi yok.';
  end if;

  delete from public.workshop_days
  where workshop_id = p_workshop_id;

  insert into public.workshop_days (
    workshop_id,
    day_number,
    title,
    description,
    content_type,
    content_url,
    duration_text
  )
  select
    p_workshop_id,
    (day->>'day_number')::integer,
    coalesce(day->>'title', ''),
    coalesce(day->>'description', ''),
    coalesce(day->>'content_type', ''),
    coalesce(day->>'content_url', ''),
    coalesce(day->>'duration_text', '')
  from jsonb_array_elements(p_days) as day;

  return jsonb_build_object('id', v_updated_id);
end;
$$;

revoke all on function public.update_owned_workshop(
  uuid, text, text, text, text, integer, numeric, text, integer, jsonb
) from public;

grant execute on function public.update_owned_workshop(
  uuid, text, text, text, text, integer, numeric, text, integer, jsonb
) to authenticated;
