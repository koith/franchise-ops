CREATE OR REPLACE FUNCTION public.assert_resource_access(p_kind text,p_id bigint) RETURNS void LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE s name; st bigint; q text;
BEGIN
 IF p_id IS NULL THEN RETURN; END IF;
 s:=public.current_tenant_schema();
 q:=CASE p_kind
 WHEN 'store' THEN 'SELECT id FROM %1$I.stores WHERE id=$1 AND is_active'
 WHEN 'employee' THEN 'SELECT store_id FROM %1$I.employees WHERE id=$1'
 WHEN 'period' THEN 'SELECT e.store_id FROM %1$I.employment_periods r JOIN %1$I.employees e ON e.id=r.employee_id WHERE r.id=$1'
 WHEN 'contract' THEN 'SELECT e.store_id FROM %1$I.employment_contracts r JOIN %1$I.employment_periods p ON p.id=r.employment_period_id JOIN %1$I.employees e ON e.id=p.employee_id WHERE r.id=$1'
 WHEN 'event' THEN 'SELECT e.store_id FROM %1$I.attendance_events r JOIN %1$I.employees e ON e.id=r.employee_id WHERE r.id=$1'
 WHEN 'document' THEN 'SELECT e.store_id FROM %1$I.employee_documents r JOIN %1$I.employees e ON e.id=r.employee_id WHERE r.id=$1'
 WHEN 'request' THEN 'SELECT e.store_id FROM %1$I.correction_requests r JOIN %1$I.employees e ON e.id=r.employee_id WHERE r.id=$1'
 ELSE NULL END;
 IF q IS NULL THEN RAISE EXCEPTION 'INVALID_RESOURCE'; END IF;
 EXECUTE format(q,s) INTO st USING p_id;
 IF st IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND (m.role='HQ' OR m.store_id=st)) THEN RAISE EXCEPTION 'RESOURCE_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
END $$;
REVOKE ALL ON FUNCTION public.assert_resource_access(text,bigint) FROM PUBLIC,anon,authenticated;
