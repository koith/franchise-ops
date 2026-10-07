BEGIN;
SELECT set_config('request.headers','{"x-tenant-id":"qa-isolation"}',true);
DO $$
DECLARE emp bigint; st bigint; a jsonb; b jsonb; n integer;
BEGIN
 SELECT id,store_id INTO emp,st FROM tenant_qa.employees WHERE name='격리 검증 직원' LIMIT 1;
 PERFORM set_config('request.headers',jsonb_build_object('x-tenant-id','qa-isolation','x-store-id',st::text)::text,true);
 UPDATE tenant_qa.store_settings SET open_minute=0,close_minute=1440 WHERE id=st;
 a:=public.punch(emp,'8642','CI-ROLLBACK',NULL);
 b:=public.punch(emp,'8642','CI-ROLLBACK',NULL);
 IF a->>'ok'<>'true' OR b->>'ok'<>'true' OR a->>'type'=b->>'type' THEN RAISE EXCEPTION 'Punch transition failed: %, %',a,b; END IF;
 SELECT count(*) INTO n FROM tenant_qa.attendance_events WHERE employee_id=emp AND device_id='CI-ROLLBACK';
 IF n<>2 THEN RAISE EXCEPTION 'Punch events not persisted'; END IF;
END $$;
SELECT 'real PIN punch transition and persisted events PASS' AS result;
ROLLBACK;
