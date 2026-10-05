import {test,expect} from '@playwright/test';
const base='http://127.0.0.1:4173';
test.setTimeout(90000);
for(const viewport of [{width:393,height:852},{width:1440,height:1000}]){
 test(`real tenant API and original layout ${viewport.width}`,async({page,request})=>{
  await page.setViewportSize(viewport);
  const failures=[];page.on('pageerror',e=>failures.push(e.message));
  const outgoing=[];page.on('request',r=>{if(r.url().includes('.supabase.co'))outgoing.push(r.url())});
  await page.goto(base+'/?tenant=sample#pos');
  await expect(page.locator('#empGrid')).toContainText('샘플 직원',{timeout:60000});
  await expect(page.locator('#appVersion')).toContainText('v0.04');
  expect(outgoing.every(u=>u.startsWith('https://xkeowpbbsllfuauifdqb.supabase.co/'))).toBeTruthy();
  expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1)).toBeTruthy();
  const layout=await page.locator('#empGrid').evaluate(e=>({columns:getComputedStyle(e).gridTemplateColumns,display:getComputedStyle(e).display}));
  expect(layout.display).toBe('grid');
  if(viewport.width<600)expect(layout.columns.split(' ').length).toBe(2);
  await page.locator('#empGrid .emp').first().click();
  await expect(page.locator('#padVeil')).toHaveClass(/show/);
  await page.locator('#padCancel').click();
  await page.locator('#hqHome').click();
  await expect(page.locator('#view')).toContainText('관리자 로그인');
  await page.goto(base+'/?tenant=qa-isolation#pos');
  await expect(page.locator('#empGrid')).toContainText('격리 검증 직원',{timeout:60000});
  await expect(page.locator('#empGrid')).not.toContainText('샘플 직원');
  expect(failures).toEqual([]);
  await page.screenshot({path:`artifacts/tenant-${viewport.width}.png`,fullPage:true});
 });
}
test('tenant is required, private schemas are inaccessible, admin RPC rejects anonymous',async({request})=>{
 const text=await (await request.get(base+'/tenant-context.js')).text();
 const key=text.match(/const apiKey='([^']+)'/)[1];
 const url='https://xkeowpbbsllfuauifdqb.supabase.co/rest/v1/rpc/';
 const headers={apikey:key,Authorization:'Bearer '+key};
 for(const tenant of [null,'unknown-tenant']){
  const r=await request.post(url+'list_stores',{headers:{...headers,...(tenant?{'x-tenant-id':tenant}:{})},data:{}});expect(r.ok()).toBeFalsy();
 }
 const r=await request.post(url+'admin_list_employees',{headers:{...headers,'x-tenant-id':'sample'},data:{}});expect(r.ok()).toBeFalsy();
});
