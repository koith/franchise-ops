# Full-source port (in progress, NOT COMPLETED)

Source: koith/attendance-proto main e0a39bc839d766f32418fad0354a640a411cc37f (v0.152).
Destination intended bundle: v0.04. Existing main remains v0.03 until verified merge.

All runtime modules and active source regressions were copied before isolation changes. Source remains read-only.
Target backend: xkeowpbbsllfuauifdqb (ap-northeast-2). Public tenant registry and RPC gateway select an isolated private schema per tenant. Private schemas preserve all 44 source table row shapes and 131 business functions. No source production rows, auth users, secrets, sheets, or storage were copied.

Sample tenant `sample` is GCOVA Chicken solely as a registry row. `qa-isolation` is an independent synthetic tenant used to test boundaries. Neither tenant name appears in business logic. Each has synthetic clearly-labelled employee/store fixtures.

QA: `npm test` runs the 100 regression scripts currently connected to source CI (extraction prerequisite first). Historical version-era checks remain for provenance, but obsolete version-specific tests are not current release gates. Brand key assertions were renamed and minimum-source-version assertions now check destination v0.04. SQL history assertions read provenance paths, not executable migrations.

Outstanding release gates: full real API behavior, member/store authorization, independent Google report integration, browser mobile/desktop interaction parity, PR CI, merge, Pages, deployed browser proof. Do not claim complete until these pass.
