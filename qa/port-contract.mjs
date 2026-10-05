import fs from 'node:fs';import assert from 'node:assert/strict';
const h=fs.readFileSync('index.html','utf8');assert(h.length>200000);assert(h.includes('const APP_VERSION="v0.04"'));
for(const name of ['actual_attendance','employment_contracts','operations_v1','operations_reference_ui_v208','substitution_v2','payroll_contract_authority_v1'])assert(fs.statSync(name+'.js').size>1000,name);
for(const f of fs.readdirSync('.').filter(f=>/\.(html|js|css)$/.test(f)&&!f.startsWith('qa'))){const s=fs.readFileSync(f,'utf8');assert(!s.includes('waluhdgqhwjjwmflhrle'),f);if(f.endsWith('.html')&&s.includes('<script'))assert(s.includes('tenant-context.js'),f);}
console.log('Complete source modules and isolated runtime PASS');
