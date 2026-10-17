# GitHub #569 — M2C Legacy Rename Retirement Preflight

**Status:** In progress — source PR preflight, no hosted deployment or migration.
**Primary owner:** Supabase/Postgres security; linked to Workout identity.
**Affected platforms:** Supabase test harness and GitHub CI only.

## Owner Approval and Scope Boundary

**Trigger:** Existing #569 approved Move feature, nested security prerequisite.
**Approval evidence:** Owner confirmed on 2026-10-17 that **no real users exist**, and explicitly authorized advancing toward working Move. This is a statement about the current product audience, not independently verified proof of no test/dev clients or that an app build was never installed.
**In scope:** CI-only transaction-scoped simulation of retiring authenticated direct Routine `UPDATE(name)`, with negative/positive protected-RPC tests and one CI step.
**Out of scope:** NO hosted GRANT revoke, SQL migration generation/apply, new tables/columns, automatic forced update, M1 Move deployment/grant, Move UI, Program Delete, canonical My Program, app release.

## Active Handoff

- **Planning:** GitHub #569 Open, Linear TNYX-81 broad W4 Backlog; #568 / #475 default Program identity still independently gated.
- **Repository:** `main@3f118d2ac4c3ec31796e4389c3797548ba5d9472` (PR #588 M1 dormant, PR #591 M2B and #592 docs merged).
- **Source branch:** `tnyx/issue-569-m2c-legacy-rename-preflight`, created from verified main.
- **Implementation:** New transactional SQL negative matrix in `supabase/tests/database/`; added CI job step to existing Supabase DB workflow. No migration or runtime code change.
- **Validation:** Await exact-head Supabase Database CI disposable migration replay, SQL matrix, race tests, lint baseline, required commit attribution guard.
- **Windows local repo:** `G:\projects\Tio-World` inaccessible via GitHub connector; no local git/CLI/device tests claimed.
- **Current host:** Supabase project `oykupyiitspujzpwwvuj` 62 applied migrations, M1 RPC absent; authenticated direct `UPDATE(name)` allowed, direct `UPDATE(program_id)` denied; protected 7-arg Rename RPC available.
- **Review owner:** Independent SQL/security review / owner-directed manual gate after CI.
- **Next exact step:** Finish preflight CI, then **generate** the actual follow-on versioned migration using `supabase migration new retire_legacy_routine_name_update` on a supported Supabase CLI, without inventing a timestamp filename. Refactor old compatibility-dependent tests and legacy two-session fixtures in that **separate** cutover PR; do not deploy or enable Move until full CI and explicit reviewed gate.

## Verified Architecture and Risk

- Older installed mobile binary issues Data API `UPDATE(name)` with `user_id` + `routine_id` and no source Program/revision. A stale A screen can rename after A→B Move, violating Program-scoped CAS.
- Current merged `SupabaseRoutineRepository.rename(id,name)` fails closed; protected `renameVersioned` reuses `update_user_workout_routine_with_composition`, and canonical composer uses that RPC.
- Live `authenticated` grant is **column-level** only (`UPDATE(name)`), not broad `UPDATE`; remove only the narrow legacy grant and retain `SELECT`, metadata-column `INSERT`, protected Update/Composition RPCs, and owner RLS.
- Production migration remains blocked until supported rollout/dev-install impact and rollback are deliberately accepted, even though owner reports no real users.
- Older SQL matrices `tnyx_78`, `tnyx_81`, `tnyx_526`, and `tnyx_569` deliberately expect old Rename success or use it in two-session races. Do not silently change them in this preflight. Actual cutoff follow-up must rewrite those expected outcomes plus concurrency coverage before replay can go green.
- Server-side authorization must never trust mutable `user_devices.app_version/app_build` values or client-supplied headers.
- Rollback order after Move activation: disable Move first; never reinstate direct legacy Rename while Move is active.

## Security Acceptance (for CI preflight)

- [ ] No authenticated table-wide or column-level direct UPDATE privileges survive temporary revoke.
- [ ] Direct old Rename fails 42501 and leaves Name/revision intact.
- [ ] Protected name-only RPC and identical token replay work, stale/new token and wrong Program fail.
- [ ] Old composition RPC, Routine metadata INSERT/SELECT remain usable.
- [ ] Cross-user protected Update fails without exposing another user.
- [ ] Move EXECUTE stays revoked.
- [ ] ROLLBACK restores original grants, data and current CI baseline.
- [ ] Entire existing Supabase Database CI remains green.

## Handoff

**No production change.** Subsequent migration filename MUST be created by the Supabase CLI on a supported workspace. No approval to turn on Move UI or hosted DB migration is implied by this preflight.
