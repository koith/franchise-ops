create or replace function public.current_tenant_schema()
returns name language plpgsql stable security definer
set search_path to public,pg_temp
as $fn$
declare result name; slug_value text;
begin
 slug_value:=nullif(current_setting('request.headers',true),'')::jsonb->>'x-tenant-id';
 if auth.uid() is null then raise exception 'AUTH_REQUIRED' using errcode='42501'; end if;
 select t.schema_name into result from public.tenants t
 join public.tenant_memberships m on m.tenant_id=t.id and m.user_id=auth.uid()
 where t.slug=slug_value and t.active;
 if result is null then raise exception 'TENANT_NOT_AUTHORIZED' using errcode='42501'; end if;
 return result;
end $fn$;
