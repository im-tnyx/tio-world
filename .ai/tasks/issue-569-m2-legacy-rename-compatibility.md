# GitHub #569 — M2 Legacy Rename Compatibility and Safe Move Preparation

**Status:** M2B implementation and regression coverage committed in Draft PR #591; CI PASS on previous code HEAD `a5c0507e` (run #39029400984), latest-head tests and independent review pending. Old-client compatibility retirement and Move activation remain blocked and NOT implemented.
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
- **Working tree / PR:** Local Windows `G:\projects\Tio-World` cannot be inspected from this connector-only session; do not claim a clean local tree. GitHub #591 is OPEN/Draft on the M2 branch and awaits independently verified review; earlier no-open-PR observation is historical.
- **Hosted runtime:** Tio-world Supabase project `oykupyiitspujzpwwvuj` has 62 migrations through `20261016220000`; source contains 63 including M1 `20261017100000`. Hosted Move RPC count zero. Authenticated direct `UPDATE(name)` allowed; direct `UPDATE(program_id)` and revision UPDATE denied.
- **M1 permission:** Merged function revokes EXECUTE from `PUBLIC`, `anon`, `authenticated`, `service_role`. It remains dormant even if that reviewed migration is separately deployed.
- **Validation:** GitHub Flutter CI run #39029400984 **SUCCESS on code SHA `a5c0507e`** (Analyze/Dart, app-workout, nutrition-onboarding, core-wear, aggregate gate). Later mutation-barrier regression commits have their own newer CI; exact latest-head PASS must be verified separately. Live Supabase read-only permission/advisor inspection performed; no Supabase migration replay or device tests.
- **Current blocker:** A server-enforced old-client retirement/compatibility decision is required before any Move activation. No minimum-supported-version enforcement deployed.
- **Next exact step:** Verify exact-head Flutter CI after recent unconfirmed-Rename guard and handoff corrections; independently review PR #591 and resolve any in-scope findings before Ready for Review. Do not merge without explicit owner instruction; do not add activation GRANT or revoke legacy UPDATE(name).

## M2B implementation checkpoint (2026-10-17)

- Source added to the same previously approved M2 Draft PR #591 (not a separate PR, single implementation owner): `apps/features/workout/lib/src/domain/repositories/routine_repository.dart`, `apps/features/workout/lib/src/data/repositories/supabase_routine_repository.dart`, `apps/features/workout/lib/src/presentation/library/routines/program_routines_controller.dart`, `apps/app/lib/app/composition/workout_providers.dart`, and two focused Workout tests.
- `RoutineMetadataRevision` keeps the list-time version and opaque app-owned `loginCycleId` separate from canonical shared `Routine`. `RoutineVersionedRenameRepository` is an opt-in capability for legacy metadata controllers; unsupported fakes can list but do not authorize Rename.
- New-client Supabase metadata transport now only **SELECTs** owner Program Routines with revision and supports INSERT. The old unversioned `SupabaseRoutineRepository.rename(id,name)` **fails closed**; no Flutter Data API direct UPDATE(name) is issued from it.
- Protected metadata Rename delegates the frozen `RoutineAggregateUpdate` name-only command to the **existing** `SupabaseRoutineCompositionRepository.updateAggregate` and server seven-argument name-aware RPC. The controller freezes list-time Program, revision, expected Name and login cycle; a confirmed result must match the RPC-confirmed revision and an owner-scoped read-back. Reading the desired Name after an unknown write is **not sufficient** success proof.
- Existing app auth provider supplies the **live** `AuthSessionAuthenticated.session.loginCycleId`; list and dispatch reject stale/changed cycles, including logout/relogin by the same owner. No app visual/layout change.
- Uncertain legacy metadata Create reconciliation now only accepts the original stable UUID with the **same** persisted Name; it never blindly calls Rename to overwrite a concurrently edited name. A mismatch stays unconfirmed and requires explicit editor lifecycle handling.
- Focused tests added/updated: no direct metadata Rename, malformed revision/foreign Program, auth-owner and login-cycle change, freeze and delegate name-only RPC, stale source Program, A→B→A, unknown write confirmation, post-Create changed Name, zero-row and owner read-back.
- **Validation status:** GitHub Flutter CI #39029400984 **PASS on `a5c0507e`**. Current head moves for uncertainty gating and handoff updates require a fresh full CI result; no latest-head PASS claim. Independent reviewer approval outstanding.
- **M2B audit fix:** An ambiguous metadata Rename response now records a Routine-scoped in-process uncertainty barrier. A refreshed Program list is *not* proof the prior token committed or did not commit; the controller will not mint a second token for that Routine during its lifetime. Focused test covers refresh + attempted second Rename. Existing live old-client Data API permission is untouched; this is not a cross-process or old-app security guarantee.
- **Review/security evidence:** Hosted Tio-world still permits old authenticated `UPDATE(name)` and denies direct `UPDATE(program_id)`; protected seven-argument RPC is available, Move RPC absent. Supabase Advisor retains nine existing intentional/reviewable authenticated SECURITY DEFINER warnings and one INFO on private retired-Routine-ID table (see [official Supabase warning guidance](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable)). No new hosted security finding or changed authorization by this PR.
- **Documentation-only correction:** Fixed literal escaped newline that accidentally joined two rows of the `.ai/tasks/README.md` task index. Canonical `docs/data/SUPABASE_STRATEGY.md` currently claims 62/62 migration alignment although code M1 is 63 checked-in / 62 live; existing Pre-P9 reconciliation owns that wider canonical docs drift, not this M2 client-code review.
- **Still NOT done:** client-version retirement, server-side direct UPDATE(name) denial, hosted M1 deploy, Move EXECUTE, Move UI, new/default Program actions, old-client on-device adoption tests.

