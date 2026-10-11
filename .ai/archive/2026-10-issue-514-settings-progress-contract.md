# GitHub #514 — Settings ↔ Progress contract-only public dependency

**Status:** Validated
**Completed:** 2026-10-11
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
**Implementation ownership state:** Closed; merged implementation archived
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub `main@5aeba4540dcc0b461096cd6d657377336f388f3e` on 2026-10-11 (remote verified; no local checkout)
**Branch:** `tnyx/issue-514-settings-progress-contract`
**Final reviewed PR HEAD:** `379b31cf7e5b934e3f15eeae1855f3636af641b9`. All required exact-head checks and Codex review passed before merge; squash commit on `main` is `5aeba4540dcc0b461096cd6d657377336f388f3e`.
**Observed working-tree state:** Connector-only execution; no local checkout/status available.
**Observed uncommitted/dirty files:** Not observable; GitHub branch was created from exact main.
**PR / tracker:** PR #515 merged (squash) as `5aeba4540dcc0b461096cd6d657377336f388f3e`; GitHub #514 auto-closed as completed; parent #260/#357 and broader Linear TNYX-154/TNYX-201 remain separate/open; TNYX-155 out of scope.
**Current implementation state:** Narrow `progress_contracts.dart` publishes two Progress domain files; two Settings page imports and two focused tests consume it. Boundary guard now checks both Settings production `lib/` and `test/`. Canonical ownership decision recorded; original broad Progress barrel and app composition unchanged.
**Relevant execution surface:** `apps/features/progress/lib`, `apps/features/settings/lib/src/presentation/pages`, focused Settings tests, canonical module ownership document.
**Validation completed at SHA:** exact final PR HEAD `379b31cf7e5b934e3f15eeae1855f3636af641b9`: Flutter CI #3061 / run `38131250858` PASS (Flutter/Dart analyze and tests), Commit attribution guard PASS, Attribution guard runner PASS, Codex clean `Didn't find any major issues` (PR comment #6107982137); 0 unresolved threads, 17 ahead/0 behind, exactly eight approved paths, mergeable true. Merged as `5aeba4540dcc0b461096cd6d657377336f388f3e`; remote `main` and the closed GitHub #514 verified. Earlier manual review #5482373566 had no blockers, and its only guard note was resolved at `3224ed2e1ed1dac9d1a54b6cf42d26ea0a6daac9`.
**Validation remaining:** None for merged GitHub #514. The operator-provided Windows PowerShell output confirms a clean pre-sync local `main`, successful `git fetch origin --prune` and `git pull --ff-only origin main`, with both `HEAD` and `origin/main` resolving to `5aeba4540dcc0b461096cd6d657377336f388f3e`. A separate post-sync `git status` and local Flutter analyze/tests were not observed; these are not claimed.
**Current blocker:** None for merged #514. The old Codex quota message was superseded by clean exact-head reviews. Broader TNYX-154 remains In Progress, not Done.
**Open review finding IDs:** None.
**Next exact action:** Use `main@5aeba4540dcc0b461096cd6d657377336f388f3e` or newer verified main for any separately approved TNYX-154/TNYX-201 slice; inspect active trackers/docs/source first. No implementation action remains in GitHub #514.

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
- TNYX-154: In Progress on 2026-10-11 (was Backlog before this bounded child), option A is an explicitly supported safe outcome; TNYX-201 remains In Progress, #260/#357 open.
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
- [x] Add contract-only public barrel and switch Settings imports.
- [x] Add focused regression guard.
- [x] Update canonical ownership documentation.
- [x] Audit exact changed-file scope (eight paths only).
- [x] Open Draft PR #515.
- [x] Flutter CI #3056 full PASS at reviewed head `ec3239d89...`.
- [x] Manual COMMENTED review recorded; no blocking findings.
- [x] Improve import guard to scan both `lib/` and `test/`.
- [x] Flutter CI #3058 full PASS on exact source/review head `e16ecee...`.
- [x] Codex exact-head review clean on `e16ecee...`; unresolved threads 0.
- [x] Flutter CI #3059 full PASS and Codex clean on `bc508abab4...` (latest pre-refresh exact HEAD); zero unresolved threads.
- [x] Final HEAD `379b31cf7e...` Flutter CI #3061 full PASS, attribution PASS, Codex clean, threads 0; Ready for Review verified.
- [x] Owner-authorized squash merge of PR #515 as `5aeba4540dcc0b461096cd6d657377336f388f3e`; main and issue #514 verified.

