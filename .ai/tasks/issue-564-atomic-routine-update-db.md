# GitHub #564 — Atomic Routine Name + Composition database contract

**Status:** In progress — implementation and disposable SQL validation, no hosted deployment
**Primary owner:** Supabase database / Workout security boundary
**Affected platforms:** Supabase Postgres; existing Flutter and watch behavior unchanged.

## Approval and scope
**Owner approval:** Owner 2026-10-16 `Go`, directly after explicit proposal for `last_routine_update_request_hash bytea` nullable 32-byte SHA-256 digest plus Routine-wide revision/token semantics, legacy rename trigger and versioned authenticated RPC. This is exact database-shape approval, **not production deployment or PR merge**.
**In scope:** ONE additional nullable `user_workout_routines.last_routine_update_request_hash bytea` column, semantic aggregate revision for name/sets, narrowly scoped legacy direct-name trigger, separately named atomic Update RPC, SQL tests and test workflow integration.
**Out of scope:** Flutter Name field and 3-dot Rename removal, routine Delete #526, notes/rest, workout session/history, backend service, privileged mobile API, new table, changing old four-argument signature, revoking old client grants, hosted SQL apply, merge or release.

## Active handoff
**Planning:** [GitHub #564](https://github.com/im-tnyx/tio-world/issues/564) Open / [Linear TNYX-81](https://linear.app/tnyx/issue/TNYX-81) Backlog (broader blockers TNYX-78/TNYX-80); separate reviewed Draft docs contract [PR #575](https://github.com/im-tnyx/tio-world/pull/575), do not modify its branch.
**Implementation owner:** This GitHub-connected session, database-only branch `security/issue-564-atomic-routine-update-db`, from `main@ca02216936e146e9b0553e440d91b777c24d4d25`.
**Review owner:** Independent Codex after CI.
**Working tree:** GitHub remote branch; user's local Windows worktree not remotely inspectable. Prior owner PowerShell checkout `7f05def9`, now behind verified `main`.
**Current blocker:** Cannot assert local/disposable DB tests until CI actually runs. No production migration/deploy.
**Review findings:** Independent PR #575 design P1s were corrected and 2/2 threads resolved: replay before stale CAS; DB-first additive old-client rollback compatibility.
**Next:** Add incremental SQL migration + disposable SQL matrix and CI matrix entry. Run exact-head Supabase DB CI, Codex review, fix findings. Keep Draft until approval.

## Verified baseline / boundaries
- Live read-only Tio-world Supabase `oykupyiitspujzpwwvuj`, 2026-10-16: exactly eight Routine parent columns including `composition_revision` and raw `last_composition_mutation_id`; only `updated_at` trigger; authenticated can UPDATE(name), not revision/token; existing 4-arg composition and 5-arg Create RPC authenticated-only SECDEF.
- `supabase/migrations/20261015180000_guard_routine_custom_type_at_save.sql`: 4-arg RPC locks owner row, compares same token + normalized persisted content **before** revision conflict, validates archived/type-changed Custom Exercises and rich Set shape, deletes/reinserts composition on new save and bumps revision/token.
- Existing `supabase/tests/database/tnyx_509_routine_composition.test.sql` and `.github/workflows/supabase-db-ci.yml` establish disposable local DB test pattern.
- `RoutineRepository.rename` in Workout feature calls owner-filtered direct Data API UPDATE(name); this does not bump revision today.

## Design
**One parent aggregate revision:** direct old Name changes under authenticated Data API bump Routine revision + clear replay token/hash; old 4-arg composition mutation remains callable, raw client UUID unchanged, and invalidates any prior new-RPC fingerprint. Use a narrow private BEFORE UPDATE trigger to cover old writes; prevent double revision bump for new SECDEF combined writes that supply a distinct new request hash.
**New API:** `update_user_workout_routine_with_composition(p_routine_id uuid,p_program_id uuid,p_expected_revision bigint,p_expected_name text,p_client_mutation_id uuid,p_name text,p_exercises jsonb)`, intentionally separately named, no overloaded PostgREST signature. `p_name IS NULL` leaves Name untouched; `p_exercises IS NULL` leaves composition untouched; `[]` is actual empty replacement.
**Same-token order:** validate auth/owner and lock, build canonical request digest, if same stored UUID compare 32-byte full-original-request SHA-256 and requested post-state (including composition using unchanged old 4-arg replay validation) **BEFORE** expected revision/Name CAS. Mismatch = conflict; matching retry returns committed revision.
**New request:** check expected revision/Name CAS. If Sets included call the original four-arg secure composition RPC **inside same transaction** to reuse all archived/type/legacy validations, followed by Name/fingerprint update; if Name only never touch child Set data, update revision/token/name/hash together. No UI client two-write sequence.
**Rollout:** additive DB-first; never revoke old 4-arg RPC or UPDATE(name) during overlap, never roll incompatible DB schema back after a new mobile app relies on it. Old direct-name client may overwrite a later Name until explicit old-client retirement; any such update invalidates the new token and bumps revision for fresh readers.
**Rejected:** duplicating 500+ line composition validator; repurposing raw client UUID as digest; separate mutation history table; client two sequential commits; privileged mobile key; runtime UI redesign.

## Validation gates
- [ ] SQL migration replays from scratch in disposable Supabase DB CI.
- [ ] Owner A/B and cross-program fail-closed; signed-out/anon/restricted grants.
- [ ] New name-only (Set identity untouched), Sets-only, combined atomic, expected revision/Name stale, exact/different same UUID replay, empty array, malformed request.
- [ ] Old direct Name changes revision/token/hash; old composition clears hash and honors old replay, old Create stays compatible; no double bump on combined Update.
- [ ] Transaction rollback on invalid Custom/type/rich Set; preserved Name and Set identities if failure.
- [ ] Two-session old/new write race and statement-order gate where practical.
- [ ] No new RLS exposure/privilege escalation; public function EXECUTE restricted.
- [ ] Exact-head independent Codex and owner review, PR not merged/deployed without explicit go.

## Current QA and final handoff
No executed tests, CI, migration or deployment claimed at task start. Changes must be summarized with exact HEAD, changed paths, validated gates, unresolved issues. Status **IN PROGRESS**.
