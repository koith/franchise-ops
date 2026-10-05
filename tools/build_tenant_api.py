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
 admin=not f['anon'] or n.startswith('admin_') or n in ['is_admin','is_hq_admin','can_manage_store','hq_store_dashboard']
 gate="""
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.tenant_memberships m JOIN public.tenants t ON t.id=m.tenant_id WHERE t.schema_name=s AND m.user_id=auth.uid()) THEN
 RAISE EXCEPTION 'TENANT_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 """ if admin else ''
 query=query.replace("'","''")
 out.append(f'''CREATE OR REPLACE FUNCTION public.{n}({f['full_args']}) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $api$
 DECLARE s name; result jsonb;
 BEGIN
 s:=public.current_tenant_schema();{gate}
 EXECUTE format('{query}',s) INTO result{using};
 RETURN result;
 END $api$;
 REVOKE ALL ON FUNCTION public.{n}({f['args']}) FROM PUBLIC,anon,authenticated;
 GRANT EXECUTE ON FUNCTION public.{n}({f['args']}) TO {'authenticated' if admin else 'anon,authenticated'};
 ''')
(R/'backend/tenant-api.sql').write_text('\n'.join(out));print('Wrappers',len(out))
