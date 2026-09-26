# TNYX-201 B3 — Workout Composition Split

**Status:** In progress
**Primary owner:** apps/app composition root
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Approved
**Approval evidence:** Owner requested on 2026-09-26: “Go”.
**Approved product/UI/data-shape boundaries:** Internal app composition refactor only.
**Explicit non-changes:** No provider rename/type/lifetime/override change; no Supabase/in-memory selection change; no Profile/Wellness/Body/Nutrition/Onboarding extraction; no router work; no Workout feature source change; no UI/UX change; no Supabase/schema/backend change.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub main `c47094f85ba3e02ccce999a12efe5c8398ee2cd4`; no open TNYX-201 implementation PR/branch existed before B3 branch creation.
**Branch:** `tnyx/tnyx-201-b3-workout-composition`
**HEAD SHA:** runtime/source checkpoint `5edce0e9afb7ce1c84c0d7d2a825b7ca78dd9550`; this handoff update is documentation-only
**Observed working-tree state:** No local worktree exists in this API-backed session; remote branch/main ancestry and changed-file delta are used as safety evidence.
**Observed uncommitted/dirty files:** Not applicable in API-backed session
**PR / tracker:** Linear TNYX-201; GitHub #260 parent; GitHub #365; PR #366 ready for review; GitHub #357 remains planning-only
**Current implementation state:** B3 source extraction complete. The two Workout providers now live in `app/composition/workout_providers.dart`; `network_providers.dart` re-exports them and retains all remaining composition.
**Relevant execution surface:** `apps/app/lib/app/network_providers.dart`, new `apps/app/lib/app/composition/workout_providers.dart`, Product Onboarding completion provider consumer
**Validation completed at SHA:** runtime/source checkpoint `5edce0e9afb7ce1c84c0d7d2a825b7ca78dd9550` passed Flutter CI #2771 / run `36218676430`; review checkpoint `beb62a26f77dd582ed08cee49f93ac1cd7298be8` passed exact-head Flutter CI #2772 / run `36219154979`, including bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests.
**Validation remaining:** No implementation validation remains. Live PR checks remain the merge gate; do not rerun CI solely because this handoff text is corrected unless repository automation does so automatically.
**Current blocker:** None
**Open review finding IDs:** `PRRT_kwDOTOXwB86mOCSv` — P2 stale final handoff; addressed by this documentation-only correction and pending thread recheck/resolution.
**Next exact action:** Recheck the live review thread and PR checks, resolve the addressed P2 finding when verified, then stop at the merge decision. No next implementation slice starts before B3 is merged/post-merge reconciled.

## Global UI / Design-System Guardrail

No production UI is in scope. Existing rendered behavior must remain unchanged.

## 1. Discovery

### User Outcome

Continue #260 Slice B with the next smallest ownership-safe decomposition of `network_providers.dart`.

### Success Criteria

- Workout-owned repository composition has a dedicated app-composition file.
- Product Onboarding completion continues to read the same provider symbols.
- Existing `network_providers.dart` consumers remain source-compatible.
- No other provider group moves in B3.

### Scope

Move only:

- `workoutProfileRepositoryProvider`
- `workoutTargetsRepositoryProvider`

to:

`apps/app/lib/app/composition/workout_providers.dart`

### Non-Goals

- no Profile/Wellness/Body/Nutrition/Onboarding provider extraction
- no Workout feature-package source change
- no consumer import migration
- no provider redesign
- no router/UI/persistence/schema changes

## 2. Codebase Exploration

### Verified Evidence

- Read root `AGENTS.md`, applicable feature agent rules, `.ai/workflow.md`, `.ai/tasks/TEMPLATE.md`, `docs/ARCHITECTURE.md`, `docs/MODULE_OWNERSHIP.md`, GitHub #260/#365, Linear TNYX-201 and current source.
- Current base: `main@c47094f85ba3e02ccce999a12efe5c8398ee2cd4`.
- `network_providers.dart`: 294 lines, blob `58e73795e8c6e1bd5cfb6eb8a512ebe0fc3fd41d`.
- Workout Profile and Workout Targets contracts/adapters belong to `apps/features/workout`.
- `apps/app` only selects Supabase vs in-memory implementations and exposes them to Product Onboarding completion.
- Current direct app consumers: `onboarding/onboarding_completion_use_case_provider.dart` and `network_providers_test.dart`.
- No open TNYX-201 implementation PR or branch existed before B3 branch creation.

## 3. Clarification

| Decision | Status | Rationale | Owner |
| --- | --- | --- | --- |
| Extract Workout before Body/Wellness | Made | Workout pair is independent; Body/Wellness has a cross-owner adapter | #260/TNYX-201 |
| Keep Workout pair together | Made | Both share the same feature owner and runtime selection pattern | apps/app |
| Keep `network_providers.dart` re-export | Made | Preserves current source compatibility and limits B3 diff | apps/app |

## 4. Architecture Design

### Chosen Approach

```text
apps/app/lib/app/composition/
├─ runtime_providers.dart
├─ auth_providers.dart
├─ hydration_preferences_providers.dart
└─ workout_providers.dart
```

`workout_providers.dart` owns only app-shell construction/selection for Workout-owned repository contracts.

`network_providers.dart` re-exports the module and keeps all remaining feature composition.

### Ownership and Data Flow

```text
Supabase runtime availability
        ↓
apps/app workout provider composition
        ↓
Workout-owned repositories
        ↓
Product Onboarding completion consumer
```

### Alternative Rejected

Moving Body/Wellness next was rejected for B3 because `bodySetupRepositoryProvider` currently composes a cross-owner Body+Wellness adapter and requires a broader ownership-safe split.

## 5. Implementation Plan

- [x] create `composition/workout_providers.dart`
- [x] remove only the two approved provider definitions from `network_providers.dart`
- [x] re-export the new composition file
- [x] remove now-unused Workout import from `network_providers.dart`
- [x] preserve all existing consumers
- [x] audit exact branch delta
- [x] obtain focused/app validation and CI
- [ ] reconcile GitHub/Linear/task state for review

## 6. Quality Review

### Validation Run

```text
Flutter CI #2771 / run 36218676430 @ 5edce0e9afb7ce1c84c0d7d2a825b7ca78dd9550
- Bootstrap workspace: PASS
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
| --- | --- | --- | --- | --- | --- |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-b3-workout-composition.md`
- `apps/app/lib/app/composition/workout_providers.dart`
- `apps/app/lib/app/network_providers.dart`

### Actual Behavior

No product/runtime behavior change is intended. Existing consumers continue importing the same provider symbols through `network_providers.dart`; only ownership location changed. `network_providers.dart` dropped from 294 to 274 lines.

### Known Limitations

Local Flutter tooling is unavailable in this connector-only session; GitHub CI supplies executable validation. Runtime/source validation is complete. This correction changes handoff documentation only and does not invalidate the already-green runtime/source checkpoint; live PR checks remain authoritative for the merge gate.

### Final Status

`REVIEW`
