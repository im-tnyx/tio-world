# GitHub #514 — Settings ↔ Progress contract-only public dependency

**Status:** In progress
**Primary owner:** `apps/features/progress` public domain contract + `apps/features/settings` consumer
**Affected platforms:** Flutter Android and iOS

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped internal architecture slice
**Approval status:** Approved
**Approval evidence:** Owner said `Next go follow agent.md` on 2026-10-11, proceeding from the prior read-only audit recommending TNYX-201 reconciliation followed by a focused TNYX-154 boundary decision.
**Approved product/UI/data-shape boundaries:** Contract-only import/publishing refactor; no user-visible change.
**Explicit non-changes:** No route/UI/behavior/persistence/Auth/Supabase/migration/API change, no Progress/Settings package restructuring, no Body/Wellness editor relocation.

## Active Handoff

**Planning owner:** ChatGPT architecture workflow
**Implementation owner:** ChatGPT (single owner for this slice)
**Review owner:** Codex on PR
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub `main@dfe9cee7389165f0a485623a1e3e69477eb1dc37` on 2026-10-11
**Branch:** `tnyx/issue-514-settings-progress-contract`
**HEAD SHA:** branch created at `dfe9cee7389165f0a485623a1e3e69477eb1dc37`
**Observed working-tree state:** Connector-only execution; no local checkout/status available.
**Observed uncommitted/dirty files:** Not observable; GitHub branch was created from exact main.
**PR / tracker:** GitHub #514; parent #260/#357; Linear TNYX-154, TNYX-201; TNYX-155 remains separate.
**Current implementation state:** Discovery and bounded architecture choice complete. Source change pending.
**Relevant execution surface:** `apps/features/progress/lib`, `apps/features/settings/lib/src/presentation/pages`, focused Settings tests, canonical module ownership document.
**Validation completed at SHA:** Read-only source/dependency and tracker audit on `main@dfe9cee...`.
**Validation remaining:** Static exact diff audit; hosted Flutter/Dart analyze/tests; Codex exact-head review.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Publish narrow Progress domain barrel, migrate exactly two Settings pages and two tests, add import-boundary regression guard, update ownership doc, open Draft PR.

## 1. Discovery

### User Outcome

Avoid treating the public `progress.dart` mixed domain/data/presentation barrel as a domain contract for Settings; preserve existing Body & Weight and Daily Wellness editors and their route behavior.

### Success Criteria

- Narrow public Progress import exposes only canonical Body/Wellness domain contracts.
- Settings production UI and focused tests no longer import broad Progress entry.
- Existing Progress public barrel and app composition remain unchanged.
- No duplicate Body/Wellness state or repository, no screen move.
- Boundary guard + hosted CI and Codex review pass.

### Scope

One `progress_contracts.dart` public barrel with two existing domain exports; two Settings page imports and two focused test imports; one focused architecture guard; Module Ownership contract clarification.

### Non-Goals

Route extraction, `router.dart` changes, UI/design, Body/Wellness persistence, data adapters, Auth, Supabase/RLS/schema, a new shared package, TNYX-153/TNYX-155 package structure, and unrelated consumers.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md`, `apps/features/AGENTS.md`; no package-specific AGENTS found under Settings/Progress.
- Canonical: `docs/architecture/ARCHITECTURE.md`, `MODULE_OWNERSHIP.md`, `docs/screens/settings.md`.
- TNYX-154: Backlog, option A is an explicitly supported safe outcome; TNYX-201 In Progress, #260/#357 open.
- Runtime `router.dart` remains 862 lines / 4 direct routes on exact main.
- `apps/features/progress/lib/progress.dart` exports domain + `src/data/*` + `src/progress_presentation.dart`.
- `DailyWellnessSettingsPage` consumes `WellnessTargetsData`; `BodyWeightSettingsPage` consumes `BodyState`, `BodyGoalState`, `BodyGoalType`, `BodyGoalUpdate` from Progress.
- Two matching focused Settings tests consume broad `progress.dart` imports. No other Settings package imports of Progress found in repo code search.
- `apps/app/lib/app/composition/body_wellness_providers.dart` already owns concrete Body/Wellness data adapters/provider selection; no relocation needed.
- TNYX-129 and TNYX-133 are Done; TNYX-155/TNYX-153 are Backlog. No overlapping open PR found in issue-specific search.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Choose TNYX-154 option A, narrow public domain barrel | Approved for this child | Preserves direct dependency but narrows visible API to needed contracts | App architecture |
| Keep Settings Body/Wellness presentation in place | Frozen | Existing Settings IA and accepted S0-B1/B4, no UI move required by this contract cleanup | Settings |
| Keep Body/Wellness domain + repositories Progress-owned | Frozen | Canonical owner and existing app provider wiring | Progress |
| Keep broad Progress barrel for app/other consumers | Frozen | Backward-compatibility; avoid unrelated breaking changes | Progress |
| Do not finish all TNYX-154 acceptance in one PR | Frozen | Broader package/route ownership questions remain separate | Planning |

## 4. Architecture Design

### Chosen Approach

Export existing `src/domain/body_setup.dart` and `src/domain/wellness_targets.dart` from one narrow public `package:tio_feature_progress/progress_contracts.dart`. Retarget only four Settings imports to this path. Keep `progress.dart` for app/other existing consumers. Add an import-boundary test that rejects broad/deep Progress imports from Settings.

### Ownership and Data Flow

```text
Settings Body/Wellness editors
  -> Progress contract-only public barrel (domain models/commands)
apps/app Body/Wellness providers
  -> existing Progress repositories/adapters
  -> existing persistence
```

### Alternative Rejected

Moving pages to Progress, adapting to plain DTO copies, moving domain types to `apps/shared`, or moving providers into Settings would widen scope, split canonical state, or require unapproved UI/contract redesign.

### Failure and Accessibility States

All existing load/error/retry/save/validation and accessibility rendering preserved byte-for-byte except import declarations; no new runtime branch.

## 5. Implementation Plan

- [x] Fresh tracker/source ownership audit.
- [x] TNYX-201 current-main planning correction.
- [x] Create bounded issue/branch/task.
- [ ] Add contract-only public barrel and switch Settings imports.
- [ ] Add focused regression guard.
- [ ] Update canonical ownership documentation.
- [ ] Audit exact changed-file scope, open Draft PR.
- [ ] Hosted CI + Codex exact-head gate.

## 6. Quality Review

### Validation Run

```text
Not run. Connector-only; no local working tree or Flutter toolchain.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

No runtime behavior change intended.

### Known Limitations

Cannot claim local `git status`, `flutter analyze`, `flutter test`, or `git diff --check` from connector-only execution. Hosted CI must validate.

### Final Status

`PARTIAL`
