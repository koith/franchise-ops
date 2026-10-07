CREATE OR REPLACE FUNCTION public.current_store_keys() RETURNS text[] LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE s name; st bigint; key text;
BEGIN s:=public.current_tenant_schema();st:=public.current_store_id();
EXECUTE format('SELECT source_store_key FROM %I.stores WHERE id=$1',s) INTO key USING st;
RETURN array_remove(ARRAY[key,'store-'||st],NULL);END $$;
REVOKE ALL ON FUNCTION public.current_store_keys() FROM PUBLIC,anon,authenticated;
ALTER TABLE tenant_template.inventory_movements ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_template.stores(id); ALTER TABLE tenant_template.inventory_movements ALTER COLUMN store_id SET DEFAULT public.current_store_id();
ALTER TABLE tenant_template.operations_reconciliation_issues ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_template.stores(id); ALTER TABLE tenant_template.operations_reconciliation_issues ALTER COLUMN store_id SET DEFAULT public.current_store_id();
CREATE OR REPLACE FUNCTION tenant_template.admin_inventory_movements(p_item_id bigint DEFAULT NULL::bigint, p_from date DEFAULT NULL::date, p_to date DEFAULT NULL::date)
 RETURNS TABLE(id bigint, item_id bigint, item_name text, business_date date, movement_type text, quantity numeric, unit_cost bigint, source_type text, source_key text, note text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
begin
 if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select m.id,m.item_id,i.name,m.business_date,m.movement_type,m.quantity,m.unit_cost,m.source_type,m.source_key,m.note
 from (SELECT * FROM tenant_template.inventory_movements WHERE store_id=public.current_store_id()) m join tenant_template.inventory_items i on i.id=m.item_id
 where (p_item_id is null or m.item_id=p_item_id) and (p_from is null or m.business_date>=p_from) and (p_to is null or m.business_date<=p_to)
 order by m.business_date desc,m.id desc limit 1000;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_inventory_overview()
 RETURNS TABLE(id bigint, sku text, name text, unit text, is_active boolean, on_hand numeric, reorder_level numeric, inventory_value numeric, low_stock boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
begin
 if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query
 select i.id,i.sku,i.name,i.unit,i.is_active,
   coalesce(sum(m.quantity),0)::numeric on_hand,i.reorder_level,
   coalesce(sum(m.quantity * coalesce(m.unit_cost,0)),0)::numeric inventory_value,
   (i.reorder_level is not null and coalesce(sum(m.quantity),0)<=i.reorder_level) low_stock
 from tenant_template.inventory_items i left join (SELECT * FROM tenant_template.inventory_movements WHERE store_id=public.current_store_id()) m on m.item_id=i.id
 group by i.id order by i.is_active desc,i.name;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_inventory_overview_v2()
 RETURNS TABLE(id bigint, sku text, name text, unit text, is_active boolean, on_hand numeric, reorder_level numeric, inventory_value numeric, low_stock boolean, category text, source_unit_system text, source_minimum_text text, source_current_text text, source_order_text text, source_note text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
begin
 if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select i.id,i.sku,i.name,i.unit,i.is_active,coalesce(sum(m.quantity),0)::numeric,i.reorder_level,
 coalesce(sum(m.quantity*coalesce(m.unit_cost,0)),0)::numeric,
 (i.reorder_level is not null and coalesce(sum(m.quantity),0)<=i.reorder_level),
 i.category,i.source_unit_system,i.source_minimum_text,i.source_current_text,i.source_order_text,i.source_note
 from tenant_template.inventory_items i left join (SELECT * FROM tenant_template.inventory_movements WHERE store_id=public.current_store_id()) m on m.item_id=i.id
 group by i.id order by i.is_active desc,i.name;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_inventory_overview_v3()
 RETURNS TABLE(id bigint, sku text, name text, unit text, is_active boolean, on_hand numeric, reorder_level numeric, inventory_value numeric, low_stock boolean, category text, source_unit_system text, source_minimum_text text, source_current_text text, source_order_text text, source_note text, stock_unit text, order_unit text, conversion_quantity numeric, unit_configured boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
begin
 if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query
 select i.id,i.sku,i.name,i.unit,i.is_active,coalesce(sum(m.quantity),0)::numeric,i.reorder_level,
   coalesce(sum(m.quantity*coalesce(m.unit_cost,0)),0)::numeric,
   (i.reorder_level is not null and coalesce(sum(m.quantity),0)<=i.reorder_level),
   i.category,i.source_unit_system,i.source_minimum_text,i.source_current_text,i.source_order_text,i.source_note,
   i.stock_unit,i.order_unit,i.conversion_quantity,
   (i.stock_unit is not null and i.order_unit is not null and i.conversion_quantity is not null)
 from tenant_template.inventory_items i left join (SELECT * FROM tenant_template.inventory_movements WHERE store_id=public.current_store_id()) m on m.item_id=i.id
 group by i.id order by i.is_active desc,i.name;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_operations_analytics(p_from date, p_to date)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
declare v json;
begin
 if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 select json_build_object(
 'by_channel',coalesce((select json_agg(x) from(select coalesce(channel,'기타') channel,sum(total_amount) amount,count(*) transactions from (SELECT * FROM tenant_template.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) operations_transactions where business_date between p_from and p_to and transaction_type='SALE' and status='CONFIRMED' group by 1 order by 2 desc)x),'[]'::json),
 'daily',coalesce((select json_agg(x) from(select business_date,sum(case when transaction_type='SALE' then total_amount when transaction_type='REFUND' then -total_amount else 0 end) sales,sum(case when transaction_type='PURCHASE' then total_amount else 0 end) purchases from (SELECT * FROM tenant_template.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) operations_transactions where business_date between p_from and p_to and status='CONFIRMED' group by business_date order by business_date)x),'[]'::json),
 'open_reconciliation',(select count(*) from (SELECT * FROM tenant_template.operations_reconciliation_issues WHERE store_id=public.current_store_id()) operations_reconciliation_issues where business_date between p_from and p_to and status='OPEN'),
 'low_stock',(select count(*) from (select i.id from tenant_template.inventory_items i left join (SELECT * FROM tenant_template.inventory_movements WHERE store_id=public.current_store_id()) m on m.item_id=i.id where i.is_active and i.reorder_level is not null group by i.id having coalesce(sum(m.quantity),0)<=i.reorder_level)s)
 ) into v; return v;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_operations_channels(p_from date, p_to date)
 RETURNS TABLE(channel text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$ begin if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if; return query select distinct coalesce(x.channel,'기타') from (SELECT * FROM tenant_template.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) x where x.business_date between p_from and p_to order by 1; end $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_operations_import_stage(p_source text, p_file_name text, p_rows jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
declare bid bigint; r jsonb; n int:=0; sk text; bdate date;
begin
 if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 if coalesce(jsonb_typeof(p_rows),'')<>'array' then raise exception 'ROWS_MUST_BE_ARRAY'; end if;
 insert into operations_import_batches(source,source_store_key,idempotency_key,file_name,status,row_count,started_at)
 values(trim(p_source),'store-'||public.current_store_id(),md5(coalesce(p_file_name,'')||clock_timestamp()::text),p_file_name,'PROCESSING',jsonb_array_length(p_rows),now()) returning id into bid;
 for r in select * from jsonb_array_elements(p_rows) loop
   n:=n+1; sk:=coalesce(nullif(r->>'source_record_key',''),bid::text||'-'||n);
   begin bdate:=nullif(r->>'business_date','')::date; exception when others then bdate:=null; end;
   insert into operations_raw_records(batch_id,source,source_store_key,source_record_key,business_date,payload,payload_hash)
   values(bid,trim(p_source),'store-'||public.current_store_id(),sk,bdate,r,md5(r::text))
   on conflict(source,source_store_key,source_record_key) do update set payload=excluded.payload,payload_hash=excluded.payload_hash,business_date=excluded.business_date,ingested_at=now();
 end loop;
 update operations_import_batches set status='COMPLETED',completed_at=now() where id=bid;
 return jsonb_build_object('ok',true,'batch_id',bid,'row_count',n);
exception when others then
 if bid is not null then update operations_import_batches set status='FAILED',error_message=sqlerrm,completed_at=now() where id=bid; end if;
 raise;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_operations_imports()
 RETURNS TABLE(id bigint, source text, file_name text, status text, row_count integer, error_message text, created_at timestamp with time zone, completed_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
begin
 if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select b.id,b.source,b.file_name,b.status,b.row_count,b.error_message,b.created_at,b.completed_at
 from (SELECT * FROM tenant_template.operations_import_batches WHERE source_store_key=ANY(public.current_store_keys())) b order by b.id desc limit 100;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_operations_inquiry(p_from date, p_to date, p_type text DEFAULT NULL::text, p_channel text DEFAULT NULL::text)
 RETURNS TABLE(id bigint, business_date date, transaction_type text, channel text, counterparty text, net_amount bigint, vat_amount bigint, total_amount bigint, status text, source text, is_demo boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
begin if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
return query select x.id,x.business_date,x.transaction_type,x.channel,x.counterparty,x.net_amount,x.vat_amount,x.total_amount,x.status,x.source,x.is_demo from (SELECT * FROM tenant_template.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) x
where x.business_date between p_from and p_to and (p_type is null or x.transaction_type=p_type) and (p_channel is null or x.channel=p_channel) order by x.business_date desc,x.id desc limit 2000; end $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_operations_summary(p_from date, p_to date)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
declare v_sales bigint; v_purchases bigint; v_refunds bigint; v_tx bigint; v_items bigint; v_imports bigint;
begin
 if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 if p_from is null or p_to is null or p_to < p_from then raise exception 'INVALID_RANGE'; end if;
 select coalesce(sum(case when transaction_type='SALE' and status='CONFIRMED' then total_amount else 0 end),0),
        coalesce(sum(case when transaction_type='PURCHASE' and status='CONFIRMED' then total_amount else 0 end),0),
        coalesce(sum(case when transaction_type='REFUND' and status='CONFIRMED' then total_amount else 0 end),0),
        count(*) into v_sales,v_purchases,v_refunds,v_tx
 from (SELECT * FROM tenant_template.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) operations_transactions where business_date between p_from and p_to;
 select count(*) into v_items from tenant_template.inventory_items where is_active;
 select count(*) into v_imports from (SELECT * FROM tenant_template.operations_import_batches WHERE source_store_key=ANY(public.current_store_keys())) operations_import_batches where created_at::date between p_from and p_to;
 return json_build_object('sales',v_sales,'purchases',v_purchases,'refunds',v_refunds,'transaction_count',v_tx,'active_items',v_items,'import_count',v_imports);
end $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_operations_transactions(p_from date, p_to date, p_type text DEFAULT NULL::text)
 RETURNS TABLE(id bigint, business_date date, transaction_type text, channel text, counterparty text, net_amount bigint, vat_amount bigint, total_amount bigint, status text, source text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
begin
 if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select t.id,t.business_date,t.transaction_type,t.channel,t.counterparty,t.net_amount,t.vat_amount,t.total_amount,t.status,t.source
 from (SELECT * FROM tenant_template.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) t
 where t.business_date between p_from and p_to and (p_type is null or t.transaction_type=p_type)
 order by t.business_date desc,t.id desc limit 500;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_operations_trend(p_window text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
declare v_start timestamptz; v_bucket text; v json;
begin
 if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 case p_window
 when '1h' then v_start=now()-interval '1 hour'; v_bucket='minute';
 when '24h' then v_start=now()-interval '24 hours'; v_bucket='hour';
 when '7d' then v_start=now()-interval '7 days'; v_bucket='day';
 when '1m' then v_start=now()-interval '1 month'; v_bucket='day';
 when '6m' then v_start=now()-interval '6 months'; v_bucket='week';
 when '1y' then v_start=now()-interval '1 year'; v_bucket='month';
 else raise exception 'INVALID_WINDOW';
 end case;
 with base as(
  select date_trunc(v_bucket,transacted_at) bucket,transaction_type,coalesce(counterparty,'미분류') menu,total_amount
  from (SELECT * FROM tenant_template.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) operations_transactions where transacted_at>=v_start and status='CONFIRMED'
 ), totals as(
  select bucket,sum(case when transaction_type='SALE' then total_amount when transaction_type='REFUND' then -total_amount else 0 end) sales,
  sum(case when transaction_type='PURCHASE' then total_amount else 0 end) purchases from base group by bucket
 ), menus as(
  select bucket,menu,sum(case when transaction_type='SALE' then total_amount when transaction_type='REFUND' then -total_amount else 0 end) amount
  from base where transaction_type in('SALE','REFUND') group by bucket,menu
 ), topmenus as(select menu,sum(amount) amount from menus group by menu order by amount desc limit 8)
 select json_build_object(
  'window',p_window,'bucket',v_bucket,
  'totals',coalesce((select json_agg(t order by bucket) from totals t),'[]'::json),
  'menus',coalesce((select json_agg(m order by bucket,menu) from menus m join topmenus tm using(menu)),'[]'::json),
  'menu_names',coalesce((select json_agg(menu order by amount desc) from topmenus),'[]'::json)
 ) into v; return v;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_reconciliation_issues(p_from date, p_to date)
 RETURNS TABLE(id bigint, business_date date, issue_type text, left_source text, right_source text, amount_difference bigint, status text, detail jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
begin
 if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select x.id,x.business_date,x.issue_type,x.left_source,x.right_source,x.amount_difference,x.status,x.detail
 from (SELECT * FROM tenant_template.operations_reconciliation_issues WHERE store_id=public.current_store_id()) x where x.business_date between p_from and p_to order by x.business_date desc,x.id desc;
end $function$
;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA tenant_template FROM PUBLIC,anon,authenticated;
ALTER TABLE tenant_sample.inventory_movements ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_sample.stores(id); ALTER TABLE tenant_sample.inventory_movements ALTER COLUMN store_id SET DEFAULT public.current_store_id();
ALTER TABLE tenant_sample.operations_reconciliation_issues ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_sample.stores(id); ALTER TABLE tenant_sample.operations_reconciliation_issues ALTER COLUMN store_id SET DEFAULT public.current_store_id();
CREATE OR REPLACE FUNCTION tenant_sample.admin_inventory_movements(p_item_id bigint DEFAULT NULL::bigint, p_from date DEFAULT NULL::date, p_to date DEFAULT NULL::date)
 RETURNS TABLE(id bigint, item_id bigint, item_name text, business_date date, movement_type text, quantity numeric, unit_cost bigint, source_type text, source_key text, note text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
begin
 if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select m.id,m.item_id,i.name,m.business_date,m.movement_type,m.quantity,m.unit_cost,m.source_type,m.source_key,m.note
 from (SELECT * FROM tenant_sample.inventory_movements WHERE store_id=public.current_store_id()) m join tenant_sample.inventory_items i on i.id=m.item_id
 where (p_item_id is null or m.item_id=p_item_id) and (p_from is null or m.business_date>=p_from) and (p_to is null or m.business_date<=p_to)
 order by m.business_date desc,m.id desc limit 1000;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_inventory_overview()
 RETURNS TABLE(id bigint, sku text, name text, unit text, is_active boolean, on_hand numeric, reorder_level numeric, inventory_value numeric, low_stock boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
begin
 if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query
 select i.id,i.sku,i.name,i.unit,i.is_active,
   coalesce(sum(m.quantity),0)::numeric on_hand,i.reorder_level,
   coalesce(sum(m.quantity * coalesce(m.unit_cost,0)),0)::numeric inventory_value,
   (i.reorder_level is not null and coalesce(sum(m.quantity),0)<=i.reorder_level) low_stock
 from tenant_sample.inventory_items i left join (SELECT * FROM tenant_sample.inventory_movements WHERE store_id=public.current_store_id()) m on m.item_id=i.id
 group by i.id order by i.is_active desc,i.name;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_inventory_overview_v2()
 RETURNS TABLE(id bigint, sku text, name text, unit text, is_active boolean, on_hand numeric, reorder_level numeric, inventory_value numeric, low_stock boolean, category text, source_unit_system text, source_minimum_text text, source_current_text text, source_order_text text, source_note text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
begin
 if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select i.id,i.sku,i.name,i.unit,i.is_active,coalesce(sum(m.quantity),0)::numeric,i.reorder_level,
 coalesce(sum(m.quantity*coalesce(m.unit_cost,0)),0)::numeric,
 (i.reorder_level is not null and coalesce(sum(m.quantity),0)<=i.reorder_level),
 i.category,i.source_unit_system,i.source_minimum_text,i.source_current_text,i.source_order_text,i.source_note
 from tenant_sample.inventory_items i left join (SELECT * FROM tenant_sample.inventory_movements WHERE store_id=public.current_store_id()) m on m.item_id=i.id
 group by i.id order by i.is_active desc,i.name;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_inventory_overview_v3()
 RETURNS TABLE(id bigint, sku text, name text, unit text, is_active boolean, on_hand numeric, reorder_level numeric, inventory_value numeric, low_stock boolean, category text, source_unit_system text, source_minimum_text text, source_current_text text, source_order_text text, source_note text, stock_unit text, order_unit text, conversion_quantity numeric, unit_configured boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
begin
 if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query
 select i.id,i.sku,i.name,i.unit,i.is_active,coalesce(sum(m.quantity),0)::numeric,i.reorder_level,
   coalesce(sum(m.quantity*coalesce(m.unit_cost,0)),0)::numeric,
   (i.reorder_level is not null and coalesce(sum(m.quantity),0)<=i.reorder_level),
   i.category,i.source_unit_system,i.source_minimum_text,i.source_current_text,i.source_order_text,i.source_note,
   i.stock_unit,i.order_unit,i.conversion_quantity,
   (i.stock_unit is not null and i.order_unit is not null and i.conversion_quantity is not null)
 from tenant_sample.inventory_items i left join (SELECT * FROM tenant_sample.inventory_movements WHERE store_id=public.current_store_id()) m on m.item_id=i.id
 group by i.id order by i.is_active desc,i.name;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_operations_analytics(p_from date, p_to date)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
declare v json;
begin
 if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 select json_build_object(
 'by_channel',coalesce((select json_agg(x) from(select coalesce(channel,'기타') channel,sum(total_amount) amount,count(*) transactions from (SELECT * FROM tenant_sample.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) operations_transactions where business_date between p_from and p_to and transaction_type='SALE' and status='CONFIRMED' group by 1 order by 2 desc)x),'[]'::json),
 'daily',coalesce((select json_agg(x) from(select business_date,sum(case when transaction_type='SALE' then total_amount when transaction_type='REFUND' then -total_amount else 0 end) sales,sum(case when transaction_type='PURCHASE' then total_amount else 0 end) purchases from (SELECT * FROM tenant_sample.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) operations_transactions where business_date between p_from and p_to and status='CONFIRMED' group by business_date order by business_date)x),'[]'::json),
 'open_reconciliation',(select count(*) from (SELECT * FROM tenant_sample.operations_reconciliation_issues WHERE store_id=public.current_store_id()) operations_reconciliation_issues where business_date between p_from and p_to and status='OPEN'),
 'low_stock',(select count(*) from (select i.id from tenant_sample.inventory_items i left join (SELECT * FROM tenant_sample.inventory_movements WHERE store_id=public.current_store_id()) m on m.item_id=i.id where i.is_active and i.reorder_level is not null group by i.id having coalesce(sum(m.quantity),0)<=i.reorder_level)s)
 ) into v; return v;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_operations_channels(p_from date, p_to date)
 RETURNS TABLE(channel text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$ begin if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if; return query select distinct coalesce(x.channel,'기타') from (SELECT * FROM tenant_sample.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) x where x.business_date between p_from and p_to order by 1; end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_operations_import_stage(p_source text, p_file_name text, p_rows jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
declare bid bigint; r jsonb; n int:=0; sk text; bdate date;
begin
 if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 if coalesce(jsonb_typeof(p_rows),'')<>'array' then raise exception 'ROWS_MUST_BE_ARRAY'; end if;
 insert into operations_import_batches(source,source_store_key,idempotency_key,file_name,status,row_count,started_at)
 values(trim(p_source),'store-'||public.current_store_id(),md5(coalesce(p_file_name,'')||clock_timestamp()::text),p_file_name,'PROCESSING',jsonb_array_length(p_rows),now()) returning id into bid;
 for r in select * from jsonb_array_elements(p_rows) loop
   n:=n+1; sk:=coalesce(nullif(r->>'source_record_key',''),bid::text||'-'||n);
   begin bdate:=nullif(r->>'business_date','')::date; exception when others then bdate:=null; end;
   insert into operations_raw_records(batch_id,source,source_store_key,source_record_key,business_date,payload,payload_hash)
   values(bid,trim(p_source),'store-'||public.current_store_id(),sk,bdate,r,md5(r::text))
   on conflict(source,source_store_key,source_record_key) do update set payload=excluded.payload,payload_hash=excluded.payload_hash,business_date=excluded.business_date,ingested_at=now();
 end loop;
 update operations_import_batches set status='COMPLETED',completed_at=now() where id=bid;
 return jsonb_build_object('ok',true,'batch_id',bid,'row_count',n);
exception when others then
 if bid is not null then update operations_import_batches set status='FAILED',error_message=sqlerrm,completed_at=now() where id=bid; end if;
 raise;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_operations_imports()
 RETURNS TABLE(id bigint, source text, file_name text, status text, row_count integer, error_message text, created_at timestamp with time zone, completed_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
begin
 if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select b.id,b.source,b.file_name,b.status,b.row_count,b.error_message,b.created_at,b.completed_at
 from (SELECT * FROM tenant_sample.operations_import_batches WHERE source_store_key=ANY(public.current_store_keys())) b order by b.id desc limit 100;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_operations_inquiry(p_from date, p_to date, p_type text DEFAULT NULL::text, p_channel text DEFAULT NULL::text)
 RETURNS TABLE(id bigint, business_date date, transaction_type text, channel text, counterparty text, net_amount bigint, vat_amount bigint, total_amount bigint, status text, source text, is_demo boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
begin if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
return query select x.id,x.business_date,x.transaction_type,x.channel,x.counterparty,x.net_amount,x.vat_amount,x.total_amount,x.status,x.source,x.is_demo from (SELECT * FROM tenant_sample.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) x
where x.business_date between p_from and p_to and (p_type is null or x.transaction_type=p_type) and (p_channel is null or x.channel=p_channel) order by x.business_date desc,x.id desc limit 2000; end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_operations_summary(p_from date, p_to date)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
declare v_sales bigint; v_purchases bigint; v_refunds bigint; v_tx bigint; v_items bigint; v_imports bigint;
begin
 if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 if p_from is null or p_to is null or p_to < p_from then raise exception 'INVALID_RANGE'; end if;
 select coalesce(sum(case when transaction_type='SALE' and status='CONFIRMED' then total_amount else 0 end),0),
        coalesce(sum(case when transaction_type='PURCHASE' and status='CONFIRMED' then total_amount else 0 end),0),
        coalesce(sum(case when transaction_type='REFUND' and status='CONFIRMED' then total_amount else 0 end),0),
        count(*) into v_sales,v_purchases,v_refunds,v_tx
 from (SELECT * FROM tenant_sample.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) operations_transactions where business_date between p_from and p_to;
 select count(*) into v_items from tenant_sample.inventory_items where is_active;
 select count(*) into v_imports from (SELECT * FROM tenant_sample.operations_import_batches WHERE source_store_key=ANY(public.current_store_keys())) operations_import_batches where created_at::date between p_from and p_to;
 return json_build_object('sales',v_sales,'purchases',v_purchases,'refunds',v_refunds,'transaction_count',v_tx,'active_items',v_items,'import_count',v_imports);
end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_operations_transactions(p_from date, p_to date, p_type text DEFAULT NULL::text)
 RETURNS TABLE(id bigint, business_date date, transaction_type text, channel text, counterparty text, net_amount bigint, vat_amount bigint, total_amount bigint, status text, source text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
begin
 if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select t.id,t.business_date,t.transaction_type,t.channel,t.counterparty,t.net_amount,t.vat_amount,t.total_amount,t.status,t.source
 from (SELECT * FROM tenant_sample.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) t
 where t.business_date between p_from and p_to and (p_type is null or t.transaction_type=p_type)
 order by t.business_date desc,t.id desc limit 500;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_operations_trend(p_window text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
declare v_start timestamptz; v_bucket text; v json;
begin
 if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 case p_window
 when '1h' then v_start=now()-interval '1 hour'; v_bucket='minute';
 when '24h' then v_start=now()-interval '24 hours'; v_bucket='hour';
 when '7d' then v_start=now()-interval '7 days'; v_bucket='day';
 when '1m' then v_start=now()-interval '1 month'; v_bucket='day';
 when '6m' then v_start=now()-interval '6 months'; v_bucket='week';
 when '1y' then v_start=now()-interval '1 year'; v_bucket='month';
 else raise exception 'INVALID_WINDOW';
 end case;
 with base as(
  select date_trunc(v_bucket,transacted_at) bucket,transaction_type,coalesce(counterparty,'미분류') menu,total_amount
  from (SELECT * FROM tenant_sample.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) operations_transactions where transacted_at>=v_start and status='CONFIRMED'
 ), totals as(
  select bucket,sum(case when transaction_type='SALE' then total_amount when transaction_type='REFUND' then -total_amount else 0 end) sales,
  sum(case when transaction_type='PURCHASE' then total_amount else 0 end) purchases from base group by bucket
 ), menus as(
  select bucket,menu,sum(case when transaction_type='SALE' then total_amount when transaction_type='REFUND' then -total_amount else 0 end) amount
  from base where transaction_type in('SALE','REFUND') group by bucket,menu
 ), topmenus as(select menu,sum(amount) amount from menus group by menu order by amount desc limit 8)
 select json_build_object(
  'window',p_window,'bucket',v_bucket,
  'totals',coalesce((select json_agg(t order by bucket) from totals t),'[]'::json),
  'menus',coalesce((select json_agg(m order by bucket,menu) from menus m join topmenus tm using(menu)),'[]'::json),
  'menu_names',coalesce((select json_agg(menu order by amount desc) from topmenus),'[]'::json)
 ) into v; return v;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_reconciliation_issues(p_from date, p_to date)
 RETURNS TABLE(id bigint, business_date date, issue_type text, left_source text, right_source text, amount_difference bigint, status text, detail jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
begin
 if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select x.id,x.business_date,x.issue_type,x.left_source,x.right_source,x.amount_difference,x.status,x.detail
 from (SELECT * FROM tenant_sample.operations_reconciliation_issues WHERE store_id=public.current_store_id()) x where x.business_date between p_from and p_to order by x.business_date desc,x.id desc;
end $function$
;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA tenant_sample FROM PUBLIC,anon,authenticated;
ALTER TABLE tenant_qa.inventory_movements ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_qa.stores(id); ALTER TABLE tenant_qa.inventory_movements ALTER COLUMN store_id SET DEFAULT public.current_store_id();
ALTER TABLE tenant_qa.operations_reconciliation_issues ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_qa.stores(id); ALTER TABLE tenant_qa.operations_reconciliation_issues ALTER COLUMN store_id SET DEFAULT public.current_store_id();
CREATE OR REPLACE FUNCTION tenant_qa.admin_inventory_movements(p_item_id bigint DEFAULT NULL::bigint, p_from date DEFAULT NULL::date, p_to date DEFAULT NULL::date)
 RETURNS TABLE(id bigint, item_id bigint, item_name text, business_date date, movement_type text, quantity numeric, unit_cost bigint, source_type text, source_key text, note text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
begin
 if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select m.id,m.item_id,i.name,m.business_date,m.movement_type,m.quantity,m.unit_cost,m.source_type,m.source_key,m.note
 from (SELECT * FROM tenant_qa.inventory_movements WHERE store_id=public.current_store_id()) m join tenant_qa.inventory_items i on i.id=m.item_id
 where (p_item_id is null or m.item_id=p_item_id) and (p_from is null or m.business_date>=p_from) and (p_to is null or m.business_date<=p_to)
 order by m.business_date desc,m.id desc limit 1000;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_inventory_overview()
 RETURNS TABLE(id bigint, sku text, name text, unit text, is_active boolean, on_hand numeric, reorder_level numeric, inventory_value numeric, low_stock boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
begin
 if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query
 select i.id,i.sku,i.name,i.unit,i.is_active,
   coalesce(sum(m.quantity),0)::numeric on_hand,i.reorder_level,
   coalesce(sum(m.quantity * coalesce(m.unit_cost,0)),0)::numeric inventory_value,
   (i.reorder_level is not null and coalesce(sum(m.quantity),0)<=i.reorder_level) low_stock
 from tenant_qa.inventory_items i left join (SELECT * FROM tenant_qa.inventory_movements WHERE store_id=public.current_store_id()) m on m.item_id=i.id
 group by i.id order by i.is_active desc,i.name;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_inventory_overview_v2()
 RETURNS TABLE(id bigint, sku text, name text, unit text, is_active boolean, on_hand numeric, reorder_level numeric, inventory_value numeric, low_stock boolean, category text, source_unit_system text, source_minimum_text text, source_current_text text, source_order_text text, source_note text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
begin
 if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select i.id,i.sku,i.name,i.unit,i.is_active,coalesce(sum(m.quantity),0)::numeric,i.reorder_level,
 coalesce(sum(m.quantity*coalesce(m.unit_cost,0)),0)::numeric,
 (i.reorder_level is not null and coalesce(sum(m.quantity),0)<=i.reorder_level),
 i.category,i.source_unit_system,i.source_minimum_text,i.source_current_text,i.source_order_text,i.source_note
 from tenant_qa.inventory_items i left join (SELECT * FROM tenant_qa.inventory_movements WHERE store_id=public.current_store_id()) m on m.item_id=i.id
 group by i.id order by i.is_active desc,i.name;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_inventory_overview_v3()
 RETURNS TABLE(id bigint, sku text, name text, unit text, is_active boolean, on_hand numeric, reorder_level numeric, inventory_value numeric, low_stock boolean, category text, source_unit_system text, source_minimum_text text, source_current_text text, source_order_text text, source_note text, stock_unit text, order_unit text, conversion_quantity numeric, unit_configured boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
begin
 if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query
 select i.id,i.sku,i.name,i.unit,i.is_active,coalesce(sum(m.quantity),0)::numeric,i.reorder_level,
   coalesce(sum(m.quantity*coalesce(m.unit_cost,0)),0)::numeric,
   (i.reorder_level is not null and coalesce(sum(m.quantity),0)<=i.reorder_level),
   i.category,i.source_unit_system,i.source_minimum_text,i.source_current_text,i.source_order_text,i.source_note,
   i.stock_unit,i.order_unit,i.conversion_quantity,
   (i.stock_unit is not null and i.order_unit is not null and i.conversion_quantity is not null)
 from tenant_qa.inventory_items i left join (SELECT * FROM tenant_qa.inventory_movements WHERE store_id=public.current_store_id()) m on m.item_id=i.id
 group by i.id order by i.is_active desc,i.name;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_operations_analytics(p_from date, p_to date)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
declare v json;
begin
 if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 select json_build_object(
 'by_channel',coalesce((select json_agg(x) from(select coalesce(channel,'기타') channel,sum(total_amount) amount,count(*) transactions from (SELECT * FROM tenant_qa.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) operations_transactions where business_date between p_from and p_to and transaction_type='SALE' and status='CONFIRMED' group by 1 order by 2 desc)x),'[]'::json),
 'daily',coalesce((select json_agg(x) from(select business_date,sum(case when transaction_type='SALE' then total_amount when transaction_type='REFUND' then -total_amount else 0 end) sales,sum(case when transaction_type='PURCHASE' then total_amount else 0 end) purchases from (SELECT * FROM tenant_qa.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) operations_transactions where business_date between p_from and p_to and status='CONFIRMED' group by business_date order by business_date)x),'[]'::json),
 'open_reconciliation',(select count(*) from (SELECT * FROM tenant_qa.operations_reconciliation_issues WHERE store_id=public.current_store_id()) operations_reconciliation_issues where business_date between p_from and p_to and status='OPEN'),
 'low_stock',(select count(*) from (select i.id from tenant_qa.inventory_items i left join (SELECT * FROM tenant_qa.inventory_movements WHERE store_id=public.current_store_id()) m on m.item_id=i.id where i.is_active and i.reorder_level is not null group by i.id having coalesce(sum(m.quantity),0)<=i.reorder_level)s)
 ) into v; return v;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_operations_channels(p_from date, p_to date)
 RETURNS TABLE(channel text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$ begin if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if; return query select distinct coalesce(x.channel,'기타') from (SELECT * FROM tenant_qa.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) x where x.business_date between p_from and p_to order by 1; end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_operations_import_stage(p_source text, p_file_name text, p_rows jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
declare bid bigint; r jsonb; n int:=0; sk text; bdate date;
begin
 if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 if coalesce(jsonb_typeof(p_rows),'')<>'array' then raise exception 'ROWS_MUST_BE_ARRAY'; end if;
 insert into operations_import_batches(source,source_store_key,idempotency_key,file_name,status,row_count,started_at)
 values(trim(p_source),'store-'||public.current_store_id(),md5(coalesce(p_file_name,'')||clock_timestamp()::text),p_file_name,'PROCESSING',jsonb_array_length(p_rows),now()) returning id into bid;
 for r in select * from jsonb_array_elements(p_rows) loop
   n:=n+1; sk:=coalesce(nullif(r->>'source_record_key',''),bid::text||'-'||n);
   begin bdate:=nullif(r->>'business_date','')::date; exception when others then bdate:=null; end;
   insert into operations_raw_records(batch_id,source,source_store_key,source_record_key,business_date,payload,payload_hash)
   values(bid,trim(p_source),'store-'||public.current_store_id(),sk,bdate,r,md5(r::text))
   on conflict(source,source_store_key,source_record_key) do update set payload=excluded.payload,payload_hash=excluded.payload_hash,business_date=excluded.business_date,ingested_at=now();
 end loop;
 update operations_import_batches set status='COMPLETED',completed_at=now() where id=bid;
 return jsonb_build_object('ok',true,'batch_id',bid,'row_count',n);
exception when others then
 if bid is not null then update operations_import_batches set status='FAILED',error_message=sqlerrm,completed_at=now() where id=bid; end if;
 raise;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_operations_imports()
 RETURNS TABLE(id bigint, source text, file_name text, status text, row_count integer, error_message text, created_at timestamp with time zone, completed_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
begin
 if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select b.id,b.source,b.file_name,b.status,b.row_count,b.error_message,b.created_at,b.completed_at
 from (SELECT * FROM tenant_qa.operations_import_batches WHERE source_store_key=ANY(public.current_store_keys())) b order by b.id desc limit 100;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_operations_inquiry(p_from date, p_to date, p_type text DEFAULT NULL::text, p_channel text DEFAULT NULL::text)
 RETURNS TABLE(id bigint, business_date date, transaction_type text, channel text, counterparty text, net_amount bigint, vat_amount bigint, total_amount bigint, status text, source text, is_demo boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
begin if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
return query select x.id,x.business_date,x.transaction_type,x.channel,x.counterparty,x.net_amount,x.vat_amount,x.total_amount,x.status,x.source,x.is_demo from (SELECT * FROM tenant_qa.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) x
where x.business_date between p_from and p_to and (p_type is null or x.transaction_type=p_type) and (p_channel is null or x.channel=p_channel) order by x.business_date desc,x.id desc limit 2000; end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_operations_summary(p_from date, p_to date)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
declare v_sales bigint; v_purchases bigint; v_refunds bigint; v_tx bigint; v_items bigint; v_imports bigint;
begin
 if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 if p_from is null or p_to is null or p_to < p_from then raise exception 'INVALID_RANGE'; end if;
 select coalesce(sum(case when transaction_type='SALE' and status='CONFIRMED' then total_amount else 0 end),0),
        coalesce(sum(case when transaction_type='PURCHASE' and status='CONFIRMED' then total_amount else 0 end),0),
        coalesce(sum(case when transaction_type='REFUND' and status='CONFIRMED' then total_amount else 0 end),0),
        count(*) into v_sales,v_purchases,v_refunds,v_tx
 from (SELECT * FROM tenant_qa.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) operations_transactions where business_date between p_from and p_to;
 select count(*) into v_items from tenant_qa.inventory_items where is_active;
 select count(*) into v_imports from (SELECT * FROM tenant_qa.operations_import_batches WHERE source_store_key=ANY(public.current_store_keys())) operations_import_batches where created_at::date between p_from and p_to;
 return json_build_object('sales',v_sales,'purchases',v_purchases,'refunds',v_refunds,'transaction_count',v_tx,'active_items',v_items,'import_count',v_imports);
end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_operations_transactions(p_from date, p_to date, p_type text DEFAULT NULL::text)
 RETURNS TABLE(id bigint, business_date date, transaction_type text, channel text, counterparty text, net_amount bigint, vat_amount bigint, total_amount bigint, status text, source text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
begin
 if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select t.id,t.business_date,t.transaction_type,t.channel,t.counterparty,t.net_amount,t.vat_amount,t.total_amount,t.status,t.source
 from (SELECT * FROM tenant_qa.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) t
 where t.business_date between p_from and p_to and (p_type is null or t.transaction_type=p_type)
 order by t.business_date desc,t.id desc limit 500;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_operations_trend(p_window text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
declare v_start timestamptz; v_bucket text; v json;
begin
 if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 case p_window
 when '1h' then v_start=now()-interval '1 hour'; v_bucket='minute';
 when '24h' then v_start=now()-interval '24 hours'; v_bucket='hour';
 when '7d' then v_start=now()-interval '7 days'; v_bucket='day';
 when '1m' then v_start=now()-interval '1 month'; v_bucket='day';
 when '6m' then v_start=now()-interval '6 months'; v_bucket='week';
 when '1y' then v_start=now()-interval '1 year'; v_bucket='month';
 else raise exception 'INVALID_WINDOW';
 end case;
 with base as(
  select date_trunc(v_bucket,transacted_at) bucket,transaction_type,coalesce(counterparty,'미분류') menu,total_amount
  from (SELECT * FROM tenant_qa.operations_transactions WHERE source_store_key=ANY(public.current_store_keys())) operations_transactions where transacted_at>=v_start and status='CONFIRMED'
 ), totals as(
  select bucket,sum(case when transaction_type='SALE' then total_amount when transaction_type='REFUND' then -total_amount else 0 end) sales,
  sum(case when transaction_type='PURCHASE' then total_amount else 0 end) purchases from base group by bucket
 ), menus as(
  select bucket,menu,sum(case when transaction_type='SALE' then total_amount when transaction_type='REFUND' then -total_amount else 0 end) amount
  from base where transaction_type in('SALE','REFUND') group by bucket,menu
 ), topmenus as(select menu,sum(amount) amount from menus group by menu order by amount desc limit 8)
 select json_build_object(
  'window',p_window,'bucket',v_bucket,
  'totals',coalesce((select json_agg(t order by bucket) from totals t),'[]'::json),
  'menus',coalesce((select json_agg(m order by bucket,menu) from menus m join topmenus tm using(menu)),'[]'::json),
  'menu_names',coalesce((select json_agg(menu order by amount desc) from topmenus),'[]'::json)
 ) into v; return v;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_reconciliation_issues(p_from date, p_to date)
 RETURNS TABLE(id bigint, business_date date, issue_type text, left_source text, right_source text, amount_difference bigint, status text, detail jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
begin
 if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 return query select x.id,x.business_date,x.issue_type,x.left_source,x.right_source,x.amount_difference,x.status,x.detail
 from (SELECT * FROM tenant_qa.operations_reconciliation_issues WHERE store_id=public.current_store_id()) x where x.business_date between p_from and p_to order by x.business_date desc,x.id desc;
end $function$
;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA tenant_qa FROM PUBLIC,anon,authenticated;