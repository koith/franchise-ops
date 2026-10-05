/* Isolated runtime boundary; runs before every imported application module. */
(()=>{
'use strict';
const params=new URLSearchParams(location.search);
const native={get:Storage.prototype.getItem,set:Storage.prototype.setItem,remove:Storage.prototype.removeItem};
const tenant=params.get('tenant')||native.get.call(sessionStorage,'franchise:active-tenant')||'sample';
if(!/^[a-z0-9][a-z0-9-]{0,62}$/.test(tenant))throw Error('INVALID_TENANT');
native.set.call(sessionStorage,'franchise:active-tenant',tenant);
const base=`franchise:${tenant}:`;
const store=()=>params.get('store')||native.get.call(sessionStorage,base+'store-context')||'hq';
const key=k=>{
 k=String(k);
 if(k==='franchise_store_id')return base+'store-context';
 if(k==='franchise_auth')return base+'auth';
 return base+'store:'+store()+':'+k;
};
Storage.prototype.getItem=function(k){return native.get.call(this,key(k));};
Storage.prototype.setItem=function(k,v){return native.set.call(this,key(k),String(v));};
Storage.prototype.removeItem=function(k){return native.remove.call(this,key(k));};
const url='https://xkeowpbbsllfuauifdqb.supabase.co';
const apiKey='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhrZW93cGJic2xsZnVhdWlmZHFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExNDY5ODYsImV4cCI6MjEwNjcyMjk4Nn0.6scDVEJlV78k_vrgZ2jt1P1WIO5uwvsSIrkZnQQ0KEI';
window.FRANCHISE=Object.freeze({tenant,url,apiKey,storeId:()=>Number(store())||0});
const rawFetch=window.fetch.bind(window);
window.fetch=function(input,init){
 const u=new URL(typeof input==='string'?input:input.url,location.href);
 if(u.hostname.endsWith('.supabase.co')&&u.origin!==url)throw Error('CROSS_PROJECT_REQUEST_BLOCKED');
 if(u.origin===url){const h=new Headers(init?.headers||(input instanceof Request?input.headers:{}));h.set('x-tenant-id',tenant);init={...init,headers:h};}
 return rawFetch(input,init);
};
window.TENANT_READY=rawFetch(url+'/rest/v1/rpc/tenant_config',{method:'POST',headers:{apikey:apiKey,'Content-Type':'application/json'},body:JSON.stringify({p_slug:tenant})}).then(async r=>{if(!r.ok)throw Error('TENANT_CONFIG_FAILED');const cfg=await r.json();if(!cfg)throw Error('TENANT_NOT_FOUND');window.TENANT_CONFIG=Object.freeze(cfg);return cfg;});
document.addEventListener('DOMContentLoaded',()=>{
 window.TENANT_READY.then(cfg=>{
  document.title=cfg.name+' · '+document.title;
  document.querySelectorAll('[data-tenant-name]').forEach(el=>el.textContent=cfg.name);
  document.querySelectorAll('img[data-tenant-logo]').forEach(el=>{el.alt=cfg.name;if(cfg.logo_url)el.src=cfg.logo_url;});
 }).catch(()=>{document.body.replaceChildren(Object.assign(document.createElement('p'),{textContent:'프랜차이즈 설정을 불러오지 못했습니다. 주소의 tenant를 확인해주세요.'}));});
});
})();
