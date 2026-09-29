# Workout migration lineage reconciliation

**Status:** Validated
**Completion date:** 2026-09-29
**Primary owner:** `supabase/migrations` + data documentation governance
**Affected platforms:** Repository migration lineage and Supabase documentation only

## Owner Approval and Scope Boundary

**Trigger:** Repo/live migration identity drift discovered after PR #463 merge.
**Approval status:** Approved.
**Approval evidence:** Owner said `Go` after the read-only audit proposed this exact repo-only reconciliation.
**Approved scope:** Rename the checked-in Program migration version from `20260929000001` to the already-applied live identity `20260929040034` without changing its SQL body; keep Routine migration `20260929050000` pending; reconcile current Supabase strategy/schema inventory and Program/Routine execution handoffs to verified post-merge/live truth; validate repository migration replay/ledger and read-only repo-vs-live version/name parity.
**Explicit non-changes:** No hosted Supabase mutation; no `apply_migration`; no `db push`; no `migration repair`; no live ledger write; no schema/RLS/grant/data change; no Workout runtime/domain/repository/UI change; no new persistence shape; no Routine deployment.

## Active Handoff

**Planning owner:** None; reconciliation completed.
**Implementation owner:** None; PR #464 merged.
**Review owner:** Completed.
**Implementation ownership state:** Inactive.
**Repository state:** `main@9e278f6830a7d756bb2401ea20dfe5e3a28697af`.
**PR / tracker:** PR #464 squash-merged; TNYX-78 remains In Progress because broader W1 work and Routine live deployment are separate.
**Final validation:** Exact PR head `4a7e71cf8f39f8196d556bc5065142660ce1c853`; Supabase Database CI #86 success; commit attribution guard success; 0 unresolved review threads.
**Hosted state:** No hosted mutation occurred. Live ledger remains 50 migrations; `user_workout_programs` is present and `user_workout_routines` is absent.
**Final repo/live parity:** 51 repository migrations, 50 exact live version+name matches, exactly one repo-only pending migration `20260929050000_create_user_workout_routines`, 0 live-only.
**Follow-up boundary:** Routine deployment remains a separate explicitly authorized step and must preserve checked-in migration version identity.

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
- [x] Supabase Database CI #85 passed on source head `4ec21b0def0ec2a6b62fe7c8e9712fd20582ae66`.
- [x] No hosted mutation occurred; all hosted interactions were read-only.

## Quality Review

### Validation

- Supabase Database CI #86: **success** at final PR head `4a7e71cf8f39f8196d556bc5065142660ce1c853`.
- Full repository migration replay: **success**.
- Complete local migration ledger verification: **success**.
- TNYX-78 Routine ownership/RLS SQL matrix: **success**.
- Database lint delta guard: **success**.
- Commit attribution guard: **success**.
- Read-only hosted parity: 51 repo migrations, 50 live, 50 exact version+name matches, exactly one repo-only Routine migration, 0 live-only.
- Manual review: no open lineage, ordering, schema-inventory, or scope findings; PR review threads were 0.
- GitHub AI code-scanning failed before meaningful analysis with `400 The requested model is not supported` while creating the scanner model session. This matches TNYX-256 and produced no repository finding.

### Deployment Safety Follow-up

The currently available Supabase MCP `apply_migration` action accepts a migration name/query but no repository version. The previous Program deployment therefore recorded hosted version `20260929040034` instead of the original checked-in `20260929000001`. Routine deployment must use a version-preserving path, such as the checked-in migration workflow via Supabase CLI/`db push`, or another explicitly audited mechanism that preserves `20260929050000`. Do not recreate timestamp drift by blindly using `apply_migration`.

## Final Handoff

### Changed Areas

- Program migration filename only, with zero SQL-body diff;
- canonical live Supabase strategy/schema inventory;
- Program/Routine AI handoff governance and archive indexes.

### Actual Behavior

No runtime or hosted behavior changes. After this reconciliation lands, the first 50 checked-in migrations align 1:1 with the 50 live ledger entries by version + name, and `20260929050000_create_user_workout_routines` remains the sole repository-only pending migration.

### Known Limitations

Routine is not deployed live. Current connector-only session cannot perform or claim a version-preserving CLI deployment. Live Routine deployment remains a separate explicitly authorized step.

### Final Status

`VALIDATED`


## Post-merge verification

PR #464 merged as `9e278f6830a7d756bb2401ea20dfe5e3a28697af`. Fresh post-merge read-only verification confirmed the renamed Program migration on `main`, canonical Supabase docs updated, live migration count still 50, live Routine table still absent, and exact repo/live parity of 50 applied migrations plus one pending Routine migration. No hosted deployment was performed by the reconciliation.
