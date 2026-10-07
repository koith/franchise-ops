BEGIN;
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at) VALUES ('00000000-0000-4000-8000-000000000004','authenticated','authenticated','port-qa@example.invalid',now(),now());
INSERT INTO public.tenant_memberships(tenant_id,user_id,role) SELECT id,'00000000-0000-4000-8000-000000000004','HQ' FROM public.tenants WHERE slug='sample';
INSERT INTO tenant_sample.admin_users(user_id,email,admin_role) VALUES('00000000-0000-4000-8000-000000000004','port-qa@example.invalid','HQ');
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000004',true);
SELECT set_config('request.jwt.claims','{"sub":"00000000-0000-4000-8000-000000000004","role":"authenticated"}',true);
SELECT set_config('request.headers','{"x-tenant-id":"qa-isolation"}',true);
SELECT set_config('request.headers','{"x-tenant-id":"sample"}',true);
DO $$
DECLARE a bigint; b bigint; result jsonb; first_total numeric; second_total numeric; item bigint;
BEGIN
 SELECT min(id),max(id) INTO a,b FROM tenant_sample.stores;
 INSERT INTO tenant_sample.operations_transactions(source,source_store_key,source_record_key,transaction_type,transacted_at,business_date,channel,counterparty,total_amount,status)
 VALUES('QA','store-'||a,'qa-a-'||gen_random_uuid(),'SALE',now(),current_date,'QA','검증 상품',17000,'CONFIRMED'),
 ('QA','store-'||b,'qa-b-'||gen_random_uuid(),'SALE',now(),current_date,'QA','검증 상품',23000,'CONFIRMED');
 result:=public.hq_store_dashboard();
 SELECT (x->>'sales_total')::numeric INTO first_total FROM jsonb_array_elements(result) x WHERE (x->>'store_id')::bigint=a;
 SELECT (x->>'sales_total')::numeric INTO second_total FROM jsonb_array_elements(result) x WHERE (x->>'store_id')::bigint=b;
 IF first_total<>17000 OR second_total<>23000 THEN RAISE EXCEPTION 'Store sales mixed: %, %',first_total,second_total; END IF;
 PERFORM set_config('request.headers',jsonb_build_object('x-tenant-id','sample','x-store-id',a::text)::text,true);
 result:=public.admin_operations_summary(current_date,current_date);
 IF (result->>'sales')::numeric<>17000 THEN RAISE EXCEPTION 'Store A report leaked'; END IF;
 INSERT INTO tenant_sample.inventory_items(sku,name,unit) VALUES('QA-'||gen_random_uuid(),'격리 검증 품목','ea') RETURNING id INTO item;
 INSERT INTO tenant_sample.inventory_movements(item_id,business_date,movement_type,quantity,source_type,source_key,store_id) VALUES(item,current_date,'RECEIPT',2,'QA','a',a),(item,current_date,'RECEIPT',7,'QA','b',b);
 result:=public.admin_inventory_overview_v3();
 IF (SELECT (x->>'on_hand')::numeric FROM jsonb_array_elements(result)x WHERE (x->>'id')::bigint=item)<>2 THEN RAISE EXCEPTION 'Store A stock leaked'; END IF;
 PERFORM set_config('request.headers',jsonb_build_object('x-tenant-id','sample','x-store-id',b::text)::text,true);
 result:=public.admin_operations_summary(current_date,current_date);
 IF (result->>'sales')::numeric<>23000 THEN RAISE EXCEPTION 'Store B report leaked'; END IF;
 result:=public.admin_inventory_overview_v3();
 IF (SELECT (x->>'on_hand')::numeric FROM jsonb_array_elements(result)x WHERE (x->>'id')::bigint=item)<>7 THEN RAISE EXCEPTION 'Store B stock leaked'; END IF;
END $$;
SELECT 'HQ totals, store sales and stock isolation PASS' AS result;
ROLLBACK;
