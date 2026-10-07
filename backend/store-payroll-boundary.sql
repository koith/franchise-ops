CREATE FUNCTION public.current_store_id() RETURNS bigint LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE st bigint; s name; valid boolean;
BEGIN
 s:=public.current_tenant_schema();
 st:=nullif(nullif(current_setting('request.headers',true),'')::jsonb->>'x-store-id','')::bigint;
 IF st IS NULL THEN RAISE EXCEPTION 'STORE_REQUIRED' USING ERRCODE='42501'; END IF;
 EXECUTE format('SELECT EXISTS(SELECT 1 FROM %I.stores WHERE id=$1 AND is_active)',s) INTO valid USING st;
 IF NOT valid THEN RAISE EXCEPTION 'STORE_NOT_FOUND' USING ERRCODE='42501'; END IF;
 IF auth.uid() IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND (m.role='HQ' OR m.store_id=st)) THEN RAISE EXCEPTION 'STORE_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 RETURN st;
END $$;
REVOKE ALL ON FUNCTION public.current_store_id() FROM PUBLIC,anon,authenticated;
