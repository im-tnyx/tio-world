# GitHub #475 — Workout Library IA reconciliation

**Status:** Validated
**Completed:** 2026-09-30
**Primary owner:** Workout Library planning/docs (`apps/features/workout` canonical contract)
**Affected platforms:** Flutter phone planning/docs only in this slice

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + approved product-visible UI/UX direction
**Approval status:** Approved
**Approval evidence:** Owner approved continuing the bounded reconciliation slice with “Go next” on 2026-09-30 after the audit proposed reconciling GitHub #475, canonical docs/ADR and Linear before any Flutter UI work.
**Approved product/UI/data-shape boundaries:** Reconcile the approved Library IA: Programs default category; Exercises second; conditional Your Plan; owner-provided screenshots define only the category-pill selection interaction (full strip → X + selected pill → clear back to full strip), not the Library top-bar design; Routine + Explore quick actions; Programs visible directly on Library; optional Programs manage route; Program-owned Routine ownership; top-level Routine create entry may exist only if saved Routine resolves to one owning Program; Exercise Favorites/Custom/Folders remain capability-owned; Your Plan remains TrainingPlan-owned.
**Explicit non-changes:** No Flutter runtime/source changes, no router changes, no Supabase schema/RLS/grant changes, no Program/Routine persistence changes, no Custom Exercise/Favorites/Folders implementation, no TrainingPlan implementation, no Program delete implementation, no Start Empty Workout behavior implementation.

## Active Handoff

**Planning owner:** Current repository agent
**Implementation owner:** Current repository agent (docs/tracker reconciliation only)
**Review owner:** Codex through head `5371bc92...`; manual repository review fallback on `47f07077...` because the Codex code-review quota was exhausted
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository checkpoint last verified:** 2026-09-30, merged `main@359cc5932a208091f24d869e545d57534fc32591` via PR #491
**Branch:** Historical implementation branch `tnyx/gh-475-library-ia-reconciliation`; outcome merged to `main`
**Checkpoint note:** Final docs reconciliation merged via PR #491. The last exact implementation head was `1799089f4c56f05712a8c57546a139bc11a226e7`; merge commit is `359cc5932a208091f24d869e545d57534fc32591`.
**Observed working-tree state:** Remote branch created from clean/synced `main`; no local working-tree mutation is being claimed.
**Observed uncommitted/dirty files:** Not applicable to connector-only repository edits.
**PR / tracker:** GitHub #475; Linear TNYX-83 / TNYX-267 with related TNYX-81, TNYX-263, TNYX-264, TNYX-265, TNYX-268, TNYX-86
**Current implementation state:** Validated docs/architecture reconciliation merged. No Flutter runtime or Supabase implementation was part of this slice.
**Relevant execution surface:** `docs/screens/library.md`, `docs/screens/programs.md`, `docs/screens/routine-library.md`, ADR-0015, GitHub #475, Linear tracker notes
**Validation completed:** Final exact-head manual docs/architecture review on `1799089f4c56f05712a8c57546a139bc11a226e7`; 23 ahead / 0 behind from reviewed base, exactly 9 docs/task paths, trailing-whitespace 0, conflict markers 0, unresolved review threads 0. Earlier Codex-reviewed heads raised 11 findings; all were addressed and resolved. The final Codex request was quota-blocked before analysis and was not claimed as a pass. PR #491 then squash-merged as `359cc5932a208091f24d869e545d57534fc32591`.
**Validation remaining:** None for this reconciliation slice. Future #475 runtime slices require their own source/runtime validation.
**Current blocker:** None for this validated reconciliation slice. Future runtime implementation remains separately gated by stable default `My Program` identity, capability readiness, and unresolved Start Empty Workout ownership semantics.
**Open review finding IDs:** None.
**Next exact action:** Any #475 runtime implementation must start a new focused `.ai/tasks` brief from fresh `main`, re-read current Linear/GitHub/runtime state, and preserve the canonical contracts recorded by PR #491.

## Global UI / Design-System Guardrail

This slice does not change Flutter UI. Any later #475 UI implementation must re-read `apps/core/lib/src/theme/README.md`, inspect the public `package:tio_core/core.dart` reusable surface (including `TioTabSwitcher`), and preserve capability gating.

## 1. Discovery

### User Outcome

