import json,re
from pathlib import Path
R=Path(__file__).resolve().parents[1]
m=json.loads((R/'backend/source-function-meta.json').read_text());out=[]
internal={'_contract_minutes','qa_rpc_contract_health','source_recipe_components','source_recipe_instructions','recipe_thumbnail_for_source','system_apply_due_hq_products','system_enforce_store_close','substitution_enforce_due','substitution_refresh_one','substitution_is_working','substitution_schedule_conflict'}
for f in m:
 n=f['proname']
 if f['rettype']=='trigger' or n in internal:continue
 if not(f['anon'] or f['authenticated']):continue
 modes=f['proargmodes']
 if isinstance(modes,str):modes=modes.strip('{}').split(',')
 names=[name for i,name in enumerate(f['proargnames'] or []) if not modes or modes[i] in ['i','b','v']]
 # Column names of RETURNS TABLE appear in proargnames; exclude OUT params.
 placeholders=','.join('$'+str(i+1) for i in range(len(names)))
 using=' USING '+','.join('"'+x+'"' for x in names) if names else ''
 query=("SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM %I."+n+'('+placeholders+') r') if f['proretset'] else ('SELECT to_jsonb(%I.'+n+'('+placeholders+'))')
 if n=='list_active_employees':query+=' WHERE r.store_id=public.current_store_id()'
 admin=not f['anon'] or n.startswith('admin_') or n in ['is_admin','is_hq_admin','can_manage_store','hq_store_dashboard']
 if n=='list_active_employees':admin=False
 gate="""
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 """ if admin else ''
 if admin:
  for param,kind in [('p_store_id','store'),('p_employee_id','employee'),('p_contract_id','contract'),('p_employment_period_id','period'),('p_event_id','event'),('p_document_id','document'),('p_request_id','request')]:
   if param in names:gate+=f"PERFORM public.assert_resource_access('{kind}',{param});\n"
  if 'p_id' in names:
   kind={'admin_update_employee':'employee','admin_deactivate_employee':'employee','admin_retire_employee':'employee','admin_employment_contract_set':'contract','admin_employment_period_set':'period'}.get(n)
   if kind:gate+=f"PERFORM public.assert_resource_access('{kind}',p_id);\n"
  if n in ['admin_grant','admin_revoke','admin_list_auth_users','admin_list_admins','admin_seed_operations_demo','admin_clear_operations_demo']:
   gate+="IF NOT EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='HQ') THEN RAISE EXCEPTION 'HQ_REQUIRED' USING ERRCODE='42501'; END IF;\n"
  if n=='admin_schedule_batch':gate+="FOR entry IN SELECT value FROM jsonb_array_elements(p_changes) LOOP PERFORM public.assert_resource_access('employee',(entry->>'employee_id')::bigint); END LOOP;\n"
 post=''
 manager_reads={'admin_list_employees':'id','admin_list_all_employees':'id','admin_events':'employee_id','admin_events_with_corrections':'employee_id','admin_schedule_list':'employee_id','admin_pending_requests':'employee_id','admin_employee_contract_statuses':'employee_id','admin_absence_decisions':'employee_id'}
 if n in manager_reads:
  field=manager_reads[n]
  post=f"IF EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND m.role='STORE_MANAGER') THEN EXECUTE format($filter$SELECT coalesce(jsonb_agg(v),'[]'::jsonb) FROM jsonb_array_elements($1) v JOIN %I.employees e ON e.id=(v->>'{field}')::bigint WHERE e.store_id=public.current_store_id()$filter$,s) INTO result USING result; END IF;"
 query=query.replace("'","''")
 out.append(f'''CREATE OR REPLACE FUNCTION public.{n}({f['full_args']}) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb; entry jsonb;
 BEGIN
 s:=public.current_tenant_schema();{gate}
 EXECUTE format('{query}',s) INTO result{using};
 {post}
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.{n}({f['args']}) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.{n}({f['args']}) TO {'authenticated' if admin else 'anon,authenticated'};
 ''')
(R/'backend/tenant-api.sql').write_text('\n'.join(out));print('Wrappers',len(out))
