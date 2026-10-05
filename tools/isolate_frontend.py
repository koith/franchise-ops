from pathlib import Path
import re,json
R=Path(__file__).resolve().parents[1];S=R.parent/'attendance-source'
key=json.load(open(R.parent/'target-public-key.json'))['key']
old=re.search(r'SUPABASE_ANON_KEY: "([^"]+)"',(S/'index.html').read_text())[1]
for p in R.iterdir():
 if p.suffix not in ['.html','.js','.css','.ts','.gs'] or p.name.startswith('qa_'):continue
 s=p.read_text()
 s=s.replace('https://waluhdgqhwjjwmflhrle.supabase.co','https://xkeowpbbsllfuauifdqb.supabase.co').replace(old,key)
 s=s.replace('baekeok','franchise').replace('Baekeok','Franchise').replace('백억커피','프랜차이즈').replace('인하대학교점','현재 지점').replace('인하대점','현재 지점')
 s=s.replace('1-0on5kKhnIrjrutEDAR9y4nkBGlB1VL6YaLD49eG024','')
 s=s.replace('logo_combine.jpg','brand.svg').replace('logo_single.jpg','brand.svg')
 # Explicit store context, never silently choose a source-specific store id.
 s=re.sub(r'(sessionStorage\.getItem\([\"\']franchise_store_id[\"\']\)\))\s*\|\|\s*1\b',r'\1||0',s)
 if p.suffix=='.html':
  s=s.replace('<head>','<head><script src="tenant-context.js?v=004"></script>',1)
  s=s.replace('<head\n','<head\n',1)
  s=re.sub(r'(<img\b[^>]*src="brand.svg"[^>]*)(>)',r'\1 data-tenant-logo\2',s)
 if p.name=='index.html':
  s=s.replace('const APP_VERSION="v0.152"','const APP_VERSION="v0.04"')
  s=re.sub(r'const STORE_ENTRY_PATH=.*?;', 'const STORE_ENTRY_PATH=false;',s)
  s=s.replace('Number(STORE_ENTRY_PARAMS.get("store"))||((STORE_ENTRY_MODE==="store"||STORE_ENTRY_PATH)?1:0)','Number(STORE_ENTRY_PARAMS.get("store"))||0')
  s=s.replace('STORE_ENTRY_ID||1','STORE_ENTRY_ID||0')
  s=s.replace('const inha=rows.find(x=>Number(x.id)===1);','const remembered=Number(sessionStorage.getItem("franchise_store_id"));')
  s=s.replace('requested||(inha?1:Number(rows[0].id))','requested||(rows.some(x=>Number(x.id)===remembered)?remembered:Number(rows[0].id))')
  s=s.replace('DEVICE_ID: "POS_INHA_01"','DEVICE_ID: "FRANCHISE_POS"').replace('STORE_NAME: "현재 지점"','STORE_NAME: "현재 지점"')
 p.write_text(s)
p=R/'tenant-context.js';p.write_text(p.read_text().replace('__DESTINATION_ANON_KEY__',key))
