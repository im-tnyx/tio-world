# Routine Notes migration 80 role context correction

**Status:** In progress
**Implementation owner:** Codex (this slice)
**Parent:** TNYX-81; deployment packet: [Routine Notes deployment approval](routine-notes-production-deployment-approval.md)
**Repository anchor:** `main@435a6fc521f7c49d40324330b3ac3f40e57e0c6d`

## Scope and evidence

- Owner approved a narrow correction to `20261031130000_routine_note_receipt_scheduled_cleanup.sql` after hosted CLI v2.114.0 failed at `GRANT routine_note_receipt_cleanup_scheduler TO postgres WITH SET TRUE` (`XX000`, `no possible grantors`). Hosted ledger stopped at 79; the Notes gate remains disabled.
- In scope: restore the trusted `postgres` migration role after the second cleanup-owner function creation; add a disposable PostgreSQL 17 regression and record deployment implications.
- Out of scope: hosted SQL/CLI execution, ledger repair, migration 81, Notes activation, Flutter UI, broader permission changes.
- Preserve the existing uncommitted deployment-packet edits and `stash@{0}`. No concurrent owner for this exact correction was found among open Routine Notes PRs at preflight.

## Diagnosis and verification

The linked CLI session uses a login role distinct from the `postgres` migration role. PostgreSQL `RESET ROLE` restores that login role. In a disposable PostgreSQL 17 session, the first role grant succeeded as the migration role; after `RESET ROLE`, the second grant failed with `XX000`. Explicitly setting the migration role again before that grant succeeded and allowed the scheduler role switch.

## Validation

- `tnyx_81_cleanup_grant_context.sh`: PASS on isolated PostgreSQL 17; checks linked-login `RESET ROLE`, corrected grant, scheduler switch, and `SET=true`, `INHERIT=false`, `ADMIN=false` membership.
- Existing `tnyx_81_routine_note_receipt_cleanup.test.sql`: PASS against disposable local Supabase test database; assertions include role ACLs, scheduler identity, receipt redaction, bounded batches and RLS denials. Test transaction rolled back.
- `git diff --cached --check`: PASS. Full staged migration replay and hosted scheduler execution: NOT RUN; PR CI and later supervised deployment checkpoints remain required.
- The deployment packet's pre-existing uncommitted changes were preserved. Its appended hosted-incident update is local and intentionally excluded from this focused PR to avoid staging earlier user edits.

## Handoff

Submit the narrow SQL/test/doc diff for independent review. Keep the hosted ledger at its observed prefix, verify the gate remains disabled, and do not run either remaining migration before review and owner-controlled deployment gates.
