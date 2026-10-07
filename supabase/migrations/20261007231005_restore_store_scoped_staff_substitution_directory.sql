CREATE OR REPLACE FUNCTION public.admin_absence_decision_set(p_employee_id bigint, p_work_date date, p_decision text, p_note text DEFAULT NULL::text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_absence_decision_set($1,$2,$3,$4))',s) INTO result USING "p_employee_id","p_work_date","p_decision","p_note";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_absence_decision_set(p_employee_id bigint, p_work_date date, p_decision text, p_note text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_absence_decision_set(p_employee_id bigint, p_work_date date, p_decision text, p_note text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_absence_decisions(p_from date, p_to date, p_employee_id bigint DEFAULT NULL::bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_absence_decisions($1,$2,$3) r',s) INTO result USING "p_from","p_to","p_employee_id";
 IF EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='STORE_MANAGER') THEN EXECUTE format($filter$SELECT coalesce(jsonb_agg(v),'[]'::jsonb) FROM jsonb_array_elements($1) v JOIN %I.employees e ON e.id=(v->>'employee_id')::bigint WHERE e.store_id=public.current_store_id()$filter$,s) INTO result USING result; END IF;
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_absence_decisions(p_from date, p_to date, p_employee_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_absence_decisions(p_from date, p_to date, p_employee_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_attendance_break_decision_save(p_store_id bigint, p_employee_id bigint, p_in_event_id bigint, p_break_provided boolean, p_compensate_30m boolean) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);
PERFORM public.assert_resource_access('employee',p_employee_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_attendance_break_decision_save($1,$2,$3,$4,$5))',s) INTO result USING "p_store_id","p_employee_id","p_in_event_id","p_break_provided","p_compensate_30m";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_attendance_break_decision_save(p_store_id bigint, p_employee_id bigint, p_in_event_id bigint, p_break_provided boolean, p_compensate_30m boolean) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_attendance_break_decision_save(p_store_id bigint, p_employee_id bigint, p_in_event_id bigint, p_break_provided boolean, p_compensate_30m boolean) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_attendance_break_decisions(p_store_id bigint, p_from timestamp without time zone, p_to timestamp without time zone) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_attendance_break_decisions($1,$2,$3))',s) INTO result USING "p_store_id","p_from","p_to";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_attendance_break_decisions(p_store_id bigint, p_from timestamp without time zone, p_to timestamp without time zone) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_attendance_break_decisions(p_store_id bigint, p_from timestamp without time zone, p_to timestamp without time zone) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_clear_operations_demo() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='HQ') THEN RAISE EXCEPTION 'HQ_REQUIRED' USING ERRCODE='42501'; END IF;

 EXECUTE format('SELECT to_jsonb(%I.admin_clear_operations_demo())',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_clear_operations_demo() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_clear_operations_demo() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_close_payroll(p_ym text, p_rows json, p_fingerprint text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_close_payroll($1,$2,$3))',s) INTO result USING "p_ym","p_rows","p_fingerprint";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_close_payroll(p_ym text, p_rows json, p_fingerprint text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_close_payroll(p_ym text, p_rows json, p_fingerprint text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_context() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_context())',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_context() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_context() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_contract_break_policy_set(p_contract_id bigint, p_break_time_provided boolean) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('contract',p_contract_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_contract_break_policy_set($1,$2))',s) INTO result USING "p_contract_id","p_break_time_provided";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_contract_break_policy_set(p_contract_id bigint, p_break_time_provided boolean) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_contract_break_policy_set(p_contract_id bigint, p_break_time_provided boolean) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_contract_doc_add(p_employee_id bigint, p_contract_id bigint, p_storage_path text, p_filename text, p_content_type text, p_byte_size integer) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);
PERFORM public.assert_resource_access('contract',p_contract_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_contract_doc_add($1,$2,$3,$4,$5,$6))',s) INTO result USING "p_employee_id","p_contract_id","p_storage_path","p_filename","p_content_type","p_byte_size";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_contract_doc_add(p_employee_id bigint, p_contract_id bigint, p_storage_path text, p_filename text, p_content_type text, p_byte_size integer) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_contract_doc_add(p_employee_id bigint, p_contract_id bigint, p_storage_path text, p_filename text, p_content_type text, p_byte_size integer) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_contract_doc_list(p_employee_id bigint, p_contract_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);
PERFORM public.assert_resource_access('contract',p_contract_id);

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_contract_doc_list($1,$2) r',s) INTO result USING "p_employee_id","p_contract_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_contract_doc_list(p_employee_id bigint, p_contract_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_contract_doc_list(p_employee_id bigint, p_contract_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_contract_night_end_set(p_contract_id bigint, p_night_allowance_end time without time zone) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('contract',p_contract_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_contract_night_end_set($1,$2))',s) INTO result USING "p_contract_id","p_night_allowance_end";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_contract_night_end_set(p_contract_id bigint, p_night_allowance_end time without time zone) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_contract_night_end_set(p_contract_id bigint, p_night_allowance_end time without time zone) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_contract_weekly_preview(p_contract_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('contract',p_contract_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_contract_weekly_preview($1))',s) INTO result USING "p_contract_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_contract_weekly_preview(p_contract_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_contract_weekly_preview(p_contract_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_correct_event(p_action text, p_event_id bigint, p_employee_id bigint, p_new_at timestamp without time zone, p_new_type text, p_reason text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);
PERFORM public.assert_resource_access('event',p_event_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_correct_event($1,$2,$3,$4,$5,$6))',s) INTO result USING "p_action","p_event_id","p_employee_id","p_new_at","p_new_type","p_reason";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_correct_event(p_action text, p_event_id bigint, p_employee_id bigint, p_new_at timestamp without time zone, p_new_type text, p_reason text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_correct_event(p_action text, p_event_id bigint, p_employee_id bigint, p_new_at timestamp without time zone, p_new_type text, p_reason text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_create_employee(p_name text, p_pin text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_create_employee($1,$2))',s) INTO result USING "p_name","p_pin";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_create_employee(p_name text, p_pin text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_create_employee(p_name text, p_pin text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_create_employee_for_store(p_name text, p_pin text, p_store_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_create_employee_for_store($1,$2,$3))',s) INTO result USING "p_name","p_pin","p_store_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_create_employee_for_store(p_name text, p_pin text, p_store_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_create_employee_for_store(p_name text, p_pin text, p_store_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_create_employee_onboarding(p_name text, p_pin text, p_started_on date, p_payroll_type text, p_hourly_wage integer, p_monthly_salary integer, p_tax_treatment text, p_business_deduction_rate numeric, p_night_allowance_enabled boolean, p_night_allowance_mode text, p_night_allowance_value numeric, p_night_allowance_start time without time zone, p_memo text, p_workdays jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_create_employee_onboarding($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14))',s) INTO result USING "p_name","p_pin","p_started_on","p_payroll_type","p_hourly_wage","p_monthly_salary","p_tax_treatment","p_business_deduction_rate","p_night_allowance_enabled","p_night_allowance_mode","p_night_allowance_value","p_night_allowance_start","p_memo","p_workdays";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_create_employee_onboarding(p_name text, p_pin text, p_started_on date, p_payroll_type text, p_hourly_wage integer, p_monthly_salary integer, p_tax_treatment text, p_business_deduction_rate numeric, p_night_allowance_enabled boolean, p_night_allowance_mode text, p_night_allowance_value numeric, p_night_allowance_start time without time zone, p_memo text, p_workdays jsonb) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_create_employee_onboarding(p_name text, p_pin text, p_started_on date, p_payroll_type text, p_hourly_wage integer, p_monthly_salary integer, p_tax_treatment text, p_business_deduction_rate numeric, p_night_allowance_enabled boolean, p_night_allowance_mode text, p_night_allowance_value numeric, p_night_allowance_start time without time zone, p_memo text, p_workdays jsonb) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_create_employee_onboarding_for_store(p_name text, p_pin text, p_started_on date, p_payroll_type text, p_hourly_wage integer, p_monthly_salary integer, p_tax_treatment text, p_business_deduction_rate numeric, p_night_allowance_enabled boolean, p_night_allowance_mode text, p_night_allowance_value numeric, p_night_allowance_start time without time zone, p_memo text, p_workdays jsonb, p_store_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_create_employee_onboarding_for_store($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15))',s) INTO result USING "p_name","p_pin","p_started_on","p_payroll_type","p_hourly_wage","p_monthly_salary","p_tax_treatment","p_business_deduction_rate","p_night_allowance_enabled","p_night_allowance_mode","p_night_allowance_value","p_night_allowance_start","p_memo","p_workdays","p_store_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_create_employee_onboarding_for_store(p_name text, p_pin text, p_started_on date, p_payroll_type text, p_hourly_wage integer, p_monthly_salary integer, p_tax_treatment text, p_business_deduction_rate numeric, p_night_allowance_enabled boolean, p_night_allowance_mode text, p_night_allowance_value numeric, p_night_allowance_start time without time zone, p_memo text, p_workdays jsonb, p_store_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_create_employee_onboarding_for_store(p_name text, p_pin text, p_started_on date, p_payroll_type text, p_hourly_wage integer, p_monthly_salary integer, p_tax_treatment text, p_business_deduction_rate numeric, p_night_allowance_enabled boolean, p_night_allowance_mode text, p_night_allowance_value numeric, p_night_allowance_start time without time zone, p_memo text, p_workdays jsonb, p_store_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_deactivate_employee(p_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_deactivate_employee($1))',s) INTO result USING "p_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_deactivate_employee(p_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_deactivate_employee(p_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_doc_add(p_employee_id bigint, p_storage_path text, p_filename text, p_content_type text, p_byte_size integer) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_doc_add($1,$2,$3,$4,$5))',s) INTO result USING "p_employee_id","p_storage_path","p_filename","p_content_type","p_byte_size";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_doc_add(p_employee_id bigint, p_storage_path text, p_filename text, p_content_type text, p_byte_size integer) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_doc_add(p_employee_id bigint, p_storage_path text, p_filename text, p_content_type text, p_byte_size integer) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_doc_delete(p_document_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('document',p_document_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_doc_delete($1))',s) INTO result USING "p_document_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_doc_delete(p_document_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_doc_delete(p_document_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_doc_list(p_employee_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_doc_list($1) r',s) INTO result USING "p_employee_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_doc_list(p_employee_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_doc_list(p_employee_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_employee_contract_statuses() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_employee_contract_statuses() r',s) INTO result;
 IF EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='STORE_MANAGER') THEN EXECUTE format($filter$SELECT coalesce(jsonb_agg(v),'[]'::jsonb) FROM jsonb_array_elements($1) v JOIN %I.employees e ON e.id=(v->>'employee_id')::bigint WHERE e.store_id=public.current_store_id()$filter$,s) INTO result USING result; END IF;
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_employee_contract_statuses() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_employee_contract_statuses() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_employment_bundle(p_employee_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_employment_bundle($1))',s) INTO result USING "p_employee_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_employment_bundle(p_employee_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_employment_bundle(p_employee_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_employment_contract_set(p_id bigint, p_employment_period_id bigint, p_effective_from date, p_effective_to date, p_payroll_type text, p_hourly_wage integer, p_monthly_salary integer, p_tax_treatment text, p_business_deduction_rate numeric, p_night_allowance_enabled boolean, p_night_allowance_mode text, p_night_allowance_value numeric, p_night_allowance_start time without time zone, p_memo text, p_workdays jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('period',p_employment_period_id);
PERFORM public.assert_resource_access('contract',p_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_employment_contract_set($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15))',s) INTO result USING "p_id","p_employment_period_id","p_effective_from","p_effective_to","p_payroll_type","p_hourly_wage","p_monthly_salary","p_tax_treatment","p_business_deduction_rate","p_night_allowance_enabled","p_night_allowance_mode","p_night_allowance_value","p_night_allowance_start","p_memo","p_workdays";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_employment_contract_set(p_id bigint, p_employment_period_id bigint, p_effective_from date, p_effective_to date, p_payroll_type text, p_hourly_wage integer, p_monthly_salary integer, p_tax_treatment text, p_business_deduction_rate numeric, p_night_allowance_enabled boolean, p_night_allowance_mode text, p_night_allowance_value numeric, p_night_allowance_start time without time zone, p_memo text, p_workdays jsonb) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_employment_contract_set(p_id bigint, p_employment_period_id bigint, p_effective_from date, p_effective_to date, p_payroll_type text, p_hourly_wage integer, p_monthly_salary integer, p_tax_treatment text, p_business_deduction_rate numeric, p_night_allowance_enabled boolean, p_night_allowance_mode text, p_night_allowance_value numeric, p_night_allowance_start time without time zone, p_memo text, p_workdays jsonb) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_employment_period_contract_create(p_employee_id bigint, p_started_on date, p_ended_on date, p_period_note text, p_effective_from date, p_effective_to date, p_payroll_type text, p_hourly_wage integer, p_monthly_salary integer, p_tax_treatment text, p_business_deduction_rate numeric, p_night_allowance_enabled boolean, p_night_allowance_mode text, p_night_allowance_value numeric, p_night_allowance_start time without time zone, p_contract_memo text, p_workdays jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_employment_period_contract_create($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17))',s) INTO result USING "p_employee_id","p_started_on","p_ended_on","p_period_note","p_effective_from","p_effective_to","p_payroll_type","p_hourly_wage","p_monthly_salary","p_tax_treatment","p_business_deduction_rate","p_night_allowance_enabled","p_night_allowance_mode","p_night_allowance_value","p_night_allowance_start","p_contract_memo","p_workdays";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_employment_period_contract_create(p_employee_id bigint, p_started_on date, p_ended_on date, p_period_note text, p_effective_from date, p_effective_to date, p_payroll_type text, p_hourly_wage integer, p_monthly_salary integer, p_tax_treatment text, p_business_deduction_rate numeric, p_night_allowance_enabled boolean, p_night_allowance_mode text, p_night_allowance_value numeric, p_night_allowance_start time without time zone, p_contract_memo text, p_workdays jsonb) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_employment_period_contract_create(p_employee_id bigint, p_started_on date, p_ended_on date, p_period_note text, p_effective_from date, p_effective_to date, p_payroll_type text, p_hourly_wage integer, p_monthly_salary integer, p_tax_treatment text, p_business_deduction_rate numeric, p_night_allowance_enabled boolean, p_night_allowance_mode text, p_night_allowance_value numeric, p_night_allowance_start time without time zone, p_contract_memo text, p_workdays jsonb) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_employment_period_set(p_id bigint, p_employee_id bigint, p_started_on date, p_ended_on date DEFAULT NULL::date, p_note text DEFAULT NULL::text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);
PERFORM public.assert_resource_access('period',p_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_employment_period_set($1,$2,$3,$4,$5))',s) INTO result USING "p_id","p_employee_id","p_started_on","p_ended_on","p_note";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_employment_period_set(p_id bigint, p_employee_id bigint, p_started_on date, p_ended_on date, p_note text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_employment_period_set(p_id bigint, p_employee_id bigint, p_started_on date, p_ended_on date, p_note text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_events(p_from timestamp without time zone, p_to timestamp without time zone) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_events($1,$2) r',s) INTO result USING "p_from","p_to";
 IF EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='STORE_MANAGER') THEN EXECUTE format($filter$SELECT coalesce(jsonb_agg(v),'[]'::jsonb) FROM jsonb_array_elements($1) v JOIN %I.employees e ON e.id=(v->>'employee_id')::bigint WHERE e.store_id=public.current_store_id()$filter$,s) INTO result USING result; END IF;
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_events(p_from timestamp without time zone, p_to timestamp without time zone) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_events(p_from timestamp without time zone, p_to timestamp without time zone) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_events_with_corrections(p_from timestamp without time zone, p_to timestamp without time zone) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_events_with_corrections($1,$2))',s) INTO result USING "p_from","p_to";
 IF EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='STORE_MANAGER') THEN EXECUTE format($filter$SELECT coalesce(jsonb_agg(v),'[]'::jsonb) FROM jsonb_array_elements($1) v JOIN %I.employees e ON e.id=(v->>'employee_id')::bigint WHERE e.store_id=public.current_store_id()$filter$,s) INTO result USING result; END IF;
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_events_with_corrections(p_from timestamp without time zone, p_to timestamp without time zone) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_events_with_corrections(p_from timestamp without time zone, p_to timestamp without time zone) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_grant(p_email text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='HQ') THEN RAISE EXCEPTION 'HQ_REQUIRED' USING ERRCODE='42501'; END IF;

 EXECUTE format('SELECT to_jsonb(%I.admin_grant($1))',s) INTO result USING "p_email";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_grant(p_email text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_grant(p_email text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_hq_product_apply(p_product_id bigint, p_action text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_hq_product_apply($1,$2))',s) INTO result USING "p_product_id","p_action";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_hq_product_apply(p_product_id bigint, p_action text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_hq_product_apply(p_product_id bigint, p_action text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_hq_product_list() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_hq_product_list() r',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_hq_product_list() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_hq_product_list() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_hq_product_removal_schedule(p_product_ids bigint[], p_removal_date date) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_hq_product_removal_schedule($1,$2))',s) INTO result USING "p_product_ids","p_removal_date";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_hq_product_removal_schedule(p_product_ids bigint[], p_removal_date date) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_hq_product_removal_schedule(p_product_ids bigint[], p_removal_date date) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_hq_product_save(p_product_id bigint, p_payload jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_hq_product_save($1,$2))',s) INTO result USING "p_product_id","p_payload";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_hq_product_save(p_product_id bigint, p_payload jsonb) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_hq_product_save(p_product_id bigint, p_payload jsonb) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_hq_product_schedule(p_product_id bigint, p_launch_date date) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_hq_product_schedule($1,$2))',s) INTO result USING "p_product_id","p_launch_date";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_hq_product_schedule(p_product_id bigint, p_launch_date date) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_hq_product_schedule(p_product_id bigint, p_launch_date date) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_inventory_items() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_inventory_items() r',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_inventory_items() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_inventory_items() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_inventory_manual_list(p_store_id bigint DEFAULT 1) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_inventory_manual_list($1) r',s) INTO result USING "p_store_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_inventory_manual_list(p_store_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_inventory_manual_list(p_store_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_inventory_manual_save(p_id bigint, p_store_id bigint, p_name text, p_sku text, p_category text, p_unit text, p_on_hand numeric, p_target_level numeric, p_reorder_point numeric, p_thumbnail_url text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_inventory_manual_save($1,$2,$3,$4,$5,$6,$7,$8,$9,$10))',s) INTO result USING "p_id","p_store_id","p_name","p_sku","p_category","p_unit","p_on_hand","p_target_level","p_reorder_point","p_thumbnail_url";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_inventory_manual_save(p_id bigint, p_store_id bigint, p_name text, p_sku text, p_category text, p_unit text, p_on_hand numeric, p_target_level numeric, p_reorder_point numeric, p_thumbnail_url text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_inventory_manual_save(p_id bigint, p_store_id bigint, p_name text, p_sku text, p_category text, p_unit text, p_on_hand numeric, p_target_level numeric, p_reorder_point numeric, p_thumbnail_url text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_inventory_manual_save_v2(p_id bigint, p_store_id bigint, p_name text, p_sku text, p_category text, p_unit text, p_on_hand numeric, p_target_level numeric, p_reorder_point numeric, p_thumbnail_url text, p_source_item_id bigint DEFAULT NULL::bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_inventory_manual_save_v2($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11))',s) INTO result USING "p_id","p_store_id","p_name","p_sku","p_category","p_unit","p_on_hand","p_target_level","p_reorder_point","p_thumbnail_url","p_source_item_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_inventory_manual_save_v2(p_id bigint, p_store_id bigint, p_name text, p_sku text, p_category text, p_unit text, p_on_hand numeric, p_target_level numeric, p_reorder_point numeric, p_thumbnail_url text, p_source_item_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_inventory_manual_save_v2(p_id bigint, p_store_id bigint, p_name text, p_sku text, p_category text, p_unit text, p_on_hand numeric, p_target_level numeric, p_reorder_point numeric, p_thumbnail_url text, p_source_item_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_inventory_movements(p_item_id bigint DEFAULT NULL::bigint, p_from date DEFAULT NULL::date, p_to date DEFAULT NULL::date) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_inventory_movements($1,$2,$3) r',s) INTO result USING "p_item_id","p_from","p_to";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_inventory_movements(p_item_id bigint, p_from date, p_to date) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_inventory_movements(p_item_id bigint, p_from date, p_to date) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_inventory_overview() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_inventory_overview() r',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_inventory_overview() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_inventory_overview() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_inventory_overview_v2() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_inventory_overview_v2() r',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_inventory_overview_v2() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_inventory_overview_v2() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_inventory_overview_v3() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_inventory_overview_v3() r',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_inventory_overview_v3() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_inventory_overview_v3() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_inventory_purchase_order_create(p_store_id bigint, p_item_id bigint, p_manual_item_id bigint, p_quantity numeric, p_note text DEFAULT NULL::text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_inventory_purchase_order_create($1,$2,$3,$4,$5))',s) INTO result USING "p_store_id","p_item_id","p_manual_item_id","p_quantity","p_note";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_inventory_purchase_order_create(p_store_id bigint, p_item_id bigint, p_manual_item_id bigint, p_quantity numeric, p_note text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_inventory_purchase_order_create(p_store_id bigint, p_item_id bigint, p_manual_item_id bigint, p_quantity numeric, p_note text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_inventory_purchase_order_list(p_store_id bigint DEFAULT 1, p_open_only boolean DEFAULT true) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_inventory_purchase_order_list($1,$2) r',s) INTO result USING "p_store_id","p_open_only";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_inventory_purchase_order_list(p_store_id bigint, p_open_only boolean) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_inventory_purchase_order_list(p_store_id bigint, p_open_only boolean) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_inventory_purchase_receive(p_order_id bigint, p_quantity numeric) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_inventory_purchase_receive($1,$2))',s) INTO result USING "p_order_id","p_quantity";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_inventory_purchase_receive(p_order_id bigint, p_quantity numeric) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_inventory_purchase_receive(p_order_id bigint, p_quantity numeric) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_inventory_unit_config_save(p_item_id bigint, p_stock_unit text, p_order_unit text, p_conversion_quantity numeric) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_inventory_unit_config_save($1,$2,$3,$4))',s) INTO result USING "p_item_id","p_stock_unit","p_order_unit","p_conversion_quantity";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_inventory_unit_config_save(p_item_id bigint, p_stock_unit text, p_order_unit text, p_conversion_quantity numeric) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_inventory_unit_config_save(p_item_id bigint, p_stock_unit text, p_order_unit text, p_conversion_quantity numeric) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_list_admins() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='HQ') THEN RAISE EXCEPTION 'HQ_REQUIRED' USING ERRCODE='42501'; END IF;

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_list_admins() r',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_list_admins() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_list_admins() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_list_all_employees() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_list_all_employees() r',s) INTO result;
 IF EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='STORE_MANAGER') THEN EXECUTE format($filter$SELECT coalesce(jsonb_agg(v),'[]'::jsonb) FROM jsonb_array_elements($1) v JOIN %I.employees e ON e.id=(v->>'id')::bigint WHERE e.store_id=public.current_store_id()$filter$,s) INTO result USING result; END IF;
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_list_all_employees() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_list_all_employees() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_list_auth_users() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='HQ') THEN RAISE EXCEPTION 'HQ_REQUIRED' USING ERRCODE='42501'; END IF;

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_list_auth_users() r',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_list_auth_users() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_list_auth_users() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_list_employees() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_list_employees() r',s) INTO result;
 IF EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='STORE_MANAGER') THEN EXECUTE format($filter$SELECT coalesce(jsonb_agg(v),'[]'::jsonb) FROM jsonb_array_elements($1) v JOIN %I.employees e ON e.id=(v->>'id')::bigint WHERE e.store_id=public.current_store_id()$filter$,s) INTO result USING result; END IF;
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_list_employees() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_list_employees() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_operations_analytics(p_from date, p_to date) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_operations_analytics($1,$2))',s) INTO result USING "p_from","p_to";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_operations_analytics(p_from date, p_to date) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_operations_analytics(p_from date, p_to date) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_operations_channels(p_from date, p_to date) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_operations_channels($1,$2) r',s) INTO result USING "p_from","p_to";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_operations_channels(p_from date, p_to date) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_operations_channels(p_from date, p_to date) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_operations_collect_request(p_source text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_operations_collect_request($1))',s) INTO result USING "p_source";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_operations_collect_request(p_source text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_operations_collect_request(p_source text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_operations_import_stage(p_source text, p_file_name text, p_rows jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_operations_import_stage($1,$2,$3))',s) INTO result USING "p_source","p_file_name","p_rows";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_operations_import_stage(p_source text, p_file_name text, p_rows jsonb) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_operations_import_stage(p_source text, p_file_name text, p_rows jsonb) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_operations_imports() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_operations_imports() r',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_operations_imports() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_operations_imports() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_operations_inquiry(p_from date, p_to date, p_type text DEFAULT NULL::text, p_channel text DEFAULT NULL::text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_operations_inquiry($1,$2,$3,$4) r',s) INTO result USING "p_from","p_to","p_type","p_channel";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_operations_inquiry(p_from date, p_to date, p_type text, p_channel text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_operations_inquiry(p_from date, p_to date, p_type text, p_channel text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_operations_summary(p_from date, p_to date) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_operations_summary($1,$2))',s) INTO result USING "p_from","p_to";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_operations_summary(p_from date, p_to date) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_operations_summary(p_from date, p_to date) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_operations_transactions(p_from date, p_to date, p_type text DEFAULT NULL::text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_operations_transactions($1,$2,$3) r',s) INTO result USING "p_from","p_to","p_type";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_operations_transactions(p_from date, p_to date, p_type text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_operations_transactions(p_from date, p_to date, p_type text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_operations_trend(p_window text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_operations_trend($1))',s) INTO result USING "p_window";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_operations_trend(p_window text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_operations_trend(p_window text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_payroll_period(p_ym text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_payroll_period($1))',s) INTO result USING "p_ym";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_payroll_period(p_ym text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_payroll_period(p_ym text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_payroll_substitutions(p_store_id bigint, p_ym text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_payroll_substitutions($1,$2) r',s) INTO result USING "p_store_id","p_ym";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_payroll_substitutions(p_store_id bigint, p_ym text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_payroll_substitutions(p_store_id bigint, p_ym text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_pending_requests() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_pending_requests() r',s) INTO result;
 IF EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='STORE_MANAGER') THEN EXECUTE format($filter$SELECT coalesce(jsonb_agg(v),'[]'::jsonb) FROM jsonb_array_elements($1) v JOIN %I.employees e ON e.id=(v->>'employee_id')::bigint WHERE e.store_id=public.current_store_id()$filter$,s) INTO result USING result; END IF;
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_pending_requests() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_pending_requests() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_recipe_list() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_recipe_list() r',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_recipe_list() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_recipe_list() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_recipe_list_v2() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_recipe_list_v2() r',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_recipe_list_v2() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_recipe_list_v2() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_recipe_save(p_recipe_id bigint, p_menu_name text, p_category text, p_components jsonb, p_thumbnail_url text DEFAULT NULL::text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_recipe_save($1,$2,$3,$4,$5))',s) INTO result USING "p_recipe_id","p_menu_name","p_category","p_components","p_thumbnail_url";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_recipe_save(p_recipe_id bigint, p_menu_name text, p_category text, p_components jsonb, p_thumbnail_url text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_recipe_save(p_recipe_id bigint, p_menu_name text, p_category text, p_components jsonb, p_thumbnail_url text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_reconciliation_issues(p_from date, p_to date) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_reconciliation_issues($1,$2) r',s) INTO result USING "p_from","p_to";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_reconciliation_issues(p_from date, p_to date) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_reconciliation_issues(p_from date, p_to date) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_reopen_payroll(p_ym text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_reopen_payroll($1))',s) INTO result USING "p_ym";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_reopen_payroll(p_ym text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_reopen_payroll(p_ym text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_resolve_request(p_request_id bigint, p_approve boolean, p_reject_reason text DEFAULT NULL::text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('request',p_request_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_resolve_request($1,$2,$3))',s) INTO result USING "p_request_id","p_approve","p_reject_reason";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_resolve_request(p_request_id bigint, p_approve boolean, p_reject_reason text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_resolve_request(p_request_id bigint, p_approve boolean, p_reject_reason text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_retire_employee(p_id bigint, p_ended_on date DEFAULT CURRENT_DATE) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_retire_employee($1,$2))',s) INTO result USING "p_id","p_ended_on";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_retire_employee(p_id bigint, p_ended_on date) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_retire_employee(p_id bigint, p_ended_on date) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_revoke(p_user_id uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='HQ') THEN RAISE EXCEPTION 'HQ_REQUIRED' USING ERRCODE='42501'; END IF;

 EXECUTE format('SELECT to_jsonb(%I.admin_revoke($1))',s) INTO result USING "p_user_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_revoke(p_user_id uuid) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_revoke(p_user_id uuid) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_schedule_batch(p_changes jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 FOR entry IN SELECT value FROM jsonb_array_elements(p_changes) LOOP PERFORM public.assert_resource_access('employee',(entry->>'employee_id')::bigint); END LOOP;

 EXECUTE format('SELECT to_jsonb(%I.admin_schedule_batch($1))',s) INTO result USING "p_changes";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_schedule_batch(p_changes jsonb) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_schedule_batch(p_changes jsonb) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_schedule_delete(p_employee_id bigint, p_work_date date) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_schedule_delete($1,$2))',s) INTO result USING "p_employee_id","p_work_date";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_schedule_delete(p_employee_id bigint, p_work_date date) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_schedule_delete(p_employee_id bigint, p_work_date date) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_schedule_list(p_from date, p_to date) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_schedule_list($1,$2) r',s) INTO result USING "p_from","p_to";
 IF EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='STORE_MANAGER') THEN EXECUTE format($filter$SELECT coalesce(jsonb_agg(v),'[]'::jsonb) FROM jsonb_array_elements($1) v JOIN %I.employees e ON e.id=(v->>'employee_id')::bigint WHERE e.store_id=public.current_store_id()$filter$,s) INTO result USING result; END IF;
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_schedule_list(p_from date, p_to date) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_schedule_list(p_from date, p_to date) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_schedule_set(p_employee_id bigint, p_work_date date, p_status text, p_start time without time zone, p_end time without time zone, p_memo text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_schedule_set($1,$2,$3,$4,$5,$6))',s) INTO result USING "p_employee_id","p_work_date","p_status","p_start","p_end","p_memo";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_schedule_set(p_employee_id bigint, p_work_date date, p_status text, p_start time without time zone, p_end time without time zone, p_memo text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_schedule_set(p_employee_id bigint, p_work_date date, p_status text, p_start time without time zone, p_end time without time zone, p_memo text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_seed_operations_demo() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='HQ') THEN RAISE EXCEPTION 'HQ_REQUIRED' USING ERRCODE='42501'; END IF;

 EXECUTE format('SELECT to_jsonb(%I.admin_seed_operations_demo())',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_seed_operations_demo() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_seed_operations_demo() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_set_period_employee(p_ym text, p_employee_id bigint, p_fields json) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_set_period_employee($1,$2,$3))',s) INTO result USING "p_ym","p_employee_id","p_fields";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_set_period_employee(p_ym text, p_employee_id bigint, p_fields json) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_set_period_employee(p_ym text, p_employee_id bigint, p_fields json) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_set_period_weeks(p_ym text, p_weeks integer) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_set_period_weeks($1,$2))',s) INTO result USING "p_ym","p_weeks";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_set_period_weeks(p_ym text, p_weeks integer) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_set_period_weeks(p_ym text, p_weeks integer) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_snapshot(p_ym text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_snapshot($1))',s) INTO result USING "p_ym";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_snapshot(p_ym text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_snapshot(p_ym text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_store_payroll_contract_workdays(p_store_id bigint, p_month date) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_store_payroll_contract_workdays($1,$2) r',s) INTO result USING "p_store_id","p_month";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_store_payroll_contract_workdays(p_store_id bigint, p_month date) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_store_payroll_contract_workdays(p_store_id bigint, p_month date) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_store_payroll_contracts(p_store_id bigint, p_month date) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_store_payroll_contracts($1,$2) r',s) INTO result USING "p_store_id","p_month";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_store_payroll_contracts(p_store_id bigint, p_month date) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_store_payroll_contracts(p_store_id bigint, p_month date) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_store_payroll_contracts_v2(p_store_id bigint, p_month date) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_store_payroll_contracts_v2($1,$2) r',s) INTO result USING "p_store_id","p_month";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_store_payroll_contracts_v2(p_store_id bigint, p_month date) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_store_payroll_contracts_v2(p_store_id bigint, p_month date) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_store_product_retirement_finalize(p_store_id bigint, p_product_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_store_product_retirement_finalize($1,$2))',s) INTO result USING "p_store_id","p_product_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_store_product_retirement_finalize(p_store_id bigint, p_product_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_store_product_retirement_finalize(p_store_id bigint, p_product_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_store_recipe_list(p_store_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_store_recipe_list($1) r',s) INTO result USING "p_store_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_store_recipe_list(p_store_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_store_recipe_list(p_store_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_store_recipe_override_clear(p_store_id bigint, p_menu_key text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_store_recipe_override_clear($1,$2))',s) INTO result USING "p_store_id","p_menu_key";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_store_recipe_override_clear(p_store_id bigint, p_menu_key text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_store_recipe_override_clear(p_store_id bigint, p_menu_key text) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_store_recipe_override_save(p_store_id bigint, p_menu_key text, p_menu_name text, p_category text, p_components jsonb, p_thumbnail_url text, p_instructions jsonb DEFAULT NULL::jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_store_recipe_override_save($1,$2,$3,$4,$5,$6,$7))',s) INTO result USING "p_store_id","p_menu_key","p_menu_name","p_category","p_components","p_thumbnail_url","p_instructions";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_store_recipe_override_save(p_store_id bigint, p_menu_key text, p_menu_name text, p_category text, p_components jsonb, p_thumbnail_url text, p_instructions jsonb) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_store_recipe_override_save(p_store_id bigint, p_menu_key text, p_menu_name text, p_category text, p_components jsonb, p_thumbnail_url text, p_instructions jsonb) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_store_settings_get() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_store_settings_get())',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_store_settings_get() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_store_settings_get() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_store_settings_get(p_store_id bigint DEFAULT NULL::bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_store_settings_get($1))',s) INTO result USING "p_store_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_store_settings_get(p_store_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_store_settings_get(p_store_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_store_settings_set(p_open_minute integer, p_close_minute integer, p_close_grace_minutes integer, p_store_id bigint DEFAULT NULL::bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_store_settings_set($1,$2,$3,$4))',s) INTO result USING "p_open_minute","p_close_minute","p_close_grace_minutes","p_store_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_store_settings_set(p_open_minute integer, p_close_minute integer, p_close_grace_minutes integer, p_store_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_store_settings_set(p_open_minute integer, p_close_minute integer, p_close_grace_minutes integer, p_store_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_store_settings_set(p_open_minute integer, p_close_minute integer, p_close_grace_minutes integer) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.admin_store_settings_set($1,$2,$3))',s) INTO result USING "p_open_minute","p_close_minute","p_close_grace_minutes";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_store_settings_set(p_open_minute integer, p_close_minute integer, p_close_grace_minutes integer) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_store_settings_set(p_open_minute integer, p_close_minute integer, p_close_grace_minutes integer) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_unclassified_doc_list(p_employee_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_employee_id);

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.admin_unclassified_doc_list($1) r',s) INTO result USING "p_employee_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_unclassified_doc_list(p_employee_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_unclassified_doc_list(p_employee_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.admin_update_employee(p_id bigint, p_fields jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('employee',p_id);

 EXECUTE format('SELECT to_jsonb(%I.admin_update_employee($1,$2))',s) INTO result USING "p_id","p_fields";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.admin_update_employee(p_id bigint, p_fields jsonb) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.admin_update_employee(p_id bigint, p_fields jsonb) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.can_manage_store(p_store_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT to_jsonb(%I.can_manage_store($1))',s) INTO result USING "p_store_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.can_manage_store(p_store_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.can_manage_store(p_store_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.hq_store_dashboard() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.hq_store_dashboard() r',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.hq_store_dashboard() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.hq_store_dashboard() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.is_admin())',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.is_hq_admin() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 
 EXECUTE format('SELECT to_jsonb(%I.is_hq_admin())',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.is_hq_admin() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.is_hq_admin() TO authenticated;
 
CREATE OR REPLACE FUNCTION public.list_active_employees() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.list_active_employees() r WHERE r.store_id=public.current_store_id()',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.list_active_employees() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.list_active_employees() TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.list_employees_state(p_store_id bigint DEFAULT NULL::bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.list_employees_state($1) r',s) INTO result USING "p_store_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.list_employees_state(p_store_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.list_employees_state(p_store_id bigint) TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.list_store_employees(p_store_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 PERFORM public.assert_resource_access('store',p_store_id);

 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.list_store_employees($1) r',s) INTO result USING "p_store_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.list_store_employees(p_store_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.list_store_employees(p_store_id bigint) TO authenticated;
 
CREATE OR REPLACE FUNCTION public.list_stores() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.list_stores() r',s) INTO result;
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.list_stores() FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.list_stores() TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.my_events(p_employee_id bigint, p_pin text, p_from timestamp without time zone, p_to timestamp without time zone) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT to_jsonb(%I.my_events($1,$2,$3,$4))',s) INTO result USING "p_employee_id","p_pin","p_from","p_to";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.my_events(p_employee_id bigint, p_pin text, p_from timestamp without time zone, p_to timestamp without time zone) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.my_events(p_employee_id bigint, p_pin text, p_from timestamp without time zone, p_to timestamp without time zone) TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.punch(p_employee_id bigint, p_pin text, p_device text DEFAULT 'POS'::text, p_substitute_for_employee_id bigint DEFAULT NULL::bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT to_jsonb(%I.punch($1,$2,$3,$4))',s) INTO result USING "p_employee_id","p_pin","p_device","p_substitute_for_employee_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.punch(p_employee_id bigint, p_pin text, p_device text, p_substitute_for_employee_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.punch(p_employee_id bigint, p_pin text, p_device text, p_substitute_for_employee_id bigint) TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.request_correction(p_employee_id bigint, p_pin text, p_kind text, p_event_id bigint, p_requested_at timestamp without time zone, p_requested_type text, p_note text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT to_jsonb(%I.request_correction($1,$2,$3,$4,$5,$6,$7))',s) INTO result USING "p_employee_id","p_pin","p_kind","p_event_id","p_requested_at","p_requested_type","p_note";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.request_correction(p_employee_id bigint, p_pin text, p_kind text, p_event_id bigint, p_requested_at timestamp without time zone, p_requested_type text, p_note text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.request_correction(p_employee_id bigint, p_pin text, p_kind text, p_event_id bigint, p_requested_at timestamp without time zone, p_requested_type text, p_note text) TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.staff_actual_attendance(p_employee_id bigint, p_pin text, p_from timestamp without time zone, p_to timestamp without time zone) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT to_jsonb(%I.staff_actual_attendance($1,$2,$3,$4))',s) INTO result USING "p_employee_id","p_pin","p_from","p_to";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.staff_actual_attendance(p_employee_id bigint, p_pin text, p_from timestamp without time zone, p_to timestamp without time zone) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.staff_actual_attendance(p_employee_id bigint, p_pin text, p_from timestamp without time zone, p_to timestamp without time zone) TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.staff_recipe_list(p_employee_id bigint, p_pin text, p_store_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.staff_recipe_list($1,$2,$3) r',s) INTO result USING "p_employee_id","p_pin","p_store_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.staff_recipe_list(p_employee_id bigint, p_pin text, p_store_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.staff_recipe_list(p_employee_id bigint, p_pin text, p_store_id bigint) TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.store_recipe_list_public(p_store_id bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.store_recipe_list_public($1) r',s) INTO result USING "p_store_id";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.store_recipe_list_public(p_store_id bigint) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.store_recipe_list_public(p_store_id bigint) TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.substitution_candidate_availability(p_requester bigint, p_pin text, p_start timestamp without time zone, p_end timestamp without time zone) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(r)),''[]''::jsonb) FROM %I.substitution_candidate_availability($1,$2,$3,$4) r',s) INTO result USING "p_requester","p_pin","p_start","p_end";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.substitution_candidate_availability(p_requester bigint, p_pin text, p_start timestamp without time zone, p_end timestamp without time zone) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.substitution_candidate_availability(p_requester bigint, p_pin text, p_start timestamp without time zone, p_end timestamp without time zone) TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.substitution_clock_in(p_request bigint, p_employee bigint, p_pin text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT to_jsonb(%I.substitution_clock_in($1,$2,$3))',s) INTO result USING "p_request","p_employee","p_pin";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.substitution_clock_in(p_request bigint, p_employee bigint, p_pin text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.substitution_clock_in(p_request bigint, p_employee bigint, p_pin text) TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.substitution_request_cancel(p_request bigint, p_employee bigint, p_pin text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT to_jsonb(%I.substitution_request_cancel($1,$2,$3))',s) INTO result USING "p_request","p_employee","p_pin";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.substitution_request_cancel(p_request bigint, p_employee bigint, p_pin text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.substitution_request_cancel(p_request bigint, p_employee bigint, p_pin text) TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.substitution_request_create(p_requester bigint, p_pin text, p_substitute bigint, p_start timestamp without time zone, p_end timestamp without time zone, p_note text DEFAULT NULL::text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT to_jsonb(%I.substitution_request_create($1,$2,$3,$4,$5,$6))',s) INTO result USING "p_requester","p_pin","p_substitute","p_start","p_end","p_note";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.substitution_request_create(p_requester bigint, p_pin text, p_substitute bigint, p_start timestamp without time zone, p_end timestamp without time zone, p_note text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.substitution_request_create(p_requester bigint, p_pin text, p_substitute bigint, p_start timestamp without time zone, p_end timestamp without time zone, p_note text) TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.substitution_request_list(p_employee bigint, p_pin text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT to_jsonb(%I.substitution_request_list($1,$2))',s) INTO result USING "p_employee","p_pin";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.substitution_request_list(p_employee bigint, p_pin text) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.substitution_request_list(p_employee bigint, p_pin text) TO anon,authenticated;
 
CREATE OR REPLACE FUNCTION public.substitution_request_respond(p_request bigint, p_employee bigint, p_pin text, p_accept boolean) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();
 EXECUTE format('SELECT to_jsonb(%I.substitution_request_respond($1,$2,$3,$4))',s) INTO result USING "p_request","p_employee","p_pin","p_accept";
 
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.substitution_request_respond(p_request bigint, p_employee bigint, p_pin text, p_accept boolean) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.substitution_request_respond(p_request bigint, p_employee bigint, p_pin text, p_accept boolean) TO anon,authenticated;
 
