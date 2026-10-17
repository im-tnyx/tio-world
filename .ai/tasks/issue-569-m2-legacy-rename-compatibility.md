# GitHub #569 — M2 Legacy Rename Compatibility and Safe Move Preparation

**Status:** **M2B MERGED** via [PR #591](https://github.com/im-tnyx/tio-world/pull/591), squash `main@c12ea127e4cc74ebdde08b559bef04216b9b9f6b` (2026-10-17); exact-merge [Flutter CI #39038295713](https://github.com/im-tnyx/tio-world/actions/runs/39038295713) **SUCCESS** (all five jobs). Four inline threads resolved; owner-directed manual review recorded, **no independent GitHub `APPROVED` review**. This is a source merge, not a mobile release or hosted Supabase deployment. M2C older-client cutoff, M1 hosted deployment and Move activation remain separately gated.
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
- **Review owner:** M2B completed after documented owner-directed manual security/code review, not independent GitHub `APPROVED` review. Codex usage-limit failure remains a historical limitation.
- **Repository:** Squash `main@c12ea127e4cc74ebdde08b559bef04216b9b9f6b` (parent M1 merge `5a9e9f46`). Historical source branch `tnyx/issue-569-m2-rename-compatibility` remains on remote; cleanup not performed.
- **Working tree / PR:** PR #591 **closed/merged**; local Windows `G:\projects\Tio-World` is not accessible here, so no local status/pull/prune verification. Original remote source branch remains.
- **Hosted runtime:** Tio-world Supabase project `oykupyiitspujzpwwvuj` has 62 migrations through `20261016220000`; source contains 63 including M1 `20261017100000`. Hosted Move RPC count zero. Authenticated direct `UPDATE(name)` allowed; direct `UPDATE(program_id)` and revision UPDATE denied.
- **M1 permission:** Merged function revokes EXECUTE from `PUBLIC`, `anon`, `authenticated`, `service_role`. It remains dormant even if that reviewed migration is separately deployed.
- **Validation:** Post-merge Flutter CI #39038295713 **SUCCESS** at `main@c12ea127` (all five jobs); final pre-merge #39036088215 SUCCESS, including required attribution guard. Older intermediate failed/cancelled runs remain historical. Supabase read-only: 62 applied vs 63 checked-in migrations, old authenticated direct `UPDATE(name)` still granted, no deployed Move RPC. No deployment or device QA.
- **Current blocker:** A server-enforced old-client retirement/compatibility decision is required before any Move activation. No minimum-supported-version enforcement deployed.
- **Next exact step:** M2C planning/owner decision on supported deployed versions, adoption evidence, server-enforced old-client Rename cutoff, user impact/forced-update and rollback plan. No cutoff threshold or server enforcement approved. Do not revoke `UPDATE(name)` until safety validation, explicit approval and independently gated deployment. M1 migration, Move EXECUTE and Flutter UI activation remain separately gated.

## Post-merge source / hosted release boundary (2026-10-17 — current)

- GitHub PR #591 is **merged** at `main@c12ea127e4cc74ebdde08b559bef04216b9b9f6b`; all 10 scoped files landed, with [post-merge Flutter CI #39038295713](https://github.com/im-tnyx/tio-world/actions/runs/39038295713) **SUCCESS**.
- Four native review threads resolved; the owner requested manual security/code review and guarded merge. **No GitHub independent `APPROVED` review** occurred. The previous Codex usage-limit failure is neither a clean review nor a finding. GitHub accepted normal expected-head squash without force.
- Hosted Tio-world Supabase remains at 62 migrations vs 63 repository SQL; M1 Move RPC is absent live; older clients still have authenticated direct `UPDATE(name)` and cannot directly `UPDATE(program_id)`. App distribution, minimum-client cutoff and Move activation were not performed.
- **M2C decision required:** establish supported client versions, rollout/adoption evidence, server-enforced restriction of legacy Rename before Move, forced-upgrade user impact, rollback and negative/security tests. Do not base security authorization on an untrusted client-declared version header. M1 deploy, Move EXECUTE grant and Flutter Move UI are separate gates.
- Older sections mentioning PR #591 Draft/Ready for Review, pending CI or merge NO-GO are **historical pre-merge checkpoints** and superseded by this section. No local Windows sync, remote branch deletion or product runtime change was made.

## Independent inline review follow-up (2026-10-17, validated source `f17fd73`)

- **P2 #4302590466** (resolved): the metadata Create pending UUID was incorrectly reusable after logout/relogin by the same owner. The controller now freezes pending UUID to the originating login cycle and binds even an empty listed Program snapshot to that cycle. A stale cycle clears pending identity and requires another owner-scoped load before any new Create; same-name immediate retry issues no second old-UUID INSERT. Added the P2 targeted same-name retry/relogin regression. This is legacy metadata Create compatibility, not a change to current canonical Create composer.
- **P3 #4302590472** (resolved): corrected canonical `docs/screens/routine-library.md` to describe the new-client versioned protected Rename while distinguishing the **still-present hosted old-client direct `UPDATE(name)` GRANT** and the un-deployed Move RPC. No false distributed-release claim.
- Both [PR #591](https://github.com/im-tnyx/tio-world/pull/591) native threads received replies with commit/test evidence; **0 unresolved** verified after exact-head [Flutter CI #39031276265](https://github.com/im-tnyx/tio-world/actions/runs/39031276265) SUCCESS and attribution guard PASS. GitHub PR transitioned Draft → Ready for Review, **not merged**. Reviewer submissions are COMMENTED only, not APPROVED.
- Supabase hosted grants, applied migration count and security Advisor rechecked read-only; no new migration/GRANT/deploy. GitHub `main@5a9e9f46` unchanged; compare `ahead 17, behind 0` before this **docs-only** handoff update; branch-protection API returned 403 and visible rulesets list empty (not proof of no required policy).
- Linear TNYX-81 received a scoped progress comment; broad W4/W6B statuses remain Backlog. A separate owner-approved server-side old-client cutoff is mandatory before Move activation.

## P2 Auth/Privacy Re-review (2026-10-17)

- **P2 inline #4302652034 (resolved):** Reviewer proved that a login-cycle/account switch plus a failed Rename verification read republished the prior session's Routine metadata as `ready`. Fixes on `edd766b7` and `45b45fb`: the optional versioned metadata repository now exposes live trusted `activeOwnerId` as well as `activeLoginCycleId`; controller freezes both at list time and checks both before and after Create/Rename.
- On mismatch the controller clears loaded Routine rows (publishes `loadFailed`), pending metadata Create UUID/cycle and cached revisions. On unknown network result **within the same owner+cycle**, preserve existing visible state and the no-fresh-token uncertainty barrier. Owner/auth read failures are fail closed even if the previous list had content.
- Focused Flutter tests **actually simulate** post-RPC-dispatch cycle or account switch followed by a failing verification read; additional tests cover same-session failed read + uncertainty barrier, and account switch on Create completion. This fixes a **legacy metadata controller** privacy exposure; production canonical full Edit composer remains separate and is not reconfigured.
- Exact changed-source [Flutter CI #39033278931](https://github.com/im-tnyx/tio-world/actions/runs/39033278931) SUCCESS (all five jobs). Reviewer comment replied with exact SHA and evidence, native thread resolved. Existing two earlier P2/P3 threads remain resolved; **3 total, 0 unresolved**.
- GitHub Codex review summary for older `f17fd73` reports `failed` because usage limits were reached. This is neither a finding that the current code failed nor a valid clean CODEX/APPROVED review. Required-vs-supplemental status cannot be established from branch protection endpoint (403). A qualified independent review/branch-policy disposition is still needed before merge.
- Read-only hosted Supabase: 62 applied migrations through `20261016220000`; old authenticated `UPDATE(name)` allowed, direct `UPDATE(program_id)` denied, `composition_revision` SELECT + protected update RPC available; Move RPC absent. No hosted write, deploy or Move grant.

## Additional P2 uncertain-Create replay review (2026-10-17)

- **New P2 inline #4302707588**, found during the final CI/re-review after earlier three threads resolved: `load()` used to invoke `_invalidateSessionContext()` on every failed list read. A transient network failure **within the same owner and login cycle** cleared an ambiguous metadata Create UUID even though the database INSERT could have committed, allowing a later fresh UUID and duplicate logical Create.
- **Fix source `cad7c0aa` + analyzer-scope correction `c1a06627`:** On list failure, check the previously frozen authenticated owner AND login cycle. If unchanged, clear visible rows and revisions, publish `loadFailed`, but preserve original pending Create UUID/cycle for authoritative reconciliation. Only auth revocation/account/cycle change clears pending identity. A subsequent successful owner read either proves the persisted row and safely closes pending, or proves the ID absent and permits one exact-UUID retry.
- **Focused tests:** ambiguous Create with committed INSERT and lost response followed by a *second* same-session read failure and recovered owner read must have **one** persisted UUID/write; ambiguous Create before INSERT then transient read failure/recovery must reuse the exact same UUID for the eventual single INSERT. Prior post-dispatch Rename auth-change P2 tests remain.
- Intermediate run [#39034182281](https://github.com/im-tnyx/tio-world/actions/runs/39034182281) reported Analyzer `undefined_identifier` for a try-local `versioned` variable used in `catch`; source fixed by moving its declaration to `load()` method scope in `c1a06627`. No claim of green on `cad7c0aa`. Exact-head latest CI and review resolution **pending** when this handoff entry was written.
- No new database tables, grants, RPC, UI, Flutter route or Move activation. Legacy client `UPDATE(name)` remains server-permitted pending separately approved compatibility retirement.

## Final focused owner-bound identity audit (2026-10-17)

- Source review found one additional narrow edge case: when `load()` succeeded under a different authenticated owner whose login-cycle marker happened to equal the prior marker, it previously preserved the previous owner's frozen pending Create UUID. Owner-scoped Supabase reads remain isolated, but mutation identity must be owner-bound independently of cycle-marker uniqueness.
- Commit `1dba0e51` adds an explicit `_loadedOwnerId != owner` check when reconciling pending Create after a successful owner-scoped reload. Different owner invalidates the previous pending UUID even if cycle marker matches. Focused Workout test asserts prior owner's uncertain UUID `41` cannot be reused by the new owner; fresh Create allocates `42`. Same-owner/cycle failed list reads retain the prior UUID as documented.
- [Exact changed-source CI #39035723754](https://github.com/im-tnyx/tio-world/actions/runs/39035723754): all five Flutter/Dart CI jobs SUCCESS. No new backend RPC/schema/grant, deployment, UI or Move behavior.
- GitHub independent APPROVED review is still absent (COMMENTED only). `.github/CODEOWNERS` has placeholder comments, not assigned real maintainers; GitHub branch-protection REST returned 403, so required-check policy cannot be asserted despite seven passing check-runs and `mergeable_state=clean`. PR remains ready for reviewer/maintainer disposition, not owner-authorized merge.

## M2B implementation checkpoint (2026-10-17)

- Source added to the same previously approved M2 Draft PR #591 (not a separate PR, single implementation owner): `apps/features/workout/lib/src/domain/repositories/routine_repository.dart`, `apps/features/workout/lib/src/data/repositories/supabase_routine_repository.dart`, `apps/features/workout/lib/src/presentation/library/routines/program_routines_controller.dart`, `apps/app/lib/app/composition/workout_providers.dart`, and two focused Workout tests.
- `RoutineMetadataRevision` keeps the list-time version and opaque app-owned `loginCycleId` separate from canonical shared `Routine`. `RoutineVersionedRenameRepository` is an opt-in capability for legacy metadata controllers; unsupported fakes can list but do not authorize Rename.
- New-client Supabase metadata transport now only **SELECTs** owner Program Routines with revision and supports INSERT. The old unversioned `SupabaseRoutineRepository.rename(id,name)` **fails closed**; no Flutter Data API direct UPDATE(name) is issued from it.
- Protected metadata Rename delegates the frozen `RoutineAggregateUpdate` name-only command to the **existing** `SupabaseRoutineCompositionRepository.updateAggregate` and server seven-argument name-aware RPC. The controller freezes list-time Program, revision, expected Name and login cycle; a confirmed result must match the RPC-confirmed revision and an owner-scoped read-back. Reading the desired Name after an unknown write is **not sufficient** success proof.
- Existing app auth provider supplies the **live** `AuthSessionAuthenticated.session.loginCycleId`; list and dispatch reject stale/changed cycles, including logout/relogin by the same owner. No app visual/layout change.
- Uncertain legacy metadata Create reconciliation now only accepts the original stable UUID with the **same** persisted Name; it never blindly calls Rename to overwrite a concurrently edited name. A mismatch stays unconfirmed and requires explicit editor lifecycle handling.
- Focused tests added/updated: no direct metadata Rename, malformed revision/foreign Program, auth-owner and login-cycle change, freeze and delegate name-only RPC, stale source Program, A→B→A, unknown write confirmation, post-Create changed Name, zero-row and owner read-back.
- **Validation status:** GitHub Flutter CI #39033278931 **SUCCESS on source HEAD `45b45fb`** (all five jobs); attribution checks pass. Prior source CI #39031276265 is historical. All three native review threads resolved, **no APPROVED review**, Codex blocked by usage limits; local device QA and authoritative branch protection status unavailable.
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
- [x] **M2B (source merged; not deployed):** protected current-client Rename, Create identity guards and tests merged in PR #591, post-merge CI #39038295713 PASS; no Move activation.
- [ ] **M2C (separately owner-gated):** supported deployed old-client cutoff and compatibility policy; reviewed server enforcement removing old direct `UPDATE(name)` when safe.
- [ ] **M2D (separately authorized):** apply/verify dormant M1 migration then review conditional Move EXECUTE activation, negative/race SQL and exact-head CI. Existing Program Flutter selector is a later bounded slice.
- [ ] **Later:** #568 canonical My Program, atomic `+ New Program → Create & Move`, #567 Delete Program.

## 4. Findings and Merge/Release Gates

| ID | Severity | Status | Finding / disposition |
|---|---|---|---|
| M2-P2-01 | P2 activation blocker | Open | Legacy authenticated UPDATE(name) can mutate a Routine moved from stale Program context. Server grant unchanged until compatible retirement is expressly approved. |
| M2-COMP-01 | Contract gate | Merged / post-merge CI PASS | Versioned metadata list now binds original owner-scoped Program, revision, expected name and app login-cycle to the protected RPC. A→B→A stale revision and cycle-change tests included. |
| M2-OPS-01 | Process | Open | Main has 63 SQL files while live has 62; M1 source is merged but un-deployed. Do not mix up code merge, hosted deployment and client activation. |
| M2-OPS-02 | Process | Open | Local Windows git status, device/client adoption and supported-version evidence not available through connector-only audit. |
| M2-P2-02 | P2 client retry/uncertainty | Resolved in source + exact-head CI | Previous controller allowed a fresh mutation token after ambiguous Rename; current controller stores Routine-scoped in-process uncertainty gate and focused regression prohibits subsequent rename even after refresh. |
| M2-P2-03 | P2 stale owner metadata exposure | Merged / post-merge CI PASS | Post-Rename auth/account switch plus failed verification read previously republished stale Routine rows. Explicit live owner+login-cycle guard now fail-closes with empty `loadFailed` state; post-dispatch and Create regression tests passed on older HEAD. |
| M2-P2-04 | P2 pending Create UUID loss after network list failure | Merged / post-merge CI PASS | On unchanged owner+login cycle, list errors now hide rows without clearing uncertain Create UUID. Account/cycle mismatch still invalidates the identity. Tests cover both committed and uncommitted Create outcomes through failed and recovered list reads. |

**Readiness:** M2B **merged and CI-validated** on `main@c12ea127` with four inline threads resolved. Move activation **NO-GO**: old-client direct `UPDATE(name)` remains enabled, M1 Move RPC not deployed, server-supported-version cutoff not approved. Historical pre-merge review statements below do not describe current PR state.

## 5. Handoff

**Changed files at this checkpoint:** `.ai/tasks/README.md`, `.ai/tasks/issue-569-routine-move-existing-program-db.md`, this M2 brief; Workout domain metadata interface, Supabase metadata repository, Program Routines controller, focused repo/controller tests, and app Workout provider. No schema, grants, visual UI, deployment or Linear status modified.
**Validation:** GitHub final pre-merge Flutter CI #39036088215 and post-merge `main@c12ea127` CI #39038295713 both SUCCESS (five Flutter/Dart jobs); no independent GitHub `APPROVED` review, owner-directed manual audit documented, no policy bypass. Hosted Supabase queried read-only. No local Windows/device/app-release QA, Supabase deploy or grant change.
**Next owner:** #569 M2C decision/planning owner for a separately approved server-enforced legacy-client cutoff. GitHub #569 stays Open and broad W4/W6B Linear acceptance remains Backlog; M1 deploy and Move grant/UI activation are independent.
