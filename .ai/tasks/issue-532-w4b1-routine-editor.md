# GitHub #532 — W4B1 Program-owned Routine Editor

**Status:** In progress — implementation not yet delivered.
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
**Implementation ownership state:** Active — initial branch/task bootstrap, runtime work not yet implemented.
**Ownership transition:** Not applicable (no previous W4B1 implementation owner found).
**Repository state last verified:** Protected GitHub `main@ee5ed4cc67bfb6c8d3eb867129578201b60703bc`, after merged docs PR #531.
**Branch:** `tnyx/issue-532-w4b1-routine-editor`, created from exact remote main SHA.
**HEAD SHA:** To update after task bootstrap commit.
**Observed working-tree state:** GitHub remote refs verified; user's local Windows working tree and post-#531 sync are **not** accessible or verified. Before local code, check `git status -sb` and `.github/POST_MERGE_SYNC.md`, fast-forward only, preserve uncommitted work.
**PR / tracker:** GitHub #532; Linear TNYX-81 W4 remains Backlog and blocked by W1/TNYX-78 and W3/TNYX-80 for broader acceptance.
**Current implementation state:** No W4B1 Dart, widget, routing or database changes yet.
**Validation completed at SHA:** Existing PR #530 read-only Detail Flutter CI previously passed; not evidence that W4B1 passes.
**Validation remaining:** New-head Flutter/Dart Analyze+Tests, focused controller/widgets/navigation, trusted attribution, independent review, dark/compact/accessibility and performance tests.
**Current blocker:** No identified schema change necessary. This connected runtime lacks Flutter/Dart executables; any source change requires exact-head CI or local Flutter validation.
**Open review finding IDs:** None for new W4B1 code yet.
**Next exact action:** Implement minimal feature controller/draft + tests; then picker, editor and app composition. Keep PR Draft until complete and verified.

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
- [ ] Build Workout-owned draft/controller with existing IDs, validation, tests, conflict and uncertain-save semantics.
- [ ] Add bounded canonical Exercise picker (catalog + active user Custom Exercise search), tests for cancel/return/foreign owner.
- [ ] Implement separate Edit screen with Core UI and real supported Set inputs; Cancel/Update/empty/loading/failure/accessibility.
- [ ] Wire existing read-only Detail Edit action and owner-keyed app routing; refresh only after confirmed save; leave overflow Rename.
- [ ] Verify Flutter/Dart Analyze+Tests, 1,007-set performance, owner switch, weight units, dark/compact. Exact-head attribution and independent review before merge.
- [ ] Reconcile only actually implemented canonical status, archive after validation.

## 6. Quality Review
**Validation run:** None for W4B1 yet; bootstrap is docs-only. Flutter/Dart CLI unavailable here.
**Security review focus:** Owner A→B transitions, wrong Program, archived/foreign Custom ref, mutation ID/expected revision, duplicate submission, stale in-flight reads, kg↔lb conversion, ambiguous RPC.
**Findings:** None on new source yet.

## 7. Final Handoff
**Changed files:** Initial task brief + task index only; no runtime source in bootstrap.
**Actual behavior:** Production Routine Detail remains read-only, with no Edit button until implementation.
**Known limitations:** No device/local Flutter validation; user's post-#531 Windows sync unverified.
**Final status:** PARTIAL / implementation pending.