Freeze one coherent Library IA before implementation so future agents do not build from stale W6A/W6B wording.

Latest approved target:

```text
Library
├─ Programs        // default category
├─ Exercises       // second category
└─ Your Plan       // only with real followed/applicable TrainingPlan

quick actions:
Routine | Explore
```

Programs remain the owner/container for saved Routines. Exercises composes capability-owned Favorites, Custom Exercises and folders when those capabilities are real. Your Plan reads canonical TrainingPlan truth and is hidden otherwise.

### Success Criteria

- GitHub #475 contains no conflicting old quick-action acceptance.
- Canonical Library/Program/Routine docs distinguish top-level Routine **entry action** from saved Routine **ownership**.
- ADR-0015 no longer incorrectly forbids an entry action while preserving the no-orphan/no-standalone-Routines decision.
- Canonical docs record Programs → Exercises → conditional Your Plan navigation and capability gating.
- Current runtime is documented honestly as still using Programs/Exercises navigation rows and dedicated screens.
- Linear receives a reconciliation note so sequencing and acceptance do not silently rely on stale wording.
- No product runtime or database behavior changes in this slice.

### Scope

- GitHub #475 wording cleanup.
- Canonical Library/Programs/Routine docs.
- ADR-0015 clarification.
- Active task handoff/index.
- Linear reconciliation comments/notes.

### Non-Goals

- Implement category cards/tabs.
- Embed ProgramsPage or ExercisesPage into Library.
- Implement Custom Exercise, Favorites, folders or TrainingPlan.
- Create the default My Program identity mechanism.
- Change Program/Routine Supabase shape.
- Resolve Start Empty Workout runtime semantics.
- Delete/repurpose existing routes.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected:
  - `apps/features/workout/lib/src/presentation/library/library_page.dart`
  - `apps/features/workout/lib/src/presentation/library/programs/programs_page.dart`
  - `apps/features/workout/lib/src/presentation/library/programs/programs_controller.dart`
  - `apps/features/workout/lib/src/presentation/library/exercises/exercises_page.dart`
  - `apps/features/workout/lib/src/presentation/library/exercises/exercises_controller.dart`
  - `apps/app/lib/app/routing/shell/shell_route.dart`
  - `apps/core/lib/src/ui/components/navigation/tio_tab_switcher.dart`
  - current Library/Programs tests
- Existing runtime:
  - Library is stateless and pushes `/workout/programs` / `/workout/exercises`.
  - Programs has real persisted list/create capability but rows are display-only.
  - Exercises has real catalog/search/filter capability.
  - `TioTabSwitcher` exists as a reusable selector candidate for later implementation.
- Capability readiness:
  - W3A dedicated Exercises foundation is Done.
  - user-created Exercise persistence foundation is deployed/validated, but W3D UI remains Backlog.
  - W3C Favorites and W3E folders have no repository/table implementation found.
  - W6C Your Plan is blocked by W9 TrainingPlan.
  - W6B is blocked by W4; W4 is blocked by W1/W3.
- Tests already present:
  - `library_page_test.dart`
  - `programs_page_test.dart`
  - Exercises presentation tests.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Library category order is Programs → Exercises → Your Plan | Approved | Latest owner direction; Programs is default | Owner |
| Reference screenshots define only pill/category selection behavior, not Library top-bar design | Approved | Owner clarification after PR #491 opened | Owner |
| Your Plan is hidden without a real followed/applicable TrainingPlan | Approved | Matches W6C/W9 capability gating; no placeholder plan truth | Owner + TNYX-268/TNYX-86 |
| No standalone Routines category | Approved | Preserves Program ownership | ADR-0015 |
| Quick cards are Routine + Explore | Approved | Latest correction supersedes older Exercise + Explore wording | Owner |
| Top-level Create Routine entry may exist | Approved with ownership guard | Entry point is not ownership; saved Routine still requires exactly one Program | Owner + ADR-0015 clarification |
| Direct top-level Routine should use canonical default My Program | Approved product behavior; implementation unresolved | Current Program model has no stable default marker; display-name matching is not sufficient | Owner; W1 follow-up required |
| Programs manage screen may remain secondary | Approved | Program rows still appear directly on Library; individual Program does not require intermediate screen | Owner |
| Exercises category shows capability-owned smart views/folders | Approved target; capability-gated | W3C/W3D/W3E own data; no fake rows before real capability | Owner + Linear |
| Exercises catalog browse path | Approved reconciliation | Keep the three approved default entries unchanged; a separate secondary **Browse exercises** action opens the shipped canonical `/workout/exercises` route so catalog/search remains discoverable | #475 reconciliation |
| Start Empty Workout lower action semantics | Unresolved for runtime | Existing Workout architecture must determine canonical Routine/Session ownership before implementation | Follow-up |

