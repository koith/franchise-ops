BEGIN;
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at) VALUES ('00000000-0000-4000-8000-000000000004','authenticated','authenticated','port-qa@example.invalid',now(),now());
INSERT INTO public.tenant_memberships(tenant_id,user_id,role) SELECT id,'00000000-0000-4000-8000-000000000004','HQ' FROM public.tenants WHERE slug='sample';
INSERT INTO tenant_sample.admin_users(user_id,email,admin_role) VALUES('00000000-0000-4000-8000-000000000004','port-qa@example.invalid','HQ');
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000004',true);
SELECT set_config('request.jwt.claims','{"sub":"00000000-0000-4000-8000-000000000004","role":"authenticated"}',true);
SELECT set_config('request.headers','{"x-tenant-id":"qa-isolation"}',true);
DO $$
DECLARE a bigint; b bigint; result jsonb;
BEGIN
 SELECT min(id),max(id) INTO a,b FROM tenant_sample.stores;
 IF a=b THEN RAISE EXCEPTION 'QA requires two stores'; END IF;
 PERFORM set_config('request.headers',jsonb_build_object('x-tenant-id','sample','x-store-id',a::text)::text,true);
 PERFORM public.admin_close_payroll('2020-01','[]'::json,'qa-store-a');
 result:=public.admin_snapshot('2020-01');
 IF result->>'status'<>'CLOSED' THEN RAISE EXCEPTION 'A did not close'; END IF;
 PERFORM set_config('request.headers',jsonb_build_object('x-tenant-id','sample','x-store-id',b::text)::text,true);
 result:=public.admin_snapshot('2020-01');
 IF result->>'status'<>'OPEN' THEN RAISE EXCEPTION 'A close leaked to B'; END IF;
 PERFORM public.admin_close_payroll('2020-01','[]'::json,'qa-store-b');
 PERFORM public.admin_reopen_payroll('2020-01');
 PERFORM set_config('request.headers',jsonb_build_object('x-tenant-id','sample','x-store-id',a::text)::text,true);
 result:=public.admin_snapshot('2020-01');
 IF result->>'status'<>'CLOSED' THEN RAISE EXCEPTION 'B reopen leaked to A'; END IF;
END $$;
SELECT 'two-store payroll close/reopen isolation PASS' AS result;
ROLLBACK;
