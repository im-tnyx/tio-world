# GitHub #569 — M2 Legacy Rename Compatibility and Safe Move Preparation

**Status:** In progress, bounded audit/contract handoff only. Current-client implementation, permission retirement and Move activation are NOT complete.
**Primary owner:** GitHub-connected M2 implementation session (single implementation owner).
**Affected platforms:** Workout metadata repository/controller, app Auth boundary, and future Supabase authorization gate. No UI or hosted database changes in this checkpoint.

## Owner Approval and Scope Boundary

**Trigger:** Existing #569 independently scoped next Move slice.
**Approval status:** Owner said “go start” on 2026-10-17 after the read-only M2 audit; this authorizes starting the bounded compatibility work, **not** an unapproved production compatibility cutoff, live migration, Move EXECUTE, UI expansion or deployment.
**In scope:** Reconcile M1 post-merge; inspect retained direct Rename callers, old-client behavior, existing seven-argument protected Update, revision/token/read guards; define and subsequently implement the minimum current-client compatibility adapter with focused tests in its own reviewable source slice.
**Non-goals:** Direct UPDATE(program_id); revoke UPDATE(name) now; publish Move RPC; new table/column; create-new-Program/Move, canonical My Program, Delete Program, Routine picture/duplicate; UI redesign; services/api; speculative feature-flags infrastructure; production writes.

## Active Handoff

