# GitHub #532 — W4B1 Program-owned Routine Editor

**Status:** In progress — Draft PR #533 source wired; prior exact-head Flutter/Dart CI PASS at 8a6a931e, independent Codex review produced two actionable P2 findings. Fixes authored, new exact-head CI and review disposition pending.
**Primary owner:** Workout feature (`apps/features/workout`), app-shell composition/navigation (`apps/app`).
**Affected platforms:** Flutter mobile (Android/iOS).

## Owner Approval and Scope Boundary
**Trigger:** New independently scoped user-facing feature and visible Edit Routine flow.
**Approval status:** Approved for the previously described bounded W4B1 only.
**Approval evidence:** 2026-10-12 owner supplied visual references, specified Routine card → **read-only Detail** → **Edit Routine** button → **separate Edit Routine** screen, then instructed `Next go` following the explicit W4B1 scope and exclusion description.
**Approved product/UI/data shape:** Enabled Edit action only for accessible saved user Program/Routine; separate editor with real Exercise search/picker using catalog + active Custom Exercises, stable ordered Exercise and Set entries, add/remove/reorder and fixed positive Reps/optional Weight/restSeconds, Cancel without save, one confirmed Update returning to refreshed Detail. Use Tio Core theme; do not copy Hevy pixel styling.
**Explicit non-changes:** No rep-range, timed sets, notes, supersets or per-Exercise rest schema; no new Supabase tables/columns/RPC/RLS; no Workout Start/Play, media/image, Delete Program/Routine, default My Program quick-create, watch, AI or connector changes. Routine card overflow Edit remains real metadata Rename; do not repurpose without another approved scope.

