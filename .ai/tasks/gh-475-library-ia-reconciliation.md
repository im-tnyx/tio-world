# GitHub #475 — Workout Library IA reconciliation

**Status:** In progress
**Primary owner:** Workout Library planning/docs (`apps/features/workout` canonical contract)
**Affected platforms:** Flutter phone planning/docs only in this slice

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + approved product-visible UI/UX direction
**Approval status:** Approved
**Approval evidence:** Owner approved continuing the bounded reconciliation slice with “Go next” on 2026-09-30 after the audit proposed reconciling GitHub #475, canonical docs/ADR and Linear before any Flutter UI work.
**Approved product/UI/data-shape boundaries:** Reconcile the approved Library IA: Programs default category; Exercises second; conditional Your Plan; Routine + Explore quick actions; Programs visible directly on Library; optional Programs manage route; Program-owned Routine ownership; top-level Routine create entry may exist only if saved Routine resolves to one owning Program; Exercise Favorites/Custom/Folders remain capability-owned; Your Plan remains TrainingPlan-owned.
**Explicit non-changes:** No Flutter runtime/source changes, no router changes, no Supabase schema/RLS/grant changes, no Program/Routine persistence changes, no Custom Exercise/Favorites/Folders implementation, no TrainingPlan implementation, no Program delete implementation, no Start Empty Workout behavior implementation.

## Active Handoff

**Planning owner:** Current repository agent
**Implementation owner:** Current repository agent (docs/tracker reconciliation only)
**Review owner:** Unassigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-30, remote `main@b0dd0990137bcf72221f1f120657359a807a8687`
**Branch:** `tnyx/gh-475-library-ia-reconciliation`
**HEAD SHA:** `b0dd0990137bcf72221f1f120657359a807a8687` at branch creation
**Observed working-tree state:** Remote branch created from clean/synced `main`; no local working-tree mutation is being claimed.
**Observed uncommitted/dirty files:** Not applicable to connector-only repository edits.
**PR / tracker:** GitHub #475; Linear TNYX-83 / TNYX-267 with related TNYX-81, TNYX-263, TNYX-264, TNYX-265, TNYX-268, TNYX-86
**Current implementation state:** Planning/canonical reconciliation active; no runtime implementation started.
**Relevant execution surface:** `docs/screens/library.md`, `docs/screens/programs.md`, `docs/screens/routine-library.md`, ADR-0015, GitHub #475, Linear tracker notes
**Validation completed at SHA:** None yet for this branch.
**Validation remaining:** Changed-file scope audit, stale/conflict wording scan, docs whitespace/conflict-marker checks, PR review.
**Current blocker:** None for docs reconciliation. Full #475 runtime remains blocked by capability sequencing and unresolved default My Program identity implementation / Start Empty Workout semantics.
**Open review finding IDs:** None
**Next exact action:** Reconcile canonical docs/ADR to the latest approved IA without changing runtime behavior, then add Linear reconciliation notes and open a docs-only PR.

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
| Your Plan is hidden without a real followed/applicable TrainingPlan | Approved | Matches W6C/W9 capability gating; no placeholder plan truth | Owner + TNYX-268/TNYX-86 |
| No standalone Routines category | Approved | Preserves Program ownership | ADR-0015 |
| Quick cards are Routine + Explore | Approved | Latest correction supersedes older Exercise + Explore wording | Owner |
| Top-level Create Routine entry may exist | Approved with ownership guard | Entry point is not ownership; saved Routine still requires exactly one Program | Owner + ADR-0015 clarification |
| Direct top-level Routine should use canonical default My Program | Approved product behavior; implementation unresolved | Current Program model has no stable default marker; display-name matching is not sufficient | Owner; W1 follow-up required |
| Programs manage screen may remain secondary | Approved | Program rows still appear directly on Library; individual Program does not require intermediate screen | Owner |
| Exercises category shows capability-owned smart views/folders | Approved target; capability-gated | W3C/W3D/W3E own data; no fake rows before real capability | Owner + Linear |
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
- [ ] Clarify ADR-0015 entry-action vs ownership rule.
- [ ] Update Library canonical target IA and current-runtime distinction.
- [ ] Update Programs/Routine docs for secondary Programs manage screen and guarded direct Routine entry.
- [ ] Add Linear reconciliation note to W6/W6B and relevant dependency trackers as needed.
- [ ] Run docs-only quality/scope checks.
- [ ] Open docs-only PR and wait for review.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| IA-001 | Medium | Open | Current canonical docs/ADR still say there is no top-level Create Routine action; latest approved UX allows the entry but not orphan persistence. | main@b0dd0990 | Resolve in this slice. |
| IA-002 | Medium | Deferred | Stable/idempotent default My Program identity has no current domain/persistence discriminator. | main@b0dd0990 | Separate W1 implementation decision; no schema invented here. |
| IA-003 | Medium | Deferred | Start Empty Workout lower action lacks reconciled Routine/WorkoutSession ownership semantics. | main@b0dd0990 | Resolve before runtime implementation. |

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

No runtime behavior changes in this slice.

### Known Limitations

Full #475 UI remains dependency/capability gated.

### Final Status

`REVIEW`
