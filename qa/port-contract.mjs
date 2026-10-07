import fs from 'node:fs';import assert from 'node:assert/strict';
const h=fs.readFileSync('index.html','utf8');assert(h.length>200000);assert(h.includes('const APP_VERSION="v0.04"'));
for(const name of ['actual_attendance','employment_contracts','operations_v1','operations_reference_ui_v208','substitution_v2','payroll_contract_authority_v1'])assert(fs.statSync(name+'.js').size>1000,name);
for(const f of fs.readdirSync('.').filter(f=>/\.(html|js|css)$/.test(f)&&!f.startsWith('qa'))){const s=fs.readFileSync(f,'utf8');assert(!s.includes('waluhdgqhwjjwmflhrle'),f);if(f.endsWith('.html')&&s.includes('<script'))assert(s.includes('tenant-context.js'),f);}
console.log('Complete source modules and isolated runtime PASS');

for(const f of fs.readdirSync('.').filter(f=>f.endsWith('.html'))){const s=fs.readFileSync(f,'utf8');assert.equal((s.match(/src="tenant-context\.js/g)||[]).length,1,'exactly one tenant boundary: '+f);}
assert(!h.includes('Number(CURRENT_STORE_ID)!==1'),'all stores can enter operations');
assert(!h.includes('CURRENT_STORE_ID||1'),'no fallback to a different store');
