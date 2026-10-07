# Full-source port (in progress, NOT COMPLETED)

Source: koith/attendance-proto main e0a39bc839d766f32418fad0354a640a411cc37f (v0.152).
Destination intended bundle: v0.04. Existing main remains v0.03 until verified merge.

All runtime modules and active source regressions were copied before isolation changes. Source remains read-only.
Target backend: xkeowpbbsllfuauifdqb (ap-northeast-2). Public tenant registry and RPC gateway select an isolated private schema per tenant. Private schemas preserve all 44 source table row shapes and 131 business functions. No source production rows, auth users, secrets, sheets, or storage were copied.

Sample tenant `sample` is GCOVA Chicken solely as a registry row. `qa-isolation` is an independent synthetic tenant used to test boundaries. Neither tenant name appears in business logic. Each has synthetic clearly-labelled employee/store fixtures.

QA: `npm test` runs the 100 regression scripts currently connected to source CI (extraction prerequisite first). Historical version-era checks remain for provenance, but obsolete version-specific tests are not current release gates. Brand key assertions were renamed and minimum-source-version assertions now check destination v0.04. SQL history assertions read provenance paths, not executable migrations.

Outstanding release gates: full real API behavior, member/store authorization, independent Google report integration, browser mobile/desktop interaction parity, PR CI, merge, Pages, deployed browser proof. Do not claim complete until these pass.

Continuation 2026-10-08 KST:
- Latest source main reconfirmed unchanged at e0a39bc.
- PR #5 remains draft; no merge/Pages release claimed.
- Last verified original CI head f5bdbb: 100 source regression gates + 3 real-browser tests PASS.
- Actual destination SQL: create/schedule/read/tenant rejection PASS; independent two-store payroll close/reopen PASS (transaction rollback).
- Removed imported store-ID-1-only menu restriction; every selected store exposes original report/sales/inventory modules.
- Removed duplicate tenant-context script tags and moved recipe category labels/options into tenant reference config.
- Runtime-only Pages builder excludes backend/provenance/QA artifacts.
- CI-only custom-auth Edge endpoint verifies signed GitHub OIDC repository ID, owner ID, workflow, issuer/audience/expiry before provisioning a QA-only identity. Browser tests log in through the actual Auth endpoint and delete the identity afterward. This is restricted to synthetic qa-isolation, not sample/production.
- Outstanding: latest authenticated CI results, complete browser feature parity, store-manager and operation-data scope audit, independent report integration, release/deployed QA. Work is still in progress.
