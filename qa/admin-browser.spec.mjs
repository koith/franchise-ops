import {test,expect} from '@playwright/test';
test.setTimeout(240000);
test('authenticated original administrator workflows on isolated tenant',async({page,request})=>{
 const oidc=await request.get(process.env.ACTIONS_ID_TOKEN_REQUEST_URL+'&audience=franchise-ops-browser-qa',{headers:{Authorization:'Bearer '+process.env.ACTIONS_ID_TOKEN_REQUEST_TOKEN}});
 expect(oidc.ok()).toBeTruthy();const {value:jwt}=await oidc.json();
 const endpoint='https://xkeowpbbsllfuauifdqb.supabase.co/functions/v1/ci-browser-session';
 const headers={Authorization:'Bearer '+jwt};
 const session=await request.post(endpoint,{headers,data:{action:'create'}});
 expect(session.ok(),await session.text()).toBeTruthy();const account=await session.json();
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 try{
  await page.setViewportSize({width:393,height:852});
  await page.goto('http://127.0.0.1:4173/?tenant=qa-isolation#dashboard');
  await page.locator('#loginEmail').fill(account.email);await page.locator('#loginPw').fill(account.password);await page.locator('#loginBtn').click();
  await expect(page.locator('.hq-store-panel')).toContainText('격리 검증점',{timeout:30000});
  await page.locator('.hq-store-panel button').first().click();
  await expect(page.locator('#empGrid')).toContainText('격리 검증 직원');
  for(const width of [393,1440]){
  await page.setViewportSize({width,height:width===393?852:1000});
  for(const route of ['admin','pay','hours','report','sales','inventory']){
   await page.goto('http://127.0.0.1:4173/?tenant=qa-isolation#'+route);
   await expect(page.locator('#view')).not.toBeEmpty();
   await expect(page.locator('.admin-subtabs')).toBeVisible({timeout:20000});
   await expect(page.locator('#loginEmail')).toHaveCount(0);
   if(route==='pay'){
    await expect(page.locator('#payList')).not.toContainText('계산 중',{timeout:30000});
    await expect(page.locator('#payList')).not.toContainText('불러오기 실패');
   }
   if(route==='report')await expect(page.locator('.ops-kpis')).toBeVisible({timeout:30000});
   if(route==='sales')await expect(page.locator('#opsType')).toBeVisible({timeout:30000});
   if(route==='inventory'){
    await expect(page.locator('#opsInventoryAdd')).toBeVisible({timeout:30000});
    if(width===393){
     await page.locator('#opsInventoryAdd').click();
     await page.locator('#inventoryName').fill('CI 검증 품목');
     await page.locator('#inventorySku').fill('QA-'+account.user_id);
     await page.locator('#inventoryOnHand').fill('7');
     await page.locator('#inventoryTarget').fill('10');
     await page.locator('#inventoryReorder').fill('3');
     await page.locator('#inventorySave').click();
     await expect(page.locator('#inventorySave')).toHaveCount(0,{timeout:20000});
    }
    await expect(page.locator('#opsBody')).toContainText('CI 검증 품목',{timeout:20000});
   }
   expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1)).toBeTruthy();
   await page.screenshot({path:`artifacts/admin-${route}-${width}.png`,fullPage:true});
  }
  }
  expect(errors).toEqual([]);
 }finally{
  const r=await request.post(endpoint,{headers,data:{action:'cleanup',user_id:account.user_id}});expect(r.ok(),'QA identity cleanup').toBeTruthy();
 }
});
