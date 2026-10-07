from pathlib import Path
import json,re
R=Path(__file__).resolve().parents[1]
fs=json.loads((R/'backend/source-functions.json').read_text());out=[(R/'backend/store-payroll-boundary.sql').read_text()]
for schema in ['tenant_template','tenant_sample','tenant_qa']:
 for table in ['payroll_period','payroll_period_employee','payroll_snapshot']:
  out.append(f'ALTER TABLE {schema}.{table} ADD COLUMN store_id bigint NOT NULL REFERENCES {schema}.stores(id); ALTER TABLE {schema}.{table} ALTER COLUMN store_id SET DEFAULT public.current_store_id();')
 out.append(f'ALTER TABLE {schema}.payroll_period DROP CONSTRAINT payroll_period_pkey, ADD PRIMARY KEY (ym,store_id);')
 for f in fs:
  if not any(x in f['definition'] for x in ['payroll_period','payroll_snapshot']):continue
  d=f['definition'].replace('public.',schema+'.').replace("SET search_path TO 'public'",f"SET search_path TO '{schema}'")
  d=d.replace('on conflict(ym)','on conflict(ym,store_id)').replace('on conflict (ym)','on conflict (ym,store_id)')
  d=re.sub(r'where (\w+\.)?ym\s*=\s*p_ym',lambda m:m[0]+' and '+(m[1] or '')+'store_id=public.current_store_id()',d,flags=re.I)
  d=d.replace("'^\\\\d{4}-\\\\d{2}$'", "'^[0-9]{4}-[0-9]{2}$'")
  out.append(d+';')
 out.append(f'''CREATE FUNCTION {schema}.validate_payroll_employee_store() RETURNS trigger LANGUAGE plpgsql SET search_path={schema},pg_temp AS $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM {schema}.employees WHERE id=NEW.employee_id AND store_id=NEW.store_id) THEN RAISE EXCEPTION 'EMPLOYEE_STORE_MISMATCH'; END IF;
 RETURN NEW; END $$;
 CREATE TRIGGER payroll_employee_store BEFORE INSERT OR UPDATE ON {schema}.payroll_period_employee FOR EACH ROW EXECUTE FUNCTION {schema}.validate_payroll_employee_store();
 CREATE TRIGGER payroll_snapshot_store BEFORE INSERT OR UPDATE ON {schema}.payroll_snapshot FOR EACH ROW EXECUTE FUNCTION {schema}.validate_payroll_employee_store();
 REVOKE ALL ON ALL FUNCTIONS IN SCHEMA {schema} FROM PUBLIC,anon,authenticated;''')
(R/'backend/store-payroll-migration.sql').write_text('\n'.join(out))
