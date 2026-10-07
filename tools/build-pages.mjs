import {readdir,copyFile,mkdir,rm} from 'node:fs/promises';
// Publish runtime files only; backend definitions, migrations and QA stay in Git.
const root=new URL('../',import.meta.url),out=new URL('../dist/',import.meta.url);
await rm(out,{recursive:true,force:true});await mkdir(out,{recursive:true});
for(const entry of await readdir(root,{withFileTypes:true})){
 if(!entry.isFile()||!/\.(html|css|js|svg|jpg|png|webmanifest|ico|woff2?)$/.test(entry.name))continue;
 if(/^(qa_|visual_qa\.)/.test(entry.name))continue;
 await copyFile(new URL(entry.name,root),new URL(entry.name,out));
}
console.log('Runtime-only Pages bundle ready');
