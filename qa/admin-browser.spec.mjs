import {test,expect} from '@playwright/test';
test.setTimeout(120000);
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
  for(const route of ['admin','pay','hours','report','sales','inventory']){
   await page.goto('http://127.0.0.1:4173/?tenant=qa-isolation#'+route);
   await expect(page.locator('#view')).not.toBeEmpty();
   await expect(page.locator('.admin-subtabs')).toBeVisible({timeout:20000});
   await expect(page.locator('#loginEmail')).toHaveCount(0);
   await page.screenshot({path:`artifacts/admin-${route}-393.png`,fullPage:true});
  }
  expect(errors).toEqual([]);
 }finally{
  const r=await request.post(endpoint,{headers,data:{action:'cleanup',user_id:account.user_id}});expect(r.ok(),'QA identity cleanup').toBeTruthy();
 }
});