- **Planning:** GitHub #569 Open; Linear TNYX-81 Backlog and TNYX-267 Backlog. These are broader trackers, not completed W4/W6B acceptance.
- **Implementation owner:** GitHub-connected M2 session; no simultaneous source owner is known.
- **Review owner:** Independent reviewer required before merge; no approval inferred.
- **Repository:** GitHub main verified `5a9e9f46d2d114ff6eefac7aeb9b5341f24e6a65` (merged PR #588). Branch: `tnyx/issue-569-m2-rename-compatibility` from this SHA.
- **Working tree:** Local Windows `G:\projects\Tio-World` cannot be inspected from this connector-only session. GitHub API shows no open PR at audit time; do not claim a clean local tree.
- **Hosted runtime:** Tio-world Supabase project `oykupyiitspujzpwwvuj` has 62 migrations through `20261016220000`; source contains 63 including M1 `20261017100000`. Hosted Move RPC count zero. Authenticated direct `UPDATE(name)` allowed; direct `UPDATE(program_id)` and revision UPDATE denied.
- **M1 permission:** Merged function revokes EXECUTE from `PUBLIC`, `anon`, `authenticated`, `service_role`. It remains dormant even if that reviewed migration is separately deployed.
- **Validation:** Read-only API/source/database introspection only. No Flutter/Dart, GitHub CI, migration replay or device tests run during this M2 checkpoint.
- **Current blocker:** A server-enforced old-client retirement/compatibility decision is required before any Move activation. No minimum-supported-version enforcement deployed.
- **Next exact step:** Prepare a separate minimal current-client protected metadata Rename code/test diff, then exact-head Flutter CI and independent review. Do not add activation GRANT or revoke legacy UPDATE(name).

## 1. Current Source and Failure Reproduction

- `SupabaseRoutineTableGateway.renameRow()` runs Data API `.update({'name': name}).eq('user_id', userId).eq('id', routineId)` with no source Program or aggregate revision.
- `SupabaseRoutineRepository.rename(id,name)` forwards this call. `ProgramRoutinesController.rename()` invokes it; `_reconcileCreate()` may also invoke it after an ambiguous metadata Create.
- The current saved Routine 3-dot uses the canonical full Edit composer and protected `update_user_workout_routine_with_composition` RPC; the legacy metadata Rename controller is **not** that active menu action. Do not re-enable an orphan old Rename UI.
- `RoutineRepository.list()` returns `Routine(id,programId,name)`; `SupabaseRoutineTableGateway.listRows()` selects only `id,program_id,name`. This metadata contract has **no list-time revision**, a material issue for stale A→B→A protection. Existing composition snapshot separately carries a versioned read.
- Existing seven-argument RPC `update_user_workout_routine_with_composition(routine_id,program_id,expected_revision,expected_name,mutation_id,name,exercises)` supports a **name-only** request when `exercises=null`, checks owner/Program and revision/name and uses a request hash for last exact retry. Its current Flutter aggregate adapter already has bounded unknown-result reconciliation.
- M1 disposable SQL test `tnyx_569_existing_program_routine_move.test.sql` deliberately demonstrates the **known P2**: after a verified Move A→B and source A deletion, old `UPDATE(name)` still changes R in B. A passing known-exposure regression is NOT Move activation safety.
- Legacy Update trigger increments the revision *after* unauthorized-by-program context Rename, so it does not fix the moved-source stale write.
- Current `docs/backend/API_LIFECYCLE.md` and `docs/planning/FEATURE_ROLLOUT.md` are policy-only, not deployed version enforcement.
- New `RoutineMetadataCard` has an optional `onMove` presentation slot; Program Detail/expanded Library have no move callback wired. Keep this unchanged.

## 2. Compatibility Design Gates Before Implementation

1. **Preserve list-time context:** A protected metadata edit needs a frozen owner/login-cycle, RoutineId, source ProgramId, server revision, original name and new name. A pre-write *fresh* revision lookup alone must not silently turn a stale A→B→A UI into an authorized edit. Decide the narrowest feature-owned read contract; avoid adding database columns or a second canonical Routine model.
2. **Reuse existing server RPC:** Prefer `update_user_workout_routine_with_composition` with `p_exercises=null` over a new RPC. Review whether existing `RoutineAggregateUpdateRepository` transport/reconciliation can be reused without duplicating retry logic. Never route protected Rename through direct `UPDATE(name)`.
3. **Create unknown outcome:** Treat `_reconcileCreate()` separately. Preserve its stable pending Routine UUID; do not overwrite a different latest aggregate mutation, leak another account, convert uncertainty to a false success or silently create a second row.
4. **Session and conflict safety:** Check owner/login cycle before/after each async read/write; fail closed on source mismatch, deleted/foreign row, revision mismatch, in-flight other edit, session switch, offline and ambiguous response. Retry only the exact frozen mutation token after authoritative verification.
5. **Old installed clients:** A new Flutter implementation **does not** revoke old Data API grants. Record explicit owner decision on minimum-supported-client/cutoff and a server-authoritative enforcement approach (not client headers or hiding a button). The cutoff and server GRANT/REVOKE live in **another approved reviewed gate**.
6. **Current surfaces:** Do not restore legacy Rename-only UI. Preserve canonical full Edit and Routine 3-dot geometry. No speculative Flutter Move capability before backend/compatibility gates.
7. **Test gates:** Owner+Program+revision+expected-name CAS; pre-move stale source; A→B→A revision ABA; exact-token retry and superseded unknown; duplicate/foreign identity, session swap, post-unknown Create reconciliation, two-device race; existing Edit/Create regression and UI unchanged. SQL negative regression must switch from known exposure to denial before activation.

## 3. Sequencing

- [x] **M2A:** fresh `main`/PR/Linear/source/live permissions inspection; post-M1 merge-truth handoff.
- [ ] **M2B (next source slice):** minimal protected metadata Rename read/write integration, no capability activation, updated fakes and focused Flutter tests. Audit/record whether metadata Create reconciliation is still runtime reachable; do not discard its correctness without evidence.
- [ ] **M2C (separately owner-gated):** supported deployed old-client cutoff and compatibility policy; reviewed server enforcement removing old direct `UPDATE(name)` when safe.
- [ ] **M2D (separately authorized):** apply/verify dormant M1 migration then review conditional Move EXECUTE activation, negative/race SQL and exact-head CI. Existing Program Flutter selector is a later bounded slice.
- [ ] **Later:** #568 canonical My Program, atomic `+ New Program → Create & Move`, #567 Delete Program.

## 4. Findings and Merge/Release Gates

| ID | Severity | Status | Finding / disposition |
|---|---|---|---|
| M2-P2-01 | P2 activation blocker | Open | Legacy authenticated UPDATE(name) can mutate a Routine moved from stale Program context. Server grant unchanged until compatible retirement is expressly approved. |
| M2-COMP-01 | Contract gate | Open | Metadata Routine list omits aggregate revision. Full CAS and A→B→A must be solved before current-client adapter merge. |
| M2-OPS-01 | Process | Open | Main has 63 SQL files while live has 62; M1 source is merged but un-deployed. Do not mix up code merge, hosted deployment and client activation. |
| M2-OPS-02 | Process | Open | Local Windows git status, device/client adoption and supported-version evidence not available through connector-only audit. |

**Readiness:** M2 planning/audit in progress; **NO-GO** for old-client grant retirement, hosted M1 deployment and Move activation in this slice.

## 5. Handoff

**Changed files at this checkpoint:** this bounded M2 brief and a targeted stale M1 task index/handoff correction. No production source, schema, grants, UI, or Linear status modified.
**Validation:** GitHub and hosted Supabase read-only checks are verified; code/tests were not executed.
**Next owner:** M2 implementation owner to take M2B in a separately reviewable exact-head source change; independent reviewer to verify safety before merge.
