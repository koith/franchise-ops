BEGIN;
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at) VALUES ('00000000-0000-4000-8000-000000000004','authenticated','authenticated','port-qa@example.invalid',now(),now());
INSERT INTO public.tenant_memberships(tenant_id,user_id,role) SELECT id,'00000000-0000-4000-8000-000000000004','HQ' FROM public.tenants WHERE slug='sample';
INSERT INTO tenant_sample.admin_users(user_id,email,admin_role) VALUES('00000000-0000-4000-8000-000000000004','port-qa@example.invalid','HQ');
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000004',true);
SELECT set_config('request.jwt.claims','{"sub":"00000000-0000-4000-8000-000000000004","role":"authenticated"}',true);
SELECT set_config('request.headers','{"x-tenant-id":"qa-isolation"}',true);
DO $$
DECLARE a bigint; own_emp bigint; other_emp bigint; result jsonb;
BEGIN
 SELECT min(id) INTO a FROM tenant_sample.stores;
 UPDATE public.tenant_memberships SET role='STORE_MANAGER',store_id=a WHERE user_id='00000000-0000-4000-8000-000000000004';
 UPDATE tenant_sample.admin_users SET admin_role='STORE_MANAGER',store_id=a WHERE user_id='00000000-0000-4000-8000-000000000004';
 PERFORM set_config('request.headers',jsonb_build_object('x-tenant-id','sample','x-store-id',a::text)::text,true);
 SELECT id INTO own_emp FROM tenant_sample.employees WHERE store_id=a LIMIT 1;
 SELECT id INTO other_emp FROM tenant_sample.employees WHERE store_id<>a LIMIT 1;
 result:=public.admin_list_employees();
 IF EXISTS(SELECT 1 FROM jsonb_array_elements(result)x WHERE (x->>'store_id')::bigint<>a) THEN RAISE EXCEPTION 'MANAGER_LIST_LEAK'; END IF;
 PERFORM public.admin_update_employee(own_emp,'{"memo":"QA rollback"}'::jsonb);
 BEGIN
  PERFORM public.admin_update_employee(other_emp,'{"memo":"DENIED"}'::jsonb);
  RAISE EXCEPTION 'MANAGER_CROSS_STORE_WRITE_ALLOWED';
 EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN
  PERFORM public.admin_list_auth_users(); RAISE EXCEPTION 'MANAGER_AUTH_DIRECTORY_ALLOWED';
 EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
SELECT 'manager own-store read/write and cross-store denial PASS' AS result;
ROLLBACK;