## 1. Historical Pre-M2 Source Baseline and Failure Reproduction (superseded by M2B current source above)

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
- [x] **M2B (source authored; latest-head CI/review gate pending):** minimal protected metadata Rename read/write integration, no capability activation, updated fakes and focused Flutter tests. Audit/record whether metadata Create reconciliation is still runtime reachable; do not discard its correctness without evidence.
- [ ] **M2C (separately owner-gated):** supported deployed old-client cutoff and compatibility policy; reviewed server enforcement removing old direct `UPDATE(name)` when safe.
- [ ] **M2D (separately authorized):** apply/verify dormant M1 migration then review conditional Move EXECUTE activation, negative/race SQL and exact-head CI. Existing Program Flutter selector is a later bounded slice.
- [ ] **Later:** #568 canonical My Program, atomic `+ New Program → Create & Move`, #567 Delete Program.

## 4. Findings and Merge/Release Gates

| ID | Severity | Status | Finding / disposition |
|---|---|---|---|
| M2-P2-01 | P2 activation blocker | Open | Legacy authenticated UPDATE(name) can mutate a Routine moved from stale Program context. Server grant unchanged until compatible retirement is expressly approved. |
| M2-COMP-01 | Contract gate | Resolved in PR, pending exact-head validation | Versioned metadata list now binds original owner-scoped Program, revision, expected name and app login-cycle to the protected RPC. A→B→A stale revision and cycle-change tests included. |
| M2-OPS-01 | Process | Open | Main has 63 SQL files while live has 62; M1 source is merged but un-deployed. Do not mix up code merge, hosted deployment and client activation. |
| M2-OPS-02 | Process | Open | Local Windows git status, device/client adoption and supported-version evidence not available through connector-only audit. |
| M2-P2-02 | P2 client retry/uncertainty | Resolved in source, CI/review pending | Previous controller allowed a fresh mutation token after ambiguous Rename; current controller stores Routine-scoped in-process uncertainty gate and focused regression prohibits subsequent rename even after refresh. |

**Readiness:** M2B review gate in progress; **NO-GO** for merging PR #591 until exact-head CI and independent review; **NO-GO** for old-client grant retirement, hosted M1 deployment and Move activation in this slice.

## 5. Handoff

**Changed files at this checkpoint:** `.ai/tasks/README.md`, `.ai/tasks/issue-569-routine-move-existing-program-db.md`, this M2 brief; Workout domain metadata interface, Supabase metadata repository, Program Routines controller, focused repo/controller tests, and app Workout provider. No schema, grants, visual UI, deployment or Linear status modified.
**Validation:** GitHub full Flutter CI PASS at older source SHA `a5c0507e`, current exact-head pending; Supabase live read-only grants/advisors verified. Windows local git/device tests unavailable.
**Next owner:** Same M2 implementation owner through final CI; then independent GitHub reviewer for PR #591; GitHub #569 stays Open and old-client/Move activation remains a later approved slice.
