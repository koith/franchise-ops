// Only signed GitHub Actions identities for this repository may provision a
// short-lived administrator in the synthetic QA tenant. No production tenant.
import {createRemoteJWKSet,jwtVerify} from 'https://esm.sh/jose@5.9.6';
import {createClient} from 'https://esm.sh/@supabase/supabase-js@2';
const keys=createRemoteJWKSet(new URL('https://token.actions.githubusercontent.com/.well-known/jwks'));
Deno.serve(async req=>{
 try{
  if(req.method!=='POST')return new Response('Method not allowed',{status:405});
  const token=(req.headers.get('Authorization')||'').replace(/^Bearer /,'');
  const {payload:c}=await jwtVerify(token,keys,{issuer:'https://token.actions.githubusercontent.com',audience:'franchise-ops-browser-qa',algorithms:['RS256'],maxTokenAge:'10m'});
  if(c.repository_id!=='1405061163'||c.repository_owner_id!=='48688331'||c.repository!=='koith/franchise-ops'||!['push','pull_request'].includes(String(c.event_name))||!String(c.workflow_ref).startsWith('koith/franchise-ops/.github/workflows/pages.yml@')||!/^\d+$/.test(String(c.run_id)))throw Error('DENIED');
  const admin=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const body=await req.json();
  if(body.action==='cleanup'){
   const {data,error}=await admin.auth.admin.getUserById(String(body.user_id));
   if(error||data.user?.app_metadata?.qa_run!==c.run_id)throw Error('DENIED');
   const {error:dbError}=await admin.rpc('ci_qa_membership',{p_user_id:data.user.id,p_remove:true});if(dbError)throw dbError;
   const deleted=await admin.auth.admin.deleteUser(data.user.id);if(deleted.error)throw deleted.error;
   return Response.json({ok:true});
  }
  const password=crypto.randomUUID()+crypto.randomUUID();
  const email='ci-'+c.run_id+'-'+crypto.randomUUID()+'@example.invalid';
  const {data,error}=await admin.auth.admin.createUser({email,password,email_confirm:true,app_metadata:{qa_run:c.run_id,qa_only:true}});if(error)throw error;
  const {error:dbError}=await admin.rpc('ci_qa_membership',{p_user_id:data.user.id,p_remove:false});
  if(dbError){await admin.auth.admin.deleteUser(data.user.id);throw dbError;}
  return Response.json({email,password,user_id:data.user.id},{headers:{'Cache-Control':'no-store'}});
 }catch(_){return Response.json({error:'QA_SESSION_DENIED'},{status:403});}
});
