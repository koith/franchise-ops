import fs from 'node:fs';import {spawnSync} from 'node:child_process';
const tests=JSON.parse(fs.readFileSync('qa/active-source-tests.json'));
const prerequisite=spawnSync('node',['qa_extract_logic.mjs'],{encoding:'utf8'});if(prerequisite.status)throw Error(prerequisite.stderr);
let failed=0;
for(const file of tests){const r=spawnSync('node',[file],{encoding:'utf8',timeout:30000});console.log(`${r.status===0?'PASS':'FAIL'} ${file}`);if(r.status!==0){failed++;console.error((r.stdout+r.stderr).slice(-2500));}}
console.log(`${tests.length-failed}/${tests.length} imported active regression gates passed`);if(failed)process.exitCode=1;
