# HANDOFF

Current product: generic multi-franchise operations platform.
Isolation: separate repository from koith/attendance-proto. Never modify attendance-proto as part of this repository's work.

Initial sample tenant: GCOVA Chicken (지코바 치킨), used only to make the generic build visually distinguishable.
Initial milestone: HQ dashboard -> store selection -> store operations page.

Architecture:
- tenant config owns brand identity.
- stores are data under tenant.
- UI renders from config/data, not hardcoded store branches.
- backend/Supabase will be provisioned separately before real data integration.

Current phase: static first vertical slice with mock tenant/store operational data.
