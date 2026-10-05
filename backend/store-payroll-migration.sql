CREATE FUNCTION public.current_store_id() RETURNS bigint LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE st bigint; s name; valid boolean;
BEGIN
 s:=public.current_tenant_schema();
 st:=nullif(nullif(current_setting('request.headers',true),'')::jsonb->>'x-store-id','')::bigint;
 IF st IS NULL THEN RAISE EXCEPTION 'STORE_REQUIRED' USING ERRCODE='42501'; END IF;
 EXECUTE format('SELECT EXISTS(SELECT 1 FROM %I.stores WHERE id=$1 AND is_active)',s) INTO valid USING st;
 IF NOT valid THEN RAISE EXCEPTION 'STORE_NOT_FOUND' USING ERRCODE='42501'; END IF;
 IF auth.uid() IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.tenants t JOIN public.tenant_memberships m ON m.tenant_id=t.id WHERE t.schema_name=s AND m.user_id=auth.uid() AND (m.role='HQ' OR m.store_id=st)) THEN RAISE EXCEPTION 'STORE_ACCESS_DENIED' USING ERRCODE='42501'; END IF;
 RETURN st;
END $$;
REVOKE ALL ON FUNCTION public.current_store_id() FROM PUBLIC,anon,authenticated;

ALTER TABLE tenant_template.payroll_period ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_template.stores(id); ALTER TABLE tenant_template.payroll_period ALTER COLUMN store_id SET DEFAULT public.current_store_id();
ALTER TABLE tenant_template.payroll_period_employee ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_template.stores(id); ALTER TABLE tenant_template.payroll_period_employee ALTER COLUMN store_id SET DEFAULT public.current_store_id();
ALTER TABLE tenant_template.payroll_snapshot ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_template.stores(id); ALTER TABLE tenant_template.payroll_snapshot ALTER COLUMN store_id SET DEFAULT public.current_store_id();
ALTER TABLE tenant_template.payroll_period DROP CONSTRAINT payroll_period_pkey, ADD PRIMARY KEY (ym,store_id);
CREATE OR REPLACE FUNCTION tenant_template.admin_close_payroll(p_ym text, p_rows json, p_fingerprint text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
declare v_actor text; r json; n int:=0; v_month date;
begin
 if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 if p_ym !~ '^[0-9]{4}-[0-9]{2}$' then raise exception 'BAD_YM'; end if;
 v_month:=(p_ym||'-01')::date;
 if v_month>=date_trunc('month',now() at time zone 'Asia/Seoul')::date then raise exception 'CURRENT_OR_FUTURE_MONTH_CANNOT_CLOSE'; end if;
 if exists(select 1 from tenant_template.payroll_period where ym=p_ym and store_id=public.current_store_id() and status='CLOSED') then raise exception 'PAYROLL_ALREADY_CLOSED'; end if;
 v_actor:=coalesce(auth.jwt()->>'email','admin');
 delete from tenant_template.payroll_snapshot where ym=p_ym and store_id=public.current_store_id();
 for r in select * from json_array_elements(p_rows) loop
   insert into tenant_template.payroll_snapshot(ym,employee_id,employee_name,hours,wage,weeks,base_pay,juhyu_pay,adjust,gross_pay,tax_rate,net_pay,memo,source_fingerprint,closed_by)
   values(p_ym,(r->>'employee_id')::bigint,r->>'employee_name',nullif(r->>'hours','')::numeric,nullif(r->>'wage','')::int,nullif(r->>'weeks','')::int,
   nullif(r->>'base_pay','')::int,nullif(r->>'juhyu_pay','')::int,coalesce(nullif(r->>'adjust','')::int,0),nullif(r->>'gross_pay','')::int,
   nullif(r->>'tax_rate','')::numeric,nullif(r->>'net_pay','')::int,r->>'memo',p_fingerprint,v_actor);
   n:=n+1;
 end loop;
 insert into tenant_template.payroll_period(ym,status,updated_by,updated_at) values(p_ym,'CLOSED',v_actor,now())
 on conflict(ym,store_id) do update set status='CLOSED',updated_by=v_actor,updated_at=now();
 return json_build_object('ok',true,'count',n);
end $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_payroll_period(p_ym text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
begin
  if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  return (select json_build_object(
    'period', coalesce((select row_to_json(p) from payroll_period p where p.ym=p_ym and p.store_id=public.current_store_id()),
                       json_build_object('ym',p_ym,'status','OPEN','weeks',null)),
    'overrides', coalesce((select json_agg(row_to_json(o)) from payroll_period_employee o where o.ym=p_ym and o.store_id=public.current_store_id()),'[]'::json)));
end; $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_reopen_payroll(p_ym text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
declare v_actor text;
begin
  if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  v_actor := coalesce(auth.jwt()->>'email','admin');
  update payroll_period set status='OPEN', updated_by=v_actor, updated_at=now() where ym=p_ym and store_id=public.current_store_id();
  return json_build_object('ok',true);
end; $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_set_period_employee(p_ym text, p_employee_id bigint, p_fields json)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
begin
  if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  insert into payroll_period_employee(ym, employee_id,
      wage_override, juhyu_hours_override, juhyu_weeks_override, tax_rate_override, adjust_amount, memo, updated_by, updated_at)
    values (p_ym, p_employee_id,
      nullif(p_fields->>'wage_override','')::int,
      nullif(p_fields->>'juhyu_hours_override','')::numeric,
      nullif(p_fields->>'juhyu_weeks_override','')::int,
      nullif(p_fields->>'tax_rate_override','')::numeric,
      coalesce(nullif(p_fields->>'adjust_amount','')::int,0),
      nullif(p_fields->>'memo',''),
      coalesce(auth.jwt()->>'email','admin'), now())
  on conflict (ym, employee_id) do update set
      wage_override=excluded.wage_override,
      juhyu_hours_override=excluded.juhyu_hours_override,
      juhyu_weeks_override=excluded.juhyu_weeks_override,
      tax_rate_override=excluded.tax_rate_override,
      adjust_amount=excluded.adjust_amount,
      memo=excluded.memo, updated_by=excluded.updated_by, updated_at=now();
end; $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_set_period_weeks(p_ym text, p_weeks integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
begin
  if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  insert into payroll_period(ym, weeks, updated_by, updated_at)
    values (p_ym, p_weeks, coalesce(auth.jwt()->>'email','admin'), now())
  on conflict (ym,store_id) do update set weeks=excluded.weeks, updated_by=excluded.updated_by, updated_at=now();
end; $function$
;
CREATE OR REPLACE FUNCTION tenant_template.admin_snapshot(p_ym text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
begin
  if not tenant_template.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  return (select json_build_object(
    'status', coalesce((select status from payroll_period where ym=p_ym and store_id=public.current_store_id()),'OPEN'),
    'fingerprint', (select source_fingerprint from payroll_snapshot where ym=p_ym and store_id=public.current_store_id() limit 1),
    'rows', coalesce((select json_agg(row_to_json(s)) from (
      select employee_id,employee_name,hours,wage,weeks,base_pay,juhyu_pay,adjust,gross_pay,tax_rate,net_pay,memo,closed_by,closed_at
      from payroll_snapshot where ym=p_ym and store_id=public.current_store_id() order by employee_name) s),'[]'::json)));
end; $function$
;
CREATE FUNCTION tenant_template.validate_payroll_employee_store() RETURNS trigger LANGUAGE plpgsql SET search_path=tenant_template,pg_temp AS $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM tenant_template.employees WHERE id=NEW.employee_id AND store_id=NEW.store_id) THEN RAISE EXCEPTION 'EMPLOYEE_STORE_MISMATCH'; END IF;
 RETURN NEW; END $$;
 CREATE TRIGGER payroll_employee_store BEFORE INSERT OR UPDATE ON tenant_template.payroll_period_employee FOR EACH ROW EXECUTE FUNCTION tenant_template.validate_payroll_employee_store();
 CREATE TRIGGER payroll_snapshot_store BEFORE INSERT OR UPDATE ON tenant_template.payroll_snapshot FOR EACH ROW EXECUTE FUNCTION tenant_template.validate_payroll_employee_store();
 REVOKE ALL ON ALL FUNCTIONS IN SCHEMA tenant_template FROM PUBLIC,anon,authenticated;
ALTER TABLE tenant_sample.payroll_period ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_sample.stores(id); ALTER TABLE tenant_sample.payroll_period ALTER COLUMN store_id SET DEFAULT public.current_store_id();
ALTER TABLE tenant_sample.payroll_period_employee ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_sample.stores(id); ALTER TABLE tenant_sample.payroll_period_employee ALTER COLUMN store_id SET DEFAULT public.current_store_id();
ALTER TABLE tenant_sample.payroll_snapshot ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_sample.stores(id); ALTER TABLE tenant_sample.payroll_snapshot ALTER COLUMN store_id SET DEFAULT public.current_store_id();
ALTER TABLE tenant_sample.payroll_period DROP CONSTRAINT payroll_period_pkey, ADD PRIMARY KEY (ym,store_id);
CREATE OR REPLACE FUNCTION tenant_sample.admin_close_payroll(p_ym text, p_rows json, p_fingerprint text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
declare v_actor text; r json; n int:=0; v_month date;
begin
 if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 if p_ym !~ '^[0-9]{4}-[0-9]{2}$' then raise exception 'BAD_YM'; end if;
 v_month:=(p_ym||'-01')::date;
 if v_month>=date_trunc('month',now() at time zone 'Asia/Seoul')::date then raise exception 'CURRENT_OR_FUTURE_MONTH_CANNOT_CLOSE'; end if;
 if exists(select 1 from tenant_sample.payroll_period where ym=p_ym and store_id=public.current_store_id() and status='CLOSED') then raise exception 'PAYROLL_ALREADY_CLOSED'; end if;
 v_actor:=coalesce(auth.jwt()->>'email','admin');
 delete from tenant_sample.payroll_snapshot where ym=p_ym and store_id=public.current_store_id();
 for r in select * from json_array_elements(p_rows) loop
   insert into tenant_sample.payroll_snapshot(ym,employee_id,employee_name,hours,wage,weeks,base_pay,juhyu_pay,adjust,gross_pay,tax_rate,net_pay,memo,source_fingerprint,closed_by)
   values(p_ym,(r->>'employee_id')::bigint,r->>'employee_name',nullif(r->>'hours','')::numeric,nullif(r->>'wage','')::int,nullif(r->>'weeks','')::int,
   nullif(r->>'base_pay','')::int,nullif(r->>'juhyu_pay','')::int,coalesce(nullif(r->>'adjust','')::int,0),nullif(r->>'gross_pay','')::int,
   nullif(r->>'tax_rate','')::numeric,nullif(r->>'net_pay','')::int,r->>'memo',p_fingerprint,v_actor);
   n:=n+1;
 end loop;
 insert into tenant_sample.payroll_period(ym,status,updated_by,updated_at) values(p_ym,'CLOSED',v_actor,now())
 on conflict(ym,store_id) do update set status='CLOSED',updated_by=v_actor,updated_at=now();
 return json_build_object('ok',true,'count',n);
end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_payroll_period(p_ym text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
begin
  if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  return (select json_build_object(
    'period', coalesce((select row_to_json(p) from payroll_period p where p.ym=p_ym and p.store_id=public.current_store_id()),
                       json_build_object('ym',p_ym,'status','OPEN','weeks',null)),
    'overrides', coalesce((select json_agg(row_to_json(o)) from payroll_period_employee o where o.ym=p_ym and o.store_id=public.current_store_id()),'[]'::json)));
end; $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_reopen_payroll(p_ym text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
declare v_actor text;
begin
  if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  v_actor := coalesce(auth.jwt()->>'email','admin');
  update payroll_period set status='OPEN', updated_by=v_actor, updated_at=now() where ym=p_ym and store_id=public.current_store_id();
  return json_build_object('ok',true);
end; $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_set_period_employee(p_ym text, p_employee_id bigint, p_fields json)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
begin
  if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  insert into payroll_period_employee(ym, employee_id,
      wage_override, juhyu_hours_override, juhyu_weeks_override, tax_rate_override, adjust_amount, memo, updated_by, updated_at)
    values (p_ym, p_employee_id,
      nullif(p_fields->>'wage_override','')::int,
      nullif(p_fields->>'juhyu_hours_override','')::numeric,
      nullif(p_fields->>'juhyu_weeks_override','')::int,
      nullif(p_fields->>'tax_rate_override','')::numeric,
      coalesce(nullif(p_fields->>'adjust_amount','')::int,0),
      nullif(p_fields->>'memo',''),
      coalesce(auth.jwt()->>'email','admin'), now())
  on conflict (ym, employee_id) do update set
      wage_override=excluded.wage_override,
      juhyu_hours_override=excluded.juhyu_hours_override,
      juhyu_weeks_override=excluded.juhyu_weeks_override,
      tax_rate_override=excluded.tax_rate_override,
      adjust_amount=excluded.adjust_amount,
      memo=excluded.memo, updated_by=excluded.updated_by, updated_at=now();
end; $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_set_period_weeks(p_ym text, p_weeks integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
begin
  if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  insert into payroll_period(ym, weeks, updated_by, updated_at)
    values (p_ym, p_weeks, coalesce(auth.jwt()->>'email','admin'), now())
  on conflict (ym,store_id) do update set weeks=excluded.weeks, updated_by=excluded.updated_by, updated_at=now();
end; $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_snapshot(p_ym text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
begin
  if not tenant_sample.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  return (select json_build_object(
    'status', coalesce((select status from payroll_period where ym=p_ym and store_id=public.current_store_id()),'OPEN'),
    'fingerprint', (select source_fingerprint from payroll_snapshot where ym=p_ym and store_id=public.current_store_id() limit 1),
    'rows', coalesce((select json_agg(row_to_json(s)) from (
      select employee_id,employee_name,hours,wage,weeks,base_pay,juhyu_pay,adjust,gross_pay,tax_rate,net_pay,memo,closed_by,closed_at
      from payroll_snapshot where ym=p_ym and store_id=public.current_store_id() order by employee_name) s),'[]'::json)));
end; $function$
;
CREATE FUNCTION tenant_sample.validate_payroll_employee_store() RETURNS trigger LANGUAGE plpgsql SET search_path=tenant_sample,pg_temp AS $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM tenant_sample.employees WHERE id=NEW.employee_id AND store_id=NEW.store_id) THEN RAISE EXCEPTION 'EMPLOYEE_STORE_MISMATCH'; END IF;
 RETURN NEW; END $$;
 CREATE TRIGGER payroll_employee_store BEFORE INSERT OR UPDATE ON tenant_sample.payroll_period_employee FOR EACH ROW EXECUTE FUNCTION tenant_sample.validate_payroll_employee_store();
 CREATE TRIGGER payroll_snapshot_store BEFORE INSERT OR UPDATE ON tenant_sample.payroll_snapshot FOR EACH ROW EXECUTE FUNCTION tenant_sample.validate_payroll_employee_store();
 REVOKE ALL ON ALL FUNCTIONS IN SCHEMA tenant_sample FROM PUBLIC,anon,authenticated;
ALTER TABLE tenant_qa.payroll_period ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_qa.stores(id); ALTER TABLE tenant_qa.payroll_period ALTER COLUMN store_id SET DEFAULT public.current_store_id();
ALTER TABLE tenant_qa.payroll_period_employee ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_qa.stores(id); ALTER TABLE tenant_qa.payroll_period_employee ALTER COLUMN store_id SET DEFAULT public.current_store_id();
ALTER TABLE tenant_qa.payroll_snapshot ADD COLUMN store_id bigint NOT NULL REFERENCES tenant_qa.stores(id); ALTER TABLE tenant_qa.payroll_snapshot ALTER COLUMN store_id SET DEFAULT public.current_store_id();
ALTER TABLE tenant_qa.payroll_period DROP CONSTRAINT payroll_period_pkey, ADD PRIMARY KEY (ym,store_id);
CREATE OR REPLACE FUNCTION tenant_qa.admin_close_payroll(p_ym text, p_rows json, p_fingerprint text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
declare v_actor text; r json; n int:=0; v_month date;
begin
 if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
 if p_ym !~ '^[0-9]{4}-[0-9]{2}$' then raise exception 'BAD_YM'; end if;
 v_month:=(p_ym||'-01')::date;
 if v_month>=date_trunc('month',now() at time zone 'Asia/Seoul')::date then raise exception 'CURRENT_OR_FUTURE_MONTH_CANNOT_CLOSE'; end if;
 if exists(select 1 from tenant_qa.payroll_period where ym=p_ym and store_id=public.current_store_id() and status='CLOSED') then raise exception 'PAYROLL_ALREADY_CLOSED'; end if;
 v_actor:=coalesce(auth.jwt()->>'email','admin');
 delete from tenant_qa.payroll_snapshot where ym=p_ym and store_id=public.current_store_id();
 for r in select * from json_array_elements(p_rows) loop
   insert into tenant_qa.payroll_snapshot(ym,employee_id,employee_name,hours,wage,weeks,base_pay,juhyu_pay,adjust,gross_pay,tax_rate,net_pay,memo,source_fingerprint,closed_by)
   values(p_ym,(r->>'employee_id')::bigint,r->>'employee_name',nullif(r->>'hours','')::numeric,nullif(r->>'wage','')::int,nullif(r->>'weeks','')::int,
   nullif(r->>'base_pay','')::int,nullif(r->>'juhyu_pay','')::int,coalesce(nullif(r->>'adjust','')::int,0),nullif(r->>'gross_pay','')::int,
   nullif(r->>'tax_rate','')::numeric,nullif(r->>'net_pay','')::int,r->>'memo',p_fingerprint,v_actor);
   n:=n+1;
 end loop;
 insert into tenant_qa.payroll_period(ym,status,updated_by,updated_at) values(p_ym,'CLOSED',v_actor,now())
 on conflict(ym,store_id) do update set status='CLOSED',updated_by=v_actor,updated_at=now();
 return json_build_object('ok',true,'count',n);
end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_payroll_period(p_ym text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
begin
  if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  return (select json_build_object(
    'period', coalesce((select row_to_json(p) from payroll_period p where p.ym=p_ym and p.store_id=public.current_store_id()),
                       json_build_object('ym',p_ym,'status','OPEN','weeks',null)),
    'overrides', coalesce((select json_agg(row_to_json(o)) from payroll_period_employee o where o.ym=p_ym and o.store_id=public.current_store_id()),'[]'::json)));
end; $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_reopen_payroll(p_ym text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
declare v_actor text;
begin
  if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  v_actor := coalesce(auth.jwt()->>'email','admin');
  update payroll_period set status='OPEN', updated_by=v_actor, updated_at=now() where ym=p_ym and store_id=public.current_store_id();
  return json_build_object('ok',true);
end; $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_set_period_employee(p_ym text, p_employee_id bigint, p_fields json)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
begin
  if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  insert into payroll_period_employee(ym, employee_id,
      wage_override, juhyu_hours_override, juhyu_weeks_override, tax_rate_override, adjust_amount, memo, updated_by, updated_at)
    values (p_ym, p_employee_id,
      nullif(p_fields->>'wage_override','')::int,
      nullif(p_fields->>'juhyu_hours_override','')::numeric,
      nullif(p_fields->>'juhyu_weeks_override','')::int,
      nullif(p_fields->>'tax_rate_override','')::numeric,
      coalesce(nullif(p_fields->>'adjust_amount','')::int,0),
      nullif(p_fields->>'memo',''),
      coalesce(auth.jwt()->>'email','admin'), now())
  on conflict (ym, employee_id) do update set
      wage_override=excluded.wage_override,
      juhyu_hours_override=excluded.juhyu_hours_override,
      juhyu_weeks_override=excluded.juhyu_weeks_override,
      tax_rate_override=excluded.tax_rate_override,
      adjust_amount=excluded.adjust_amount,
      memo=excluded.memo, updated_by=excluded.updated_by, updated_at=now();
end; $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_set_period_weeks(p_ym text, p_weeks integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
begin
  if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  insert into payroll_period(ym, weeks, updated_by, updated_at)
    values (p_ym, p_weeks, coalesce(auth.jwt()->>'email','admin'), now())
  on conflict (ym,store_id) do update set weeks=excluded.weeks, updated_by=excluded.updated_by, updated_at=now();
end; $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_snapshot(p_ym text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
begin
  if not tenant_qa.is_admin() then raise exception 'NOT_AUTHORIZED'; end if;
  return (select json_build_object(
    'status', coalesce((select status from payroll_period where ym=p_ym and store_id=public.current_store_id()),'OPEN'),
    'fingerprint', (select source_fingerprint from payroll_snapshot where ym=p_ym and store_id=public.current_store_id() limit 1),
    'rows', coalesce((select json_agg(row_to_json(s)) from (
      select employee_id,employee_name,hours,wage,weeks,base_pay,juhyu_pay,adjust,gross_pay,tax_rate,net_pay,memo,closed_by,closed_at
      from payroll_snapshot where ym=p_ym and store_id=public.current_store_id() order by employee_name) s),'[]'::json)));
end; $function$
;
CREATE FUNCTION tenant_qa.validate_payroll_employee_store() RETURNS trigger LANGUAGE plpgsql SET search_path=tenant_qa,pg_temp AS $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM tenant_qa.employees WHERE id=NEW.employee_id AND store_id=NEW.store_id) THEN RAISE EXCEPTION 'EMPLOYEE_STORE_MISMATCH'; END IF;
 RETURN NEW; END $$;
 CREATE TRIGGER payroll_employee_store BEFORE INSERT OR UPDATE ON tenant_qa.payroll_period_employee FOR EACH ROW EXECUTE FUNCTION tenant_qa.validate_payroll_employee_store();
 CREATE TRIGGER payroll_snapshot_store BEFORE INSERT OR UPDATE ON tenant_qa.payroll_snapshot FOR EACH ROW EXECUTE FUNCTION tenant_qa.validate_payroll_employee_store();
 REVOKE ALL ON ALL FUNCTIONS IN SCHEMA tenant_qa FROM PUBLIC,anon,authenticated;