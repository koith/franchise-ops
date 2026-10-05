# KNOWN BUGS / REGRESSION CONTRACTS

## Tenant isolation
- Never identify tenant/store through magic numeric IDs or brand-name string branches.
- Never let one tenant's store list, employees, payroll, inventory, recipes, or storage keys collide with another tenant.
- Sample GCOVA data is fixture/config, not product logic.

## Production isolation
- Never import runtime configuration, secrets, database references, Apps Script deployments, Sheets/Drive roots, or deployment targets from attendance-proto.

## UI
- Mobile portrait is primary.
- Dashboard cards and store navigation must remain usable without horizontal overflow.
- Store page must clearly show the selected store and provide a path back to HQ dashboard.
