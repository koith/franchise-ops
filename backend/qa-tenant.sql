BEGIN;
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at) VALUES ('00000000-0000-4000-8000-000000000004','authenticated','authenticated','port-qa@example.invalid',now(),now());
INSERT INTO public.tenant_memberships(tenant_id,user_id,role) SELECT id,'00000000-0000-4000-8000-000000000004','HQ' FROM public.tenants WHERE slug='qa-isolation';
INSERT INTO tenant_qa.admin_users(user_id,email,admin_role) VALUES('00000000-0000-4000-8000-000000000004','port-qa@example.invalid','HQ');
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000004',true);
SELECT set_config('request.jwt.claims','{"sub":"00000000-0000-4000-8000-000000000004","role":"authenticated"}',true);
SELECT set_config('request.headers','{"x-tenant-id":"qa-isolation"}',true);
DO $$
DECLARE st bigint; emp bigint; response jsonb;
BEGIN
 SELECT min(id) INTO st FROM tenant_qa.stores;
 PERFORM set_config('request.headers',jsonb_build_object('x-tenant-id','qa-isolation','x-store-id',st::text)::text,true);
 response:=public.admin_create_employee_for_store('QA 신규 직원','1234',st);
 IF jsonb_typeof(response)<>'number' THEN RAISE EXCEPTION 'create failed %',response; END IF;
 SELECT id INTO emp FROM tenant_qa.employees WHERE name='QA 신규 직원';
 IF emp IS NULL THEN RAISE EXCEPTION 'No persisted employee'; END IF;
 response:=public.admin_schedule_set(emp,current_date,'WORK','09:00','18:00','QA');
 IF response->>'ok' IS DISTINCT FROM 'true' THEN RAISE EXCEPTION 'schedule failed %',response; END IF;
 response:=public.admin_schedule_list(current_date,current_date+1);
 IF jsonb_array_length(response)=0 THEN RAISE EXCEPTION 'Schedule not persisted'; END IF;
 PERFORM public.admin_events_with_corrections(current_date::timestamp,(current_date+1)::timestamp);
 PERFORM public.admin_inventory_overview_v3();
 PERFORM public.admin_recipe_list_v2();
 PERFORM public.admin_store_payroll_contracts_v2(st,current_date);
 PERFORM set_config('request.headers','{"x-tenant-id":"sample"}',true);
 BEGIN
  PERFORM public.admin_list_employees();
  RAISE EXCEPTION 'CROSS_TENANT_ALLOWED';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
 PERFORM set_config('request.headers','{}',true);
 BEGIN
  PERFORM public.list_stores();
  RAISE EXCEPTION 'MISSING_TENANT_ALLOWED';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
END $$;
SELECT 'tenant create/schedule/attendance/inventory/recipe/payroll/isolation PASS' AS result;
ROLLBACK;
