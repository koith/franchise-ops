-- Reject any wrapper whose USING identifiers are not declared input arguments.
SELECT p.proname, pg_get_functiondef(p.oid)
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND pg_get_functiondef(p.oid) LIKE '%USING "id"%';
