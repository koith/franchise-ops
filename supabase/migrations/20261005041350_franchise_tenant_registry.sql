CREATE TABLE public.tenants (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), slug text UNIQUE NOT NULL,
 name text NOT NULL, schema_name name UNIQUE NOT NULL,
 logo_url text, primary_color text NOT NULL DEFAULT '#166534',
 active boolean NOT NULL DEFAULT true, created_at timestamptz NOT NULL DEFAULT now(),
 CHECK(schema_name::text ~ '^tenant_[a-z0-9_]+$')
);
CREATE TABLE public.tenant_memberships (
 tenant_id uuid NOT NULL REFERENCES public.tenants(id), user_id uuid NOT NULL REFERENCES auth.users(id),
 role text NOT NULL CHECK(role IN ('HQ','STORE_MANAGER')), store_id bigint,
 PRIMARY KEY(tenant_id,user_id), CHECK(role='HQ' OR store_id IS NOT NULL)
);
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_memberships ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.tenants,public.tenant_memberships FROM anon,authenticated;
CREATE FUNCTION public.current_tenant_schema() RETURNS name LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE result name; slug_value text;
BEGIN
 slug_value := nullif(current_setting('request.headers',true),'')::jsonb->>'x-tenant-id';
 SELECT schema_name INTO result FROM public.tenants WHERE slug=slug_value AND active;
 IF result IS NULL THEN RAISE EXCEPTION 'TENANT_REQUIRED' USING ERRCODE='42501'; END IF;
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.current_tenant_schema() FROM PUBLIC,anon,authenticated;
CREATE FUNCTION public.tenant_config(p_slug text) RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public,pg_temp AS $$
SELECT jsonb_build_object('id',slug,'name',name,'logo_url',logo_url,'primary_color',primary_color) FROM public.tenants WHERE slug=p_slug AND active;
$$;
REVOKE ALL ON FUNCTION public.tenant_config(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tenant_config(text) TO anon,authenticated;

