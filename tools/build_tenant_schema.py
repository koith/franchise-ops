"""Build isolated tenant schemas from the exact source catalog; never copies rows."""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
c=json.loads((ROOT/'backend/source-catalog.json').read_text());fs=json.loads((ROOT/'backend/source-functions.json').read_text());meta=json.loads((ROOT/'backend/source-function-meta.json').read_text())
# Each tenant owns the complete original row shapes, constraints and business functions.
# PostgREST only exposes public wrappers. Tenant schemas are never API exposed.
s='tenant_template'
out=['CREATE SCHEMA IF NOT EXISTS extensions;', 'CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;',f'CREATE SCHEMA {s};',f'SET search_path={s},extensions,public;', 'SET check_function_bodies=off;']
for t in c['tables']:
 for col in t['columns']:
  d=col['default'] or ''
  if d.startswith('nextval('):out.append('CREATE SEQUENCE '+re.search("nextval\\('([^']+)'",d)[1]+';')
 cols=[]
 for col in t['columns']:
  x='"'+col['name']+'" '+col['type']
  if col['identity']:x+=' GENERATED '+('ALWAYS' if col['identity']=='a' else 'BY DEFAULT')+' AS IDENTITY'
  elif t['name']=='inventory_count_lines' and col['name']=='variance':x+=' GENERATED ALWAYS AS ('+col['default']+') STORED'
  elif col['default'] is not None:
   d=col['default'].replace('백억커피재고','inventory-import')
   if t['name'] in ['store_settings','inventory_manual_items'] and col['name'] in ['id','store_id']:d=None
   if d is not None:x+=' DEFAULT '+d
  if col['notnull']:x+=' NOT NULL'
  cols.append(x)
 out.append('CREATE TABLE '+t['name']+' ('+',\n'.join(cols)+');')
# Foreign keys after all tables exist.
for t in c['tables']:
 for con in t['constraints'] or []:
  if con['type']=='f' or con['name']=='store_settings_id_check':continue
  out.append('ALTER TABLE '+t['name']+' ADD CONSTRAINT '+con['name']+' '+con['definition'].replace('public.',s+'.')+';')
 keys={x['name'] for x in t['constraints'] or []}
 for idx in t['indexes'] or []:
  if re.search(r'INDEX (\S+)',idx)[1] not in keys:out.append(idx.replace('public.',s+'.')+';')
for t in c['tables']:
 for con in t['constraints'] or []:
  if con['type']=='f':out.append('ALTER TABLE '+t['name']+' ADD CONSTRAINT '+con['name']+' '+con['definition'].replace('public.',s+'.')+';')
for f in fs:
 d=f['definition'].replace('public.',s+'.').replace("SET search_path TO 'public'",f"SET search_path TO '{s}'")
 # Tenant administrators may discover/grant only already-enrolled tenant members.
 if f['proname'] in ['admin_list_auth_users','admin_list_admins','admin_grant']:
  d=re.sub(r'auth\.users\b',f'(select u.* from auth.users u join public.tenant_memberships tm on tm.user_id=u.id join public.tenants tt on tt.id=tm.tenant_id where tt.schema_name=\'{s}\')',d)
 # Existing legacy RPC declares SETOF attendance_events but omitted the added substitute column.
 if f['proname']=='admin_events':d=d.replace('ev.device_id, ev.created_at, ev.client_reported_at','ev.device_id, ev.created_at, ev.client_reported_at, ev.substitute_for_employee_id')
 out.append(d+';')
for t in c['tables']:
 for tr in t['triggers'] or []:out.append(tr.replace('public.',s+'.')+';')
 out.append('ALTER TABLE '+s+'.'+t['name']+' ENABLE ROW LEVEL SECURITY;')
out += [f'REVOKE ALL ON SCHEMA {s} FROM PUBLIC,anon,authenticated;',f'REVOKE ALL ON ALL TABLES IN SCHEMA {s} FROM PUBLIC,anon,authenticated;',f'REVOKE ALL ON ALL FUNCTIONS IN SCHEMA {s} FROM PUBLIC,anon,authenticated;','SET search_path=public;']
(ROOT/'backend/tenant-template.sql').write_text('\n'.join(out))
print('Generated',len(c['tables']),'tables and',len(fs),'functions')