## Active Handoff
**Planning owner:** Tio-world architecture connected session.
**Implementation owner:** Current connected GitHub session for this exact scope until explicit transfer; no concurrent source owner found in live W4B PR/branch search. A local Codex agent must receive a recorded transfer before editing the same files.
**Review owner:** Independent Codex/reviewer if available; same-session manual COMMENT is not independent APPROVED.
**Implementation ownership state:** Active — owner-exclusive editor controller, picker, Set sheet and Edit page implementation on Draft PR #533.
**Ownership transition:** Not applicable (no previous W4B1 implementation owner found).
**Repository state last verified:** Protected GitHub `main@ee5ed4cc67bfb6c8d3eb867129578201b60703bc`, after merged docs PR #531.
**Branch:** `tnyx/issue-532-w4b1-routine-editor`, created from exact remote main SHA.
**Source checkpoint before handoff update:** `7333fcb70291b4903f15f2bec3346347b9243e5d` (Editor fixes; latest Flutter CI #38285385621).
**Observed working-tree state:** GitHub remote refs verified; user's local Windows working tree and post-#531 sync are **not** accessible or verified. Before local code, check `git status -sb` and `.github/POST_MERGE_SYNC.md`, fast-forward only, preserve uncommitted work.
**PR / tracker:** GitHub #532; Linear TNYX-81 W4 remains Backlog and blocked by W1/TNYX-78 and W3/TNYX-80 for broader acceptance.
**Current implementation state:** Workout-owned editor controller, picker, separate `EditRoutinePage` and fixed Set modal with focused tests; existing read-only Detail exposes owner-gated Edit action and app-shell opens account-keyed Editor, then refreshes Detail only after a confirmed Update. Still Draft/unmerged.
**Validation completed at SHA:** Controller `871e2e81` Flutter CI #38258240886 PASS; picker/handoff `fa53ac44` Flutter CI #38265292376 PASS. Editor first CI #38285047968 FAIL (one missing brace, one untyped row). Corrected source `7333fcb7` Flutter/Dart Analyze PASS in CI #38285385621; Flutter tests still running at checkpoint and Dart tests pending. This is **not** full exact-head validation.
**Validation remaining:** New-head Flutter/Dart Analyze+Tests, focused controller/widgets/navigation, trusted attribution, independent review, dark/compact/accessibility and performance tests.
**Current blocker:** No identified schema change necessary. This connected runtime lacks Flutter/Dart executables; any source change requires exact-head CI or local Flutter validation.
**Open review finding IDs:** W4B1-P2-01 (Codex stale picker source, original PR comment 4251297955); W4B1-P2-02 (Codex same-user loginCycleId revocation, original PR comment 4251297963). Both fix authored but status Open until exact-head CI and reviewer-thread reconciliation.
**Next exact action:** Validate exact-head Flutter/Dart CI for W4B1-P2-01/02, reply to Codex inline threads with evidence, resolve threads only after validation, verify exact-head attribution and scope, then independent re-review and device QA. Keep PR Draft/unmerged.

## 1. Discovery
**User outcome:** Saved Routine card opens readonly Detail with Exercises/Sets. Its new `Edit Routine` action opens a *separate*, real persisted editor. Cancel discards; Update saves once with revision lock and refreshes Detail.
**Success criteria:** Saved owner Program/Routine association verified before reads; active signed-in user owns any selected Custom Exercise. Duplicate canonical refs are separate entry UUIDs, persisted IDs unchanged on edits, ordering stable. Positive Reps, nullable canonical kg/Rest supported. Empty, loading, failed, not found, conflict, unknown save, account switch, cancel and duplicate submit behave safely.
**Scope:** Selected Program-owned Routine, feature-owned draft/controller/picker/editor, nullable existing providers and app route navigation, test coverage.
**Non-goals:** W4B2 advanced fields, standalone Library Routine collection, TrainingPlan/session operations, schema expansion or UI redesign of Detail.

## 2. Codebase Exploration
**Verified source:** `apps/features/workout/lib/src/presentation/library/routines/routine_detail_page.dart` is read-only; `routine_detail_controller.dart` verifies owner Program→Routine before composition and guards async state. `apps/app/lib/app/routing/shell/shell_route.dart` keys private previews by authenticated session and gates Profile weight units. `RoutineCompositionRepository.read/save` already exposes revision-validated snapshot, immutable entry/set UUIDs, one RPC save and `RoutineCompositionSaveOutcomeUnknown`. Bundled Exercise catalog and Custom Exercise repository already serve canonical Exercises; dedicated Exercises UI has no Routine-context return mode. `SetPrescription` only models fixed positive reps and optional kg load/restSeconds.
**Applicable governance:** root + feature `AGENTS.md`, Core theme README, `.ai/tasks/design-system-token-consolidation.md`, ADR-0015, screen docs, `.ai/FEATURE_DEVELOPMENT.md`.

## 3. Clarification
| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Read-only Detail and Edit screen remain separate | Approved | Owner references | Product |
| Picker + currently durable fixed-Reps/Weight/Rest fields only | Approved | Existing canonical model and explicit bounded scope | Product |
| Reuse repository atomic RPC and stored IDs | Locked | Data integrity / owner RLS | Workout |
| Full rep ranges, timed sets, notes, supersets | Deferred | Require separate domain/schema+product authorization | Product |

## 4. Architecture Design
**Chosen approach:** Feature editor controller owns isolated ordered immutable-entry draft. Picker uses existing Exercise read/search capability and returns only canonical `ExerciseRef`. Feature presentation consumes `package:tio_core/core.dart` components; app shell only supplies repositories/session/weight-unit identity/navigation. `RoutineCompositionSave` freezes `expectedRevision`, mutation UUID and all entry/Set IDs before a single RPC request; unknown result is not silently retried/rebased. Confirmed success re-reads Detail.
**Alternative rejected:** In-place editing in Detail; second Exercise source; direct child-table writes; fake Edit/Add buttons; new backend.
**Failure & accessibility:** Fail closed for missing repository, signed-out/foreign owner, wrong Program and stale auth/Profile; clear loading/error/retry; form validation, accessible labels/focus, no double submits; revision conflict and unresolved save each require explicit safe UX.

## 5. Implementation Plan
- [ ] Verify current HEAD, owner and local clean state before source edits.
- [x] Build Workout-owned draft/controller with existing IDs, validation, tests, conflict and uncertain-save semantics.
- [x] Add bounded canonical Exercise picker (catalog + active user Custom Exercise search), tests for cancel/return/fail-closed.
- [x] Implement separate Edit screen source with Core UI and real supported Set inputs; Cancel/Update/empty/loading/failure/accessibility. CI/widget tests still validating.
- [x] Wire existing read-only Detail Edit action and owner-keyed app routing; refresh only after confirmed save; leave overflow Rename. CI still pending.
- [ ] Verify Flutter/Dart Analyze+Tests, 1,007-set performance, owner switch, weight units, dark/compact. Exact-head attribution and independent review before merge.
- [ ] Reconcile only actually implemented canonical status, archive after validation.

## 6. Quality Review
**Validation run:** Controller CI #38258240886 PASS; picker CI #38265292376 PASS. First Editor CI #38285047968 failed at Flutter Analyze on two scoped code defects, fixed in `7333fcb7`. Editor CI #38285385621 Flutter/Dart Analyze PASS; Flutter/Dart tests not yet complete at checkpoint. Local Flutter/Dart CLI unavailable.
**Security review focus:** Owner A→B transitions, wrong Program, archived/foreign Custom ref, mutation ID/expected revision, duplicate submission, stale in-flight reads, kg↔lb conversion, ambiguous RPC.
**Findings:** No known unresolved review threads at picker checkpoint. Independent review still pending.

## 7. Final Handoff
**Changed files:** Workout-owned editor controller, picker controller/page, `EditRoutinePage`, `RoutineSetEditorSheet`, focused controller/widget tests, `routine_detail_page.dart`, app shell route, library exports, canonical screen docs and task handoff.
**Actual behavior:** This Draft branch now renders `Edit Routine` in read-only Detail only for a verified owner Routine with active account Profile unit; separate Editor is wired and read-only Detail re-fetches data after confirmed Update. Protected `main` is unchanged until merge.
**Known limitations:** No device/local Flutter validation; user's post-#531 Windows sync unverified.
**Final status:** PARTIAL / production Edit entry and navigation implemented in Draft; exact-head Flutter/Dart CI, review and device validation pending.

## 2026-10-12 W4B1 picker checkpoint
- Verified on current Draft PR #533: controller source `871e2e81` Flutter CI #38258240886 PASS, with full Flutter/Dart Analyze and Tests jobs. Earlier four curly-brace lint errors were corrected before that run.
- Added independent Routine-context picker controller/page on the same implementation branch. Reuses `ExerciseCatalogRepository`, RLS-scoped `UserExerciseRepository.list`, `ExerciseCatalogQuery`, `ExerciseListItem` and governed Core inputs/rows. It returns one canonical `Exercise` on tap and null on Back; it never writes to Routine or Custom Exercise storage.
- Both sources must resolve before results are selectable, archived Exercises are hidden, malformed/duplicate Custom refs fail closed, and late async results are suppressed after reload/disposal. A missing user Exercise repository allows catalog-only selection, but production Editor remains unavailable until owning Program/Routine and session capability have been verified.
- Tests cover mixed catalog/Custom search, archived ref exclusion, Custom read failure/retry, invalid owner-shaped/duplicate Custom refs, stale load, successful picker return, Cancel, and source failure/retry. Source checkpoint `d456a8d4`; CI #38265035209 pending when written. Not enabled from Detail or app route.
- No new Exercise repository/domain model, Supabase schema/RPC, routing, or existing Exercises page edit. Follow-up: Editor presentation, picker hookup, fresh Detail confirmation, auth-keyed app navigation and post-Update refresh, full regression/visual/security gates, independent review.

## 2026-10-12 separate Edit page checkpoint
- Owner approved existing W4B1 flow. Fresh PR #533 audit before source: `fa53ac44`, `main@ee5ed4cc`, ahead 9 / behind 0, no review threads, Flutter CI #38265292376 SUCCESS; parent Linear TNYX-81 remains Backlog/blocked by W1/W3. No new product/task or schema approval required.
- Added `edit_routine_page.dart` and `routine_set_editor_sheet.dart` under Workout-owned Routine presentation, plus `edit_routine_page_test.dart` and barrel exports. No app shell/Detail production routing in this step. Page uses existing owner metadata/composition repositories, catalog+Custom picker, and Tio Core `TioAppBar`, `TioCard`, `TioButton`, `TioInput.numericEditor`, `TioEditorSheet`.
- UI actions: add/remove/reorder exercises and sets, fixed positive reps, optional kg/lb display weight converted to canonical kg, optional rest seconds, Cancel with no write, one guarded Update returning `true` only when confirmed/read-verified, explicit reload on revision conflict, unknown-outcome read-only Check saved data or exit without retry. Unchanged rounded displayed lb load preserves byte-exact canonical kg; missing account/units/source disables writes. Existing entries and Sets keep UUIDs. 1,007-Set editor list renders lazily in a bounded card.
- Tests authored for empty/add/picker cancel, exact kg on lb edit, invalid fields, missing repository/wrong Program/missing unit, revision conflict, unknown read-only reconciliation and 1,007-set dark-mode lazy rendering.
- First editor CI #38285047968 failed Flutter Analyze on **two local compile findings** (`dynamic` ExerciseListItem and an omitted class brace). Both fixed with commits `3d7fc8c` and `7333fcb`. On source `7333fcb`, CI #38285385621 Flutter Analyze and Dart Analyze PASS while Flutter Tests remain in progress and Dart Tests pending. Do not mark full validation/Ready/merged until exact-head CI passes and independent review completes.
- User's Windows working tree/device QA cannot be inspected here. No Supabase schema/RLS/RPC or Watch/AI/connector touched. Next user-reachable step is guarded Detail Edit action + account-keyed app composition and post-save Detail refresh, only after CI fixes; preserve card overflow Rename.

## 2026-10-12 owner-gated Detail → Editor checkpoint
- Fresh PR #533 audit: protected main `ee5ed4cc`, latest before edits `c9ea0eb7` ahead 18/behind 0, no review threads or PR comments. Broad Linear TNYX-81 stays Backlog, blocked by TNYX-78/80. Scope remains already owner-approved W4B1.
- Editor CI #38286253839: Flutter/Dart Analyze PASS, Flutter tests reported **413 passed / 2 failed** in new `edit_routine_page_test.dart`. Failures were isolated to fixture route disposal between successive test harnesses and missing Profile unit incorrectly leaving disabled Update button in widget tree. Both fixed in `cde1215a` / `f09b36e2` (not yet exact-head validated).
- Added Workout-owned `RoutineDetailPage.onEditPressed` callback with explicit ready + resolved weight unit visibility, guarded duplicate opens, and confirmed-return repository `load()`; owner association remains verified before button is exposed. Tests added for hidden Edit on missing/failed/wrong owner/unit, Cancel not reloading, confirmed Update fetching current persisted Exercises/Sets.
- In `apps/app/lib/app/routing/shell/shell_route.dart`, matching bootstrap/Auth user ID and valid Profile unit gate the Edit action and reads. Destination Consumer reevaluates Auth, bootstrap, Profile and current owner repositories every rebuild; its user/auth-scoped key disposes old private editor/controller drafts on account switch, while stale account providers are passed as null. This is feature/app composition only; no new backend or independent Exercise source.
- Latest routing CI #38288078715 failed Flutter Analyze on three redundant non-null checks in the nested route's already-promoted control flow. Fixed in `4aba1ff1`; no tests ran in that failed run. Last source commit before docs `4aba1ff1` and Detail widget tests `539eb88d`. Exact-head Flutter CI pending after docs checkpoint.
- PR remains Draft/unmerged; repository code, CI and connected services are the truth, no local Windows worktree or device validation claimed. Next: inspect exact-head Flutter/Dart Analyze+Tests, bounded fixes, independent review/security QA, then owner approval before any Ready/merge.

## 2026-10-12 Auth fixture / private overlay checkpoint
- CI #38288512836: Flutter/Dart Analyze PASS; App Flutter tests 392 PASS / 4 FAIL. Four existing routing tests lacked a matching authenticated Auth/Profile fixture although bootstrap user was test-user. Production verified-owner guard correctly denied reads. Kept the guard; test-only fixture now supplies matched Auth/Profile when composition is enabled, plus a dedicated Auth/bootstrap mismatch regression. Commit 15a3e530.
- Additional review identified private Exercise Picker / Set input routes could outlive the underlying editor during account change. The editor app-shell Consumer now detects Auth/bootstrap revocation, schedules one-shot active editor-route cleanup using Navigator.popUntil and closes any nested private picker/sheet before closing editor. Dedicated route tests cover both overlay types on session loss; commits 33040c52, c30d7f78, e5235014, de7a79f4.
- Exact-head Analyze, Flutter/Dart tests, independent review and device QA remain pending at this checkpoint. No broad W4 Linear transition, backend/schema, Workout Start, Watch, AI, connectors or card overflow Rename changes.

## 2026-10-13 Codex review follow-up (still Draft)
- Fresh GitHub audit: PR #533 HEAD `8a6a931e721560b75f65fc8da4cd5859474de65a`, ahead 35/behind 0 relative to protected main `ee5ed4cc`; Flutter CI #38289682028 and both attribution checks SUCCESS at that old head. Codex completed an independent COMMENT review at the same SHA (NOT APPROVED). Two P2 threads were OPEN; Linear TNYX-81 Backlog, blocked by TNYX-78/TNYX-80. No merge.
- **W4B1-P2-01 (Open, correction committed):** [Codex comment 4251297955](https://github.com/im-tnyx/tio-world/pull/533#discussion_r4251297955) observed that a second-device Custom Exercise freshly selected in picker was silently discarded by the editor's stale source verification. Fix `88a7e538` relies on the canonical picker controller's own validated selected `Exercise`, adds the draft, and then refreshes editor catalog/Custom source so labels and Update eligibility remain current. Failed refresh blocks Update until Retry. Regression `1f599856`: Custom ref created after initial editor source load is selected by the newer picker snapshot; entry ID persists in single save, no Custom write, label refreshes.
- **W4B1-P2-02 (Open, correction committed):** [Codex comment 4251297963](https://github.com/im-tnyx/tio-world/pull/533#discussion_r4251297963) observed same-user interactive re-login may change `AuthSession.loginCycleId` without changing bootstrap `userId`. Fix `bd3d5f34` keys private Detail and Editor by cycle, captures opening cycle in editor navigation closure, and requires unchanged cycle + owner/auth identity. The existing private Picker/Set modal dismissal now also triggers on cycle revocation. Regression `1447f447`: changing cycle with same user (bootstrap unchanged) closes nested Picker and Set modal, releases old Editor state, and allows new owner-scoped Detail reread.
- In the provider-neutral model `loginCycleId` may be null. The guard compares the nullable value when emitted; if a provider cannot expose a real cycle, same-user reauthentication without any intermediate auth change cannot be distinguished solely by this client API. No invented auth infrastructure in W4B1.
- Current **new exact-head Analyze+Tests, attribution and Codex thread disposition PENDING** at the time of this writing. Flutter/Dart executables and physical-device QA remain unavailable to this connected session. The branch is unmerged; no Supabase/schema/RPC, Workout Start, card overflow Rename, Watch, AI or Connector change.
