// Tenant router for the staged reference UI. Public keys only; all privileged data remains RLS/RPC guarded.
(()=>{
 const slug=new URLSearchParams(location.search).get("tenant")||"sample";
 if(!/^[a-z0-9][a-z0-9-]{0,62}$/.test(slug))throw Error("INVALID_TENANT_SLUG");
 window.FRANCHISE_TENANT_SLUG=slug;
 const origin="https://xkeowpbbsllfuauifdqb.supabase.co";
 const nativeFetch=window.fetch.bind(window);
 window.fetch=(input,init)=>{
  const target=new URL(typeof input==="string"?input:input.url,location.href);
  if(target.origin!==origin)return nativeFetch(input,init);
  const headers=new Headers(init?.headers||(input instanceof Request?input.headers:undefined));
  headers.set("x-tenant-id",slug);
  return nativeFetch(input,{...init,headers});
 };
 document.addEventListener("DOMContentLoaded",async()=>{
  try{
   const r=await window.fetch(origin+"/rest/v1/rpc/tenant_config",{method:"POST",headers:{"apikey":window.FRANCHISE_PUBLISHABLE_KEY,"Content-Type":"application/json"},body:JSON.stringify({p_slug:slug})});
   if(!r.ok)throw Error("TENANT_CONFIG_UNAVAILABLE");
   const config=await r.json();if(!config?.name)throw Error("TENANT_NOT_FOUND");
   document.title=config.name+" 업무자동화";
   const logo=document.querySelector("#hqHome img");
   if(logo){const label=document.createElement("strong");label.textContent=config.name;logo.replaceWith(label)}
   if(/^#[0-9a-fA-F]{6}$/.test(config.primary_color||""))document.documentElement.style.setProperty("--brand-700",config.primary_color);
  }catch(err){console.error("[tenant-bootstrap]",err);const label=document.querySelector(".conn");if(label)label.textContent="테넌트 연결 오류";}
 });
})();
