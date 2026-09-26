# TNYX-271 — App startup path organization

**Status:** Validated
**Completion date:** 2026-09-25
**Primary owner:** `apps/app` startup/composition root
**Affected platforms:** Flutter phone app (Android + iOS)

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Owner explicitly authorized this bounded child slice on 2026-09-25 with "Go follow agent.md" and requested small Linear + GitHub trackers. Parent TNYX-201 / GitHub #260 separately requires explicit owner authorization before every source slice; that authorization is satisfied for this child only.
**Approved product/UI/data-shape boundaries:** Internal path organization only. No product-visible behavior, UI/UX, routing, provider semantics, persistence, or data-shape change.
**Explicit non-changes:** No `router.dart` split; no `network_providers.dart` split; no controller ownership migration; no route/deep-link change; no provider rename/lifetime change; no Supabase schema/RLS/Storage/Edge Function change; no runtime configuration semantic change; no feature-package source change; no speculative folders beyond `apps/app/lib/app/startup/`.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Not assigned
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-26 archive reconciliation. PR #338 is merged, GitHub #337 is closed, Linear TNYX-271 is Done, and current `main` is `ad3f69e3a2f04078a081eed39ac2887b9429bafa`.
**Branch:** `tnyx/tnyx-271-a1-group-app-startup-runtime-files-under-appstartup` (merged via PR #338; remote branch no longer exists).
**HEAD SHA:** final PR head `34f1780d25443171a0de5264c4cd18141bd0d822`; squash-merged to `main` as `f5bf3c4f8aefd176bf393e0bdad8d98ab01abb45`.
**Observed working-tree state:** Not applicable in this tool session. Changes are applied directly through the GitHub remote API, so there is no local working tree to inspect with `git status --short --branch`. Remote base/head, branch collision, open PR state, and exact file SHAs were inspected instead.
**Observed uncommitted/dirty files:** Not applicable to remote GitHub API execution.
**PR / tracker:** PR #338 merged; Linear TNYX-271 is Done; GitHub #337 closed; parents TNYX-201 / GitHub #260 remain open for later slices.
**Current implementation state:** Complete and merged. The startup trio lives under `app/startup/`; live imports/tests and the modular-tree reference are reconciled.
**Relevant execution surface:** `apps/app/lib/app/bootstrap.dart`, `apps/app/lib/app/startup_hydration.dart`, `apps/app/lib/app/supabase_runtime_config.dart`, their live imports/tests, and current canonical path documentation.
**Validation completed at SHA:** final PR head `34f1780d25443171a0de5264c4cd18141bd0d822` — Flutter CI #2727 / run `36050640590` completed successfully; API scope review confirmed only the 10 task-scoped files and 0 unresolved review threads. Required attribution guard had passed; supplemental GHAS infrastructure/model failure produced no code-scanning finding.
**Validation remaining:** None.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** None for A1.

## Global UI / Design-System Guardrail

This is a non-visual path-only refactor. No Flutter production UI implementation or rendered value changes are authorized. Existing UI is untouched.

## 1. Discovery

### User Outcome

Keep the phone app composition root easier to navigate by grouping clearly startup-owned runtime files without changing behavior.

### Success Criteria

- Three startup-owned files live under `apps/app/lib/app/startup/`.
- Live production/test imports resolve to the new paths.
- No startup, Supabase runtime-config, UI, routing, provider, persistence, or schema behavior changes.
- Historical validated evidence is not rewritten merely because a later refactor moved a path.

### Scope

Move only:

```text
apps/app/lib/app/bootstrap.dart
apps/app/lib/app/startup_hydration.dart
apps/app/lib/app/supabase_runtime_config.dart
```

to:

```text
apps/app/lib/app/startup/bootstrap.dart
apps/app/lib/app/startup/startup_hydration.dart
apps/app/lib/app/startup/supabase_runtime_config.dart
```

Update required relative imports, production/test imports, and only current canonical documentation that intentionally describes the live tree.

### Non-Goals

- Broad root-folder cleanup.
- `router.dart` or `network_providers.dart` decomposition.
- Moving `AppOnboardingController`, `CalendarPreferencesController`, Profile helpers, theme/preferences, or any feature-owned behavior.
- Any UI/UX, route, data, Supabase, backend, or public-provider-contract change.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`; `.ai/workflow.md`; `.ai/tasks/README.md`; `.ai/tasks/TEMPLATE.md`; `.ai/FEATURE_DEVELOPMENT.md`; root `README.md`; `docs/ARCHITECTURE.md`; `docs/MODULE_OWNERSHIP.md`; Linear TNYX-201; GitHub #260; current main source for all three target files; live import/reference search.
- Existing pattern to follow: `apps/app` canonically owns phone bootstrap, startup, provider composition, and runtime implementation selection. Existing responsibility folders under `apps/app/lib/app/` establish grouping by app-shell concern.
- Tests or validation already present: `apps/app/test/app/startup_hydration_test.dart` and `apps/app/test/app/supabase_runtime_config_test.dart`; app-wide analyze/test is required by parent #260.
- No package-local `apps/app/AGENTS.md` exists; root `AGENTS.md` applies.
- Current base: `main@0f0851901f3ffbd6f663a1803f9ca642ccb07095`.
- No open TNYX-201 branch/PR existed at readiness time.

### Current classification

| Current file | Current responsibility | Canonical owner | Classification | Target | Action | Risk/tests |
| --- | --- | --- | --- | --- | --- | --- |
| INFRA-1 | Info | Deferred | Supplemental `github-advanced-security` failed before code analysis because configured model was unsupported. | `3fda7d52` | No source fix; log shows `400 The requested model is not supported`. Required product CI remains separate. |
| `app/bootstrap.dart` | tiny `runApp` bootstrap wrapper | `apps/app` | APP COMPOSITION | `app/startup/bootstrap.dart` | Move | compile/import check |
| `app/startup_hydration.dart` | startup load coordination for existing controllers | `apps/app` | APP COMPOSITION | `app/startup/startup_hydration.dart` | Move | existing startup hydration tests |
| `app/supabase_runtime_config.dart` | client-safe runtime configuration + initialization | `apps/app` | APP COMPOSITION | `app/startup/supabase_runtime_config.dart` | Move | existing runtime-config tests |

Known live references before mutation:

- `apps/app/lib/main.dart` imports all three.
- `apps/app/lib/app/network_providers.dart` imports `supabase_runtime_config.dart`.
- `apps/app/test/app/startup_hydration_test.dart` imports `startup_hydration.dart`.
- `apps/app/test/app/supabase_runtime_config_test.dart` imports `supabase_runtime_config.dart`.
- `docs/FLUTTER_MODULAR_STRUCTURE.md` contains a current tree reference to `bootstrap.dart`; classify before changing.
- `.ai/tasks/production-hardening-configuration-cleanup.md` is historical validation evidence and is not rewritten solely for the later path move.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
| --- | --- | --- | --- |
| Use one child slice for exactly the startup trio | Approved | Smallest coherent responsibility cluster already named in #260 target direction | Owner |
| Preserve file contents/behavior | Locked | This is organization-only | Owner / repository governance |
| Do not touch suspicious controllers/helpers | Locked | Ownership decisions belong to later dedicated slices | TNYX-201 / #260 |
| Do not rewrite historical validated task evidence paths | Locked | Historical records describe the tree at their validation SHA | Repository governance |

## 4. Architecture Design

### Chosen Approach

Use a single real folder, `apps/app/lib/app/startup/`, because the current slice immediately moves three concrete app-startup files into it. No empty/speculative structure is created.

Only import paths and relative imports required by the physical move may change.

### Ownership and Data Flow

```text
main.dart
  -> app/startup/bootstrap.dart
  -> app/startup/startup_hydration.dart
  -> app/startup/supabase_runtime_config.dart

network_providers.dart
  -> app/startup/supabase_runtime_config.dart
```

Feature/domain owners remain unchanged.

### Alternative Rejected

Move only one file at a time: rejected because all three files are already unambiguously app-startup-owned and the parent target explicitly groups them together; splitting them into three near-empty PRs would add tracker/merge overhead without reducing ownership risk.

### Failure and Accessibility States

No user-visible or accessibility state changes. Import/path mistakes must fail analysis/tests rather than be masked by compatibility shims.

## 5. Implementation Plan

- [x] Create `apps/app/lib/app/startup/` by moving the three approved files.
- [x] Fix relative imports in moved files.
- [x] Update live production/test imports.
- [x] Classify and update current canonical live-tree docs only if needed.
- [x] Confirm known live old-path references from the readiness audit are updated; historical validated evidence remains intentionally unchanged.
- [x] Run focused + app validation and diff hygiene.
- [x] Review exact branch diff against #337 scope.
- [x] Reconcile Linear/GitHub/task handoff through Draft PR creation; final status remains In Progress while exact-head CI is pending.

## 6. Quality Review

### Validation Run

```text
Remote/API validation at PR checkpoint 3fda7d52:
- Draft PR: #338
- base/merge-base: main@0f0851901f3ffbd6f663a1803f9ca642ccb07095
- ahead / behind: 14 / 0
- changed files: 10, all TNYX-271 scoped
- complete PR diff reviewed; three startup source files recognized as renames
- no UI, route, provider-contract, schema, or feature-package source diff
- Commit attribution guard: PASS
- Flutter CI: Flutter analyze PASS; Dart analyze PASS; tests still running at checkpoint
- github-advanced-security: infrastructure/model failure before analysis (400 requested model not supported); no code finding
- local flutter analyze/test and git diff --check: not runnable in this remote GitHub connector environment
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
| --- | --- | --- | --- | --- | --- |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-271-app-startup-organization.md`
- `apps/app/lib/app/network_providers.dart`
- `apps/app/lib/app/startup/bootstrap.dart` (rename)
- `apps/app/lib/app/startup/startup_hydration.dart` (rename + relative imports)
- `apps/app/lib/app/startup/supabase_runtime_config.dart` (rename)
- `apps/app/lib/main.dart`
- `apps/app/test/app/startup_hydration_test.dart`
- `apps/app/test/app/supabase_runtime_config_test.dart`
- `docs/FLUTTER_MODULAR_STRUCTURE.md`

### Actual Behavior

Runtime behavior is intentionally unchanged. Only file locations/import paths and the current modular-tree documentation were updated.

### Known Limitations

Remote GitHub API execution has no local working tree, so local `git status --short --branch` cannot be observed in this session. This does not affect the user's local checkout because all edits are isolated to the newly created remote task branch.

### Final Status

`PASS`: merged via PR #338 as `f5bf3c4f8aefd176bf393e0bdad8d98ab01abb45` on 2026-09-25T05:44:19Z (UTC). Final PR head `34f1780d` passed Flutter CI #2727, 0 unresolved review threads remained, GitHub #337 closed, and Linear TNYX-271 is Done.
