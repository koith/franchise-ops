-- Dedicated generic Supabase only. Never apply to attendance-proto production.
create or replace function public.tenant_store_list(p_slug text)
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $fn$
declare
  v_tenant public.tenants%rowtype;
  v_member public.tenant_memberships%rowtype;
  v_stores jsonb;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED' using errcode='42501';
  end if;
  select * into v_tenant from public.tenants where slug=p_slug and active;
  if not found then
    raise exception 'TENANT_NOT_FOUND' using errcode='42501';
  end if;
  select * into v_member from public.tenant_memberships
   where tenant_id=v_tenant.id and user_id=auth.uid();
  if not found then
    raise exception 'TENANT_NOT_AUTHORIZED' using errcode='42501';
  end if;
  execute format(
    'select coalesce(jsonb_agg(jsonb_build_object(''id'',id,''name'',name,''region'',region_group,''code'',code) order by name),''[]''::jsonb) from %I.stores where is_active and ($1 = ''HQ'' or id=$2)',
    v_tenant.schema_name
  ) into v_stores using v_member.role,v_member.store_id;
  return v_stores;
end
$fn$;
revoke all on function public.tenant_store_list(text) from public, anon;
grant execute on function public.tenant_store_list(text) to authenticated;