## 4. Architecture Design

### Chosen Approach

Treat this as a documentation/tracker reconciliation only. Preserve current runtime until the dependent capabilities are ready.

Canonical distinction:

```text
entry action != ownership

Library -> Create Routine
             |
             v
must resolve exactly one owning Program before persistence
```

ADR-0015 continues to reject a standalone Routines collection and orphan Routine truth. It is clarified to permit a Library-level create entry only when the ownership invariant is satisfied.

### Ownership and Data Flow

```text
Library presentation
  ├─ Programs category -> Program capability
  ├─ Exercises category -> W3 Exercise capabilities
  └─ Your Plan -> canonical TrainingPlan capability

No Library-owned Program/Routine/Exercise/TrainingPlan truth
```

### Alternative Rejected

- **Implement selector now with placeholder Favorite/Folder rows:** rejected because AGENTS capability gating forbids fake production affordances.
- **Use `My Program` display name as identity:** rejected because names are mutable/non-unique and do not provide idempotent ownership.
- **Keep “no top-level Create Routine action” literally:** rejected because it conflicts with approved UX; the durable rule is no orphan/standalone saved Routine truth.

### Failure and Accessibility States

Deferred to later UI implementation. That slice must preserve loading/error/empty states from real capability controllers and accessible selected-state semantics.

## 5. Implementation Plan

- [x] Clean stale/conflicting GitHub #475 wording.
- [x] Clarify ADR-0015 entry-action vs ownership rule.
- [x] Update Library canonical target IA and current-runtime distinction.
- [x] Update Programs/Routine docs for secondary Programs manage screen and guarded direct Routine entry.
- [x] Reconcile Linear TNYX-83 and TNYX-267 with dated owner-approved IA sections and replace explicitly conflicting acceptance wording.
- [x] Run connector-visible docs-only scope, trailing-whitespace, conflict-marker and stale-wording checks.
- [x] Open docs-only PR #491.
- [x] Resolve all Codex review findings/threads. The final Codex re-review request was quota-blocked; manual exact-head review is the documented fallback and must be PR-recorded.

## 6. Quality Review

### Validation Run

Historical/content-checkpoint evidence:

```text
Checkpoint: f21e75734588226574a1f33ca19946d9e507c8d8
Base:       main@f5e02a22f5ac4d39be2b2c4e4f7c90ded6c47cf6
Compare:    21 ahead / 0 behind
Changed paths:
  .ai/tasks/README.md
  .ai/tasks/gh-475-library-ia-reconciliation.md
  docs/adr/0015-program-owned-routine-and-program-source-boundary.md
  docs/planning/ROADMAP.md
  docs/screens/exercise-search.md
  docs/screens/library.md
  docs/screens/programs.md
  docs/screens/routine-library.md
  docs/screens/workout.md

Connector text scans before the handoff metadata update:
  trailing whitespace: 0
  conflict markers:    0

Issue/doc reconciliation:
  stale Exercise + Explore acceptance: removed
  screenshot reference: pill-selection interaction only
  Workout contract: direct Routine-create entry reconciled;
                    workout start still requires selected saved Routine
                    or scheduled PlannedWorkout
  Workout live status: shipped Programs collection/create foundation recorded
  Library categories: Programs → Exercises → conditional Your Plan aligned
  ROADMAP: direct Routine-create entry reconciled
  Quick actions: Routine/Explore acceptance explicitly capability-gated
  Exercises browse: secondary Browse exercises action → canonical /workout/exercises;
                    not a fourth default collection card
```

Live exact-head validation is maintained in PR #491 rather than embedding a self-referential moving head SHA in this file. The task brief keeps the stable content checkpoint above; the PR/review record carries the current-head compare, changed-path, whitespace and conflict-marker evidence.

Local `git diff --check` was not available in the connector-only environment and is not claimed as run.

Codex quota fallback:

