import json,re
from pathlib import Path
R=Path(__file__).resolve().parents[1]
functions=json.loads((R/'backend/source-functions.json').read_text())
readers={'admin_operations_summary','admin_operations_analytics','admin_operations_channels','admin_operations_inquiry','admin_operations_transactions','admin_operations_trend','admin_operations_imports','admin_reconciliation_issues','admin_inventory_movements','admin_inventory_overview','admin_inventory_overview_v2','admin_inventory_overview_v3'}
keywords={'where','group','order','left','right','inner','join','on','union','limit','for','cross','full','into','returning','having'}
out=['''CREATE OR REPLACE FUNCTION public.current_store_keys() RETURNS text[] LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE s name; st bigint; key text;
BEGIN s:=public.current_tenant_schema();st:=public.current_store_id();
EXECUTE format('SELECT source_store_key FROM %I.stores WHERE id=$1',s) INTO key USING st;
RETURN array_remove(ARRAY[key,'store-'||st],NULL);END $$;
REVOKE ALL ON FUNCTION public.current_store_keys() FROM PUBLIC,anon,authenticated;''']
for schema in ['tenant_template','tenant_sample','tenant_qa']:
 for table in ['inventory_movements','operations_reconciliation_issues']:
  out.append(f'ALTER TABLE {schema}.{table} ADD COLUMN store_id bigint NOT NULL REFERENCES {schema}.stores(id); ALTER TABLE {schema}.{table} ALTER COLUMN store_id SET DEFAULT public.current_store_id();')
 for f in functions:
  d=f['definition'];match=re.search(r'FUNCTION public\.(\w+)\(',d)
  if not match or match[1] not in readers|{'admin_operations_import_stage'}:continue
  name=match[1];d=d.replace('public.',schema+'.').replace("SET search_path TO 'public'",f"SET search_path TO '{schema}'")
  if name in readers:
   for table,predicate in [('operations_transactions','source_store_key=ANY(public.current_store_keys())'),('operations_import_batches','source_store_key=ANY(public.current_store_keys())'),('inventory_movements','store_id=public.current_store_id()'),('operations_reconciliation_issues','store_id=public.current_store_id()')]:
    pattern=rf'\b(FROM|JOIN)\s+(?:{schema}\.)?{table}\b(?:\s+(?:AS\s+)?(\w+))?'
    def replace(m):
     alias=m[2];tail=''
     if not alias or alias.lower() in keywords:tail=(' '+alias) if alias else '';alias=table
     return f'{m[1]} (SELECT * FROM {schema}.{table} WHERE {predicate}) {alias}'+tail
    d=re.sub(pattern,replace,d,flags=re.I)
  else:
   d=d.replace("'default',sk,bdate", "'store-'||public.current_store_id(),sk,bdate")
   d=d.replace("'store-'||coalesce(nullif(current_setting('request.headers',true)::jsonb->>'x-store-id',''),'default')","'store-'||public.current_store_id()")
  out.append(d+';')
 out.append(f'REVOKE ALL ON ALL FUNCTIONS IN SCHEMA {schema} FROM PUBLIC,anon,authenticated;')
(R/'backend/store-operations-migration.sql').write_text('\n'.join(out))
