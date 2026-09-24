# TNYX-271 — App startup path organization

**Status:** In progress
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
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** Remote GitHub state verified against `main@0f0851901f3ffbd6f663a1803f9ca642ccb07095`; no matching TNYX-201 branch or open PR existed before branch creation.
**Branch:** `tnyx/tnyx-271-a1-group-app-startup-runtime-files-under-appstartup`
**HEAD SHA:** `0f0851901f3ffbd6f663a1803f9ca642ccb07095` at branch creation; refresh after commits.
**Observed working-tree state:** Not applicable in this tool session. Changes are applied directly through the GitHub remote API, so there is no local working tree to inspect with `git status --short --branch`. Remote base/head, branch collision, open PR state, and exact file SHAs were inspected instead.
**Observed uncommitted/dirty files:** Not applicable to remote GitHub API execution.
**PR / tracker:** Linear TNYX-271; GitHub #337; parents TNYX-201 / GitHub #260.
**Current implementation state:** Readiness audit complete; child trackers created/reconciled; source moves not started.
**Relevant execution surface:** `apps/app/lib/app/bootstrap.dart`, `apps/app/lib/app/startup_hydration.dart`, `apps/app/lib/app/supabase_runtime_config.dart`, their live imports/tests, and current canonical path documentation.
**Validation completed at SHA:** Read-only inspection only; no implementation validation yet.
**Validation remaining:** reference audit, focused tests, `cd apps/app && flutter analyze && flutter test`, `git diff --check`, final exact-head review.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Move the three classified APP COMPOSITION files under `apps/app/lib/app/startup/` and update only required live references.

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

- [ ] Create `apps/app/lib/app/startup/` by moving the three approved files.
- [ ] Fix relative imports in moved files.
- [ ] Update live production/test imports.
- [ ] Classify and update current canonical live-tree docs only if needed.
- [ ] Confirm old live paths/imports have zero references.
- [ ] Run focused + app validation and diff hygiene.
- [ ] Review exact branch diff against #337 scope.
- [ ] Reconcile Linear/GitHub/task handoff.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
| --- | --- | --- | --- | --- | --- |

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Pending. Intended behavior is unchanged.

### Known Limitations

Remote GitHub API execution has no local working tree, so local `git status --short --branch` cannot be observed in this session. This does not affect the user's local checkout because all edits are isolated to the newly created remote task branch.

### Final Status

`PARTIAL`
