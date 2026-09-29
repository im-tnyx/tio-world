# Workout migration lineage reconciliation

**Status:** In progress
**Primary owner:** `supabase/migrations` + data documentation governance
**Affected platforms:** Repository migration lineage and Supabase documentation only

## Owner Approval and Scope Boundary

**Trigger:** Repo/live migration identity drift discovered after PR #463 merge.
**Approval status:** Approved.
**Approval evidence:** Owner said `Go` after the read-only audit proposed this exact repo-only reconciliation.
**Approved scope:** Rename the checked-in Program migration version from `20260929000001` to the already-applied live identity `20260929040034` without changing its SQL body; keep Routine migration `20260929050000` pending; reconcile current Supabase strategy/schema inventory and Program/Routine execution handoffs to verified post-merge/live truth; validate repository migration replay/ledger and read-only repo-vs-live version/name parity.
**Explicit non-changes:** No hosted Supabase mutation; no `apply_migration`; no `db push`; no `migration repair`; no live ledger write; no schema/RLS/grant/data change; no Workout runtime/domain/repository/UI change; no new persistence shape; no Routine deployment.

## Active Handoff

**Planning owner:** Current repository agent
**Implementation owner:** Current repository agent
**Review owner:** Unassigned
**Implementation ownership state:** Active
**Repository state last verified:** remote `main@71fef2c9e2393e89c4cf415799a5ae8f5e7e4d8a`
**Branch:** `tnyx/workout-migration-lineage-reconciliation`
**Observed working-tree state:** Connector-only session; local status unavailable.
**PR / tracker:** TNYX-78 context; PR pending.
**Current implementation state:** Program migration identity renamed content-preservingly; live schema docs and Program/Routine handoffs reconciled; validation pending.
**Current blocker:** None.
**Next exact action:** Verify exact branch diff and repo/live lineage parity, then open PR and gate on Supabase Database CI/review.

## Discovery / Verified Evidence

- Live ledger has 50 rows and ends at `20260929040034 create_user_workout_programs`.
- Repository `main` has 51 migration files: Program at `20260929000001` plus pending Routine at `20260929050000`.
- Live `20260929040034` stored statement content matches the checked-in Program migration after terminal-newline normalization only: hosted storage omits the file's final `\n`; the first raw difference is EOF and `trimEnd()` content is identical.
- Live public schema has 15 base tables: `user_workout_programs` exists and `user_workout_routines` does not.
- The Routine migration depends on the live Program table and adds the missing `(id,user_id)` ownership key before creating `user_workout_routines`.
- Existing repository precedent reconciles timestamp identity drift by renaming the repository migration to the hosted version rather than mutating the hosted ledger when the logical/applied migration is the same.

## Success Criteria

- [x] Program migration path is `20260929040034_create_user_workout_programs.sql`.
- [x] Program migration body is byte-for-byte unchanged across the repository rename (same Git blob SHA `3881245c93cdd0e0801a44b003d84c14feb8bf44`). Hosted stored SQL differs only by the stripped terminal newline.
- [x] Repository historical migrations through Program match all 50 live ledger versions/names in a fresh read-only comparison: 51 repo migrations total, 50 exact applied matches, exactly one repo-only pending Routine migration, 0 live-only migrations.
- [x] Routine migration remains `20260929050000_create_user_workout_routines.sql` and remains unapplied live.
- [x] Supabase strategy/schema inventory reflect verified current live state, not future Routine state.
- [x] Program handoff archived as validated/live; Routine handoff now records merged source + pending live deployment.
- [ ] Supabase Database CI passes on the exact PR head.
- [ ] No hosted mutation occurs.

## Final Handoff

Pending.
