import fs from "node:fs";import path from "node:path";import assert from "node:assert/strict";
const root="reference-port";
const files=fs.readdirSync(root).filter(f=>/\.(?:js|css|html)$/.test(f));
assert.equal(files.length,81,"reference runtime file count must match source snapshot");
for(const name of files){const s=fs.readFileSync(path.join(root,name),"utf8");assert(!s.includes("waluhdgqhwjjwmflhrle"),name+" must not point to production Supabase");assert(!s.includes("1-0on5kKhnIrjrutEDAR9y4nkBGlB1VL6YaLD49eG024"),name+" must not point to production Sheet");assert(!/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/.test(s),name+" must not carry a copied anon token");}
const html=fs.readFileSync(path.join(root,"index.html"),"utf8");assert(html.includes("xkeowpbbsllfuauifdqb"),"generic project reference missing");assert(html.includes("FRANCHISE_PUBLISHABLE_KEY")&&html.includes("generic-bootstrap.js"),"reference must load isolated tenant bootstrap");
const bootstrap=fs.readFileSync(path.join(root,"generic-bootstrap.js"),"utf8");assert(bootstrap.includes("x-tenant-id")&&bootstrap.includes("TENANT_CONFIG_UNAVAILABLE"),"tenant routing must fail visibly");
console.log("PASS 81 isolated reference runtime files; production endpoint, Sheet ID and token absent");