- Codex reviewed heads `6729ba36...`, `0e194c57...`, and `5371bc92...` and raised findings that were addressed/resolved.
- A final review request on `47f07077...` returned the Codex usage-limit message before analysis.
- Therefore no Codex pass is claimed for `47f07077...`; PR #491 records the manual exact-head diff/contract review used as fallback.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| IA-001 | Medium | Resolved | Canonical docs/ADR previously prohibited any top-level Create Routine action; latest approved UX allows an entry but not orphan persistence. | main@f5e02a22 | ADR-0015 + Library/Programs/Routine docs now distinguish entry action from saved ownership. |
| IA-002 | Medium | Deferred | Stable/idempotent default My Program identity has no current domain/persistence discriminator. | main@f5e02a22 | Separate W1 implementation decision; no schema invented here. |
| IA-003 | Medium | Deferred | Start Empty Workout lower action lacks reconciled Routine/WorkoutSession ownership semantics. | main@f5e02a22 | Resolve before runtime implementation; this docs slice does not redefine Quick Start/session ownership. |
| IA-004 | Medium | Resolved | `workout.md` required Program-first Routine creation while ADR/Library allowed a direct create entry. | PR #491 @ 6729ba36 | `workout.md` now distinguishes direct Routine creation from workout start and preserves Program ownership. |
| IA-005 | Medium | Resolved | Validation block contained `Not run yet` while other handoff fields claimed completed checks. | PR #491 @ 6729ba36 | Replaced with concrete checkpoint/results and explicit exact-head remaining work. |
| IA-006 | Medium | Resolved | Handoff mixed an old ahead-count with a newer SHA. | PR #491 @ 6729ba36 | Handoff uses a named stable content checkpoint and separates it from live PR-head validation. |
| IA-007 | Medium | Resolved | Workout status omitted the already shipped Programs collection/create route/foundation. | PR #491 @ 0e194c57 | `workout.md` now distinguishes shipped Programs foundation from pending detail/Routine work. |
| IA-008 | Medium | Resolved | ROADMAP still allowed Routine creation only from inside Program flow. | PR #491 @ 0e194c57 | ROADMAP now includes the guarded Library-level Create Routine entry and preserves Program ownership/start invariants. |
| IA-009 | Medium | Resolved | Workout doc category wording conflicted with Programs → Exercises → conditional Your Plan. | PR #491 @ 0e194c57 | `workout.md` now uses the same order and conditional visibility as Library. |
| IA-010 | Medium | Resolved | Target acceptance did not require approved Routine/Explore quick actions when capabilities are ready. | PR #491 @ 0e194c57 | `library.md` now makes each quick action required when its prerequisite capability is real and forbids fake affordances before readiness. |
| IA-011 | Medium | Resolved | Active handoff summary referenced an older validated checkpoint than the Quality Review block. | PR #491 @ 5371bc92 | Summary and validation now use stable content checkpoint `f21e7573...`; live exact-head evidence remains in PR #491. |
| IA-012 | Low | Resolved | Next action said three threads while four current finding IDs were listed. | PR #491 @ 5371bc92 | Next action now requires all four current threads. |
| IA-013 | Medium | Resolved | Several finding rows used noncanonical `Addressed / re-review pending` status. | PR #491 @ 5371bc92 | Prior validated findings use `Resolved`; current findings remain `Open` until clean exact-head re-review. |
| IA-014 | Medium | Resolved | Future Exercises category left the shipped catalog browse path undefined. | PR #491 @ 5371bc92 | Three default entries remain unchanged; secondary Browse exercises opens canonical `/workout/exercises`. |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/gh-475-library-ia-reconciliation.md`
- `.ai/tasks/README.md`
- `docs/adr/0015-program-owned-routine-and-program-source-boundary.md`
- `docs/planning/ROADMAP.md`
- `docs/screens/library.md`
- `docs/screens/programs.md`
- `docs/screens/routine-library.md`
- `docs/screens/exercise-search.md`
- `docs/screens/workout.md`

External tracker reconciliation also updated GitHub #475 and Linear TNYX-83/TNYX-267.

### Actual Behavior

No runtime behavior changes in this slice. Current Library still uses the existing Programs/Exercises navigation rows and dedicated routes.

### Known Limitations

Full #475 UI remains dependency/capability gated.

### Final Status

`VALIDATED`
