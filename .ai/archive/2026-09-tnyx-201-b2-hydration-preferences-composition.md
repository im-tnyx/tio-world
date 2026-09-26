# TNYX-201 B2 — HydrationPreferences Composition Split

**Status:** Validated
**Completion date:** 2026-09-26
**Primary owner:** apps/app composition root
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Approved
**Approval evidence:** Owner requested on 2026-09-26: “Next go”.
**Approved product/UI/data-shape boundaries:** Internal app composition refactor only.
**Explicit non-changes:** No provider rename/type/lifetime/override change; no HydrationPreferences default/storage/session behavior change; no Wellness/Body/Profile/Workout/Nutrition/Onboarding extraction; no Calendar Preferences work; no router work; no UI/UX change; no Supabase/schema/backend change.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-26 after PR #363 squash merge; GitHub `main` is `05dd852bbfe6fefd6f6817b983f66db0ee059c20`.
**Branch:** `tnyx/tnyx-201-b2-hydration-preferences-composition` (merged via PR #363; remote branch still exists at this archive checkpoint because the current connector exposes no branch-delete action).
**HEAD SHA:** final reviewed PR head `3b99f1a6bd48286d6a0aeace9434277e060acd75`; squash-merged to `main` as `05dd852bbfe6fefd6f6817b983f66db0ee059c20`.
**Observed working-tree state:** No local worktree exists in this API-backed session; remote branch/main ancestry and changed-file delta are used as safety evidence.
**Observed uncommitted/dirty files:** Not applicable in API-backed session
**PR / tracker:** PR #363 merged; GitHub #362 closed by merge; Linear TNYX-201 / GitHub #260 remain the open umbrella; GitHub #357 remains planning-only Slice C.
**Current implementation state:** Complete and merged. The three HydrationPreferences providers live in `app/composition/hydration_preferences_providers.dart`; `network_providers.dart` re-exports them and retains all remaining composition.
**Relevant execution surface:** `apps/app/lib/app/network_providers.dart`, `apps/app/lib/app/hydration_preferences_session_boundary.dart`, new `apps/app/lib/app/composition/hydration_preferences_providers.dart`
**Validation completed at SHA:** exact reviewed head `3b99f1a6bd48286d6a0aeace9434277e060acd75` — Flutter CI #2769 / run `36217727528`: bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests all passed. Runtime/source checkpoint `304c18a6` also passed full CI #2768 after removing the one stale unused import found by CI #2767.
**Validation remaining:** None for B2.
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** None for B2. Any later provider group or router work requires a fresh current-head audit and separate owner authorization under #260/TNYX-201.

## Global UI / Design-System Guardrail

No production UI is in scope. Existing rendered behavior must remain unchanged.

## 1. Discovery

### User Outcome

Continue #260 Slice B with the smallest ownership-safe decomposition of `network_providers.dart`.

### Success Criteria

- Settings-owned HydrationPreferences composition has a dedicated app-composition file.
- Existing `network_providers.dart` consumers remain source-compatible.
- Hydration persistence and explicit account-boundary clearing behavior remain unchanged.
- No Wellness or other feature composition moves in B2.

### Scope

Move only:

- `hydrationPreferencesRepositoryProvider`
- `hydrationPreferencesSessionBoundaryProvider`
- `hydrationPreferencesDataProvider`

to:

`apps/app/lib/app/composition/hydration_preferences_providers.dart`

### Non-Goals

- no Wellness/Body/Profile/Workout/Nutrition/Onboarding provider extraction
- no Calendar Preferences consolidation
- no consumer import migration
- no provider redesign
- no router/UI/persistence/schema changes

## 2. Codebase Exploration

### Verified Evidence

- Read root `AGENTS.md`, `.ai/workflow.md`, `.ai/tasks/TEMPLATE.md`, `docs/ARCHITECTURE.md`, `docs/MODULE_OWNERSHIP.md`, GitHub #260/#362, Linear TNYX-201 and current source.
- Current base: `main@509c9ba55388ab1c2eecc77a4b9d4e78b7688283`.
- `network_providers.dart`: 314 lines, blob `fae0f14644afdf61c15b20f4335cdbc5511cc8a7`.
- Canonical ownership: `HydrationPreferences`, repository contract and SharedPreferences adapter belong to Settings; `apps/app` constructs/injects the adapter and owns explicit account-boundary composition.
- Wellness targets belong to Progress and are explicitly excluded.
- Existing consumers import moved symbols through `package:tio_app/app/network_providers.dart`.
- Existing coverage includes hydration session-boundary, Daily Wellness route, Body & Weight route, App Mode/router, onboarding logout and network provider tests.

## 3. Clarification

| Decision | Status | Rationale | Owner |
| --- | --- | --- | --- |
| Extract HydrationPreferences before Wellness | Made | Ownership is explicit and dependency surface is smaller | #260/TNYX-201 |
| Use a precise `hydration_preferences_providers.dart` file | Made | Avoids a new broad catch-all Settings composition file | apps/app |
| Keep `network_providers.dart` re-export | Made | Preserves current source compatibility and minimizes B2 diff | apps/app |

## 4. Architecture Design

### Chosen Approach

```text
apps/app/lib/app/composition/
├─ runtime_providers.dart
├─ auth_providers.dart
└─ hydration_preferences_providers.dart
```

The new file owns only app-shell provider construction for the Settings-owned HydrationPreferences contract and app-owned session-boundary wrapper.

`network_providers.dart` imports/exports this module and keeps all remaining feature composition.

### Ownership and Data Flow

```text
Settings HydrationPreferences contract/data adapter
        ↓
apps/app composition provider construction
        ↓
HydrationPreferencesSessionBoundary / UI-route consumers
```

### Alternative Rejected

Bundling Wellness targets with HydrationPreferences was rejected because canonical ownership assigns Wellness to Progress and HydrationPreferences to Settings.

## 5. Implementation Plan

- [x] create `composition/hydration_preferences_providers.dart`
- [x] remove only the three approved provider definitions from `network_providers.dart`
- [x] import/re-export the new composition file
- [x] remove now-unused Settings/session-boundary imports from `network_providers.dart`
- [x] preserve all existing consumers
- [x] audit exact branch delta
- [x] obtain focused/app validation and CI
- [x] reconcile GitHub/Linear/task state for review

## 6. Quality Review

### Validation Run

```text
Flutter CI #2768 / run 36217231609 @ 304c18a63b40a60b73789a25ff5ca47f26d191fc
- Bootstrap workspace: PASS
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS

Initial CI #2767 failed only because `network_providers.dart` still imported the new composition file while using it only as an export. Commit 304c18a6 removed that stale import; no provider logic changed.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
| --- | --- | --- | --- | --- | --- |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-b2-hydration-preferences-composition.md`
- `apps/app/lib/app/composition/hydration_preferences_providers.dart`
- `apps/app/lib/app/network_providers.dart`

### Actual Behavior

No product/runtime behavior change is intended. Existing consumers continue importing the same provider symbols through `network_providers.dart`; only ownership location changed. `network_providers.dart` dropped from 314 to 294 lines after the unused-import cleanup.

### Known Limitations

Local Flutter tooling was unavailable in this connector-only session, so GitHub CI supplied executable validation. The B2 source branch still exists remotely at this archive checkpoint because the current GitHub connector does not expose branch deletion.

### Final Status

`PASS`: merged via PR #363 as `05dd852bbfe6fefd6f6817b983f66db0ee059c20` on 2026-09-26T04:34:40Z (UTC). Exact review head `3b99f1a6` passed Flutter CI #2769 with 0 unresolved review threads; GitHub #362 closed on merge. TNYX-201/#260 remain open for later separately authorized slices.
