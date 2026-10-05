import fs from "node:fs";
const html=fs.readFileSync("index.html","utf8");
const js=fs.readFileSync("app.js","utf8");
const css=fs.readFileSync("style.css","utf8");
const skill=fs.readFileSync("SKILL.md","utf8");
const checks=[
  ["viewport",html.includes("width=device-width")],
  ["module",html.includes('type="module"')],
  ["version",js.includes('APP_VERSION = "v0.01"')],
  ["tenant-config",js.includes('id: "gcova"') && js.includes("tenant.stores")],
  ["store-route",js.includes('qs.get("store")')],
  ["mobile-two-column",css.includes("repeat(2,minmax(0,1fr))")],
  ["isolation-contract",skill.includes("attendance-proto") && skill.includes("isolated")]
];
let failed=0;
for(const [name,ok] of checks){console.log((ok?"PASS":"FAIL")+" "+name);if(!ok)failed++;}
if(failed)process.exit(1);
console.log("PASS all "+checks.length+" checks");
