CREATE OR REPLACE FUNCTION public.ci_qa_membership(p_user_id uuid,p_remove boolean DEFAULT false) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM auth.users WHERE id=p_user_id AND raw_app_meta_data->>'qa_only'='true') THEN RAISE EXCEPTION 'QA_USER_REQUIRED'; END IF;
 IF p_remove THEN
  DELETE FROM tenant_qa.admin_users WHERE user_id=p_user_id;
  DELETE FROM public.tenant_memberships WHERE user_id=p_user_id;
 ELSE
  INSERT INTO public.tenant_memberships(tenant_id,user_id,role) SELECT id,p_user_id,'HQ' FROM public.tenants WHERE slug='qa-isolation' ON CONFLICT DO NOTHING;
  INSERT INTO tenant_qa.admin_users(user_id,email,admin_role) SELECT id,email,'HQ' FROM auth.users WHERE id=p_user_id ON CONFLICT(user_id) DO NOTHING;
 END IF;
END $$;
REVOKE ALL ON FUNCTION public.ci_qa_membership(uuid,boolean) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.ci_qa_membership(uuid,boolean) TO service_role;
