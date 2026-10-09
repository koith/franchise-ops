import{test,expect}from"@playwright/test";
test("generic functional deployed UI",async({page})=>{
 await page.goto("http://127.0.0.1:4173/#dashboard");
 await expect(page.locator("#appVersion")).toHaveText("v0.04");
 await expect(page.locator(".hq-store-panel")).toHaveCount(6);
 await page.locator(".hq-store-panel").first().getByRole("button",{name:/상세/}).click();
 await expect(page).toHaveURL(/store=gangnam#pos/);
 await expect(page.locator("#storeTabs a.on")).toHaveText("출퇴근");
 const first=page.locator(".emp").first(); await first.click(); await page.locator("#pinInput").fill("1234"); await page.locator("#pinGo").click();
 await expect(page.locator(".emp").first().locator(".badge-off")).toHaveText("출근 전");
 const keys=await page.evaluate(()=>Object.keys(localStorage));
 expect(keys).toContain("franchise_ops:gcova:store:gangnam");
 expect(keys).not.toContain("franchise_ops:gcova:data");
 await page.getByRole("link",{name:"근무현황"}).click(); await expect(page.locator("#storeTabs a.on")).toHaveText("근무현황"); await expect(page.locator(".calendar")).toBeVisible();
 await page.getByRole("link",{name:"레시피"}).click(); await expect(page.locator("#storeTabs a.on")).toHaveText("레시피"); await expect(page.locator(".recipe-grid article")).toHaveCount(3);
 await page.getByRole("link",{name:"관리"}).click(); await expect(page.locator("#storeTabs a.on")).toHaveText("관리"); await expect(page.getByRole("heading",{name:"직원 관리"})).toBeVisible();
 await page.getByRole("button",{name:"급여"}).click(); await expect(page.locator(".pay-card").first()).toBeVisible();
 await page.getByRole("button",{name:"운영시간"}).click(); await page.locator("#open").fill("12:00"); await page.locator("#saveHours").click(); page.once("dialog",d=>d.accept());
 await page.getByRole("button",{name:"매출·매입"}).click(); const before=await page.locator(".ops-kpis b").first().textContent(); await page.locator("#plusSales").click(); await expect(page.locator(".ops-kpis b").first()).not.toHaveText(before);
 await page.getByRole("button",{name:"재고"}).click(); const inv=page.locator(".inventory-list article").first(); const qty=await inv.locator("strong").textContent(); await inv.locator("button").click(); await expect(page.locator(".inventory-list article").first().locator("strong")).not.toHaveText(qty);
 await page.setViewportSize({width:430,height:932}); await expect(page.locator("body")).toHaveJSProperty("scrollWidth",430);
 await page.screenshot({path:"artifacts/iphone-smoke.png",fullPage:true});
});
test("alternative tenant fixture",async({page})=>{
 const fixture='export const tenant={id:"other",name:"독립 브랜드",stores:[{id:"branch1",name:"1호점",region:"서울"}],fixture:{employeeNames:["직원"],baseWage:11000,baseHours:24,operatingHours:{open:"10:00",close:"21:00"},baseSales:100000,salesStep:0,inventory:[["품목",5,"개",2]],recipes:[["레시피","설명"]]}};';
 await page.route("**/tenant-config.js",route=>route.fulfill({status:200,contentType:"application/javascript",body:fixture}));
 await page.goto("http://127.0.0.1:4173/#dashboard");
 await expect(page.locator("#brandName")).toHaveText("독립 브랜드");
 await expect(page.locator(".hq-store-panel")).toHaveCount(1);
 await page.locator(".hq-store-panel button").click();
 await expect(page).toHaveURL(/store=branch1#pos/);
});

test("reference UI resolves tenant brand from dedicated Supabase",async({page})=>{
 await page.goto("http://127.0.0.1:4173/reference-port/index.html?tenant=qa-isolation#dashboard");
 await expect(page).toHaveTitle("격리 검증 프랜차이즈 업무자동화",{timeout:15000});
 await expect(page.locator("#hqHome strong")).toHaveText("격리 검증 프랜차이즈");
});
