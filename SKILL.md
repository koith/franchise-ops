# Franchise Ops Work Contract

## Purpose
This repository is the generic multi-franchise operations platform. It must remain physically and operationally isolated from the Baekeok Coffee attendance-proto production/field-test repository.

## Mandatory start
1. Read latest main.
2. Read this file, HANDOFF.md, VERSIONING.md, playbooks/KNOWN_BUGS.md.
3. Inspect relevant code and QA before editing.

## Architecture contract
- Generic hierarchy: franchise/tenant -> stores -> operational modules.
- Sample/demo brand data may use GCOVA Chicken, but business logic must never depend on GCOVA names, store IDs, or codes.
- Brand/store identity must come from data/config.
- No code, database, deployment, secrets, or storage shared with attendance-proto.
- Namespace client persistence by tenant and store when persistence is introduced.
- Future backend data must be tenant-scoped and fail closed across tenants.

## Work continuation contract
NEXT ACTION EXISTS -> CONTINUE.
Do not stop at an executable next step. Development ends as COMPLETED, BLOCKED, or FAILED with evidence.
Do not make the user perform automatable QA.

## QA
- Mobile-first, iPhone portrait.
- Dashboard must select a store and enter a store page.
- Generic regression must prove changing tenant fixture data does not require UI/business-logic edits.
- Run all repository QA before PR/merge.
