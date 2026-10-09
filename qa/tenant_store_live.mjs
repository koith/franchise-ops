import assert from "node:assert/strict";
const base="https://xkeowpbbsllfuauifdqb.supabase.co";
const key="sb_publishable_aClD6oI0rr-KwanFlRyUTg_GUQKwRw0"; // public publishable key; never a service-role key
const oidcRequest=process.env.ACTIONS_ID_TOKEN_REQUEST_URL;
const oidcBearer=process.env.ACTIONS_ID_TOKEN_REQUEST_TOKEN;
assert(oidcRequest&&oidcBearer,"GitHub OIDC identity required");
const oidcUrl=new URL(oidcRequest);oidcUrl.searchParams.set("audience","franchise-ops-browser-qa");
const oidcRes=await fetch(oidcUrl,{headers:{Authorization:"Bearer "+oidcBearer}});
assert(oidcRes.ok,"GitHub OIDC request failed");
const {value:oidc}=await oidcRes.json();
const sessionEndpoint=base+"/functions/v1/ci-browser-session";
async function session(body){const r=await fetch(sessionEndpoint,{method:"POST",headers:{Authorization:"Bearer "+oidc,"Content-Type":"application/json"},body:JSON.stringify(body)});assert(r.ok,"QA session endpoint failed: "+r.status);return r.json()}
const account=await session({});
try{
 const login=await fetch(base+"/auth/v1/token?grant_type=password",{method:"POST",headers:{apikey:key,"Content-Type":"application/json"},body:JSON.stringify({email:account.email,password:account.password})});
 assert(login.ok,"QA authentication failed");
 const {access_token}=await login.json();
 async function stores(slug){return fetch(base+"/rest/v1/rpc/tenant_store_list",{method:"POST",headers:{apikey:key,Authorization:"Bearer "+access_token,"Content-Type":"application/json"},body:JSON.stringify({p_slug:slug})})}
 const own=await stores("qa-isolation");assert(own.ok,"authorized tenant store listing failed: "+own.status);assert(Array.isArray(await own.json()),"store listing must be an array");
 const other=await stores("sample");assert(!other.ok,"cross-tenant store listing unexpectedly succeeded");
 console.log("PASS authenticated QA tenant listing and cross-tenant denial");
}finally{await session({action:"cleanup",user_id:account.user_id})}
