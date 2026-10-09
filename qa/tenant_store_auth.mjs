import fs from "node:fs";import assert from "node:assert/strict";
const sql=fs.readFileSync("supabase/migrations/20261009003000_tenant_store_list.sql","utf8");
for(const term of ["auth.uid() is null","tenant_id=v_tenant.id and user_id=auth.uid()","v_member.role,v_member.store_id","format(","%I.stores","revoke all on function public.tenant_store_list(text) from public, anon","grant execute on function public.tenant_store_list(text) to authenticated"])assert(sql.includes(term),"missing store tenant authorization guard: "+term);
assert(!sql.includes("waluhdgqhwjjwmflhrle"));
console.log("PASS tenant-scoped store RPC authorization contract");