## 6. Quality Review

### Validation Run

```text
Static GitHub compare: eight changed paths exactly (task brief, Progress contract barrel, two Settings pages, two Settings focused widget tests, one boundary guard, Module Ownership doc). `progress.dart` unchanged. No routes, persistence, providers, app code or visible UI changed.

Flutter CI #3054 initially failed `dangling_library_doc_comments`; fixed in `80f4ab620a...` without export changes. CI #3055 cancelled on new commit. Flutter CI #3056 passed full Flutter/Dart analyze/tests on `ec3239d89...`. Manual PR review #5482373566 found no blockers but noted a test-root scanning gap; scoped guard-only change at `3224ed2e...` now includes `test/` as well as `lib/`. Flutter CI #3058 / run `38129864107` PASS on `e16ecee...` (Flutter/Dart analyze/tests). Codex's earlier quota limit was superseded: exact-head Codex review completed with `Didn't find any major issues` and 0 unresolved threads on `e16ecee...`. Flutter CI #3059 / run `38130482762` later passed every analysis/test step on `bc508abab4...`, with attribution checks PASS and Codex exact-head clean review (#6107857144); 0 threads. The final head `379b31cf7e...` subsequently passed Flutter CI #3061, both attribution checks and Codex exact-head review (0 unresolved threads) and was squash-merged to `main` as `5aeba4540dcc0b461096cd6d657377336f388f3e`. No local Flutter/git execution was performed.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| `CI-3054-LINT` | Analyzer | Resolved | Dangling doc comment on new Progress public barrel | `e7d6100a73d30d3b7c38dfb87481ddc69d7d2d90` | Changed comment to ordinary `//` in `80f4ab620a...`; CI #3055 analysis passed |
| `GATE-CODEX-QUOTA` | Review gate | Resolved | Initial Codex review request hit usage quota, with no review returned at that time | earlier PR head | Superseded by completed clean Codex reviews at `e16ecee...` and `bc508abab4...` (PR comment #6107857144) |
| `MANUAL-515-1` | Hardening | Resolved | Source-only architecture guard missed test-side imports (non-blocking) | Manual review #5482373566, `ec3239d89...` | Guard updated to scan Settings `lib/` + `test/` in `3224ed2e...`; exact-head Flutter CI #3058 PASS, Codex clean |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/issue-514-settings-progress-contract.md`
- `apps/features/progress/lib/progress_contracts.dart`
- `apps/features/settings/lib/src/presentation/pages/{body_weight_settings_page,daily_wellness_settings_page}.dart`
- `apps/features/settings/test/presentation/{body_weight_settings_page,daily_wellness_settings_page}_test.dart`
- `apps/features/settings/test/architecture/progress_contract_boundary_test.dart`
- `docs/architecture/MODULE_OWNERSHIP.md`

### Actual Behavior

No runtime behavior change intended.

### Known Limitations

GitHub-hosted Flutter CI #3061 passed full Flutter/Dart analysis and tests on the reviewed PR #515 HEAD `379b31cf7e5b934e3f15eeae1855f3636af641b9`, before squash merge. This is completed validation, not a pending gate. No local Flutter test/analyze or `git diff --check` result is claimed; owner-provided PowerShell output verifies local fast-forward sync to the merged `main` commit.

### Final Status

`VALIDATED` (PR #515 squash-merged as `5aeba4540dcc0b461096cd6d657377336f388f3e`; source and final-head review gate passed, GitHub #514 closed; broader TNYX-154 In Progress)
