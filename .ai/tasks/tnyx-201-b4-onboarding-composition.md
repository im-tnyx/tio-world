# TNYX-201 B4 — Onboarding Composition Split

**Status:** In progress
**Primary owner:** apps/app composition root
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Approved
**Approval evidence:** Owner requested on 2026-09-26: “Next go”.
**Approved product/UI/data-shape boundaries:** Internal app composition refactor only.
**Explicit non-changes:** No feature-owned Onboarding logic/controller/public API change; no provider/function rename/type/lifetime/override change; no API/Supabase selection change; no Profile/Wellness/Body/Nutrition extraction; no router/UI/schema/backend change.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub main `d9edb55be00a7b2a520e3d1cba7fdfa37bd0252d`; B3 merged/archived and B4 is the sole active #260 source slice.
**Branch:** `tnyx/tnyx-201-b4-onboarding-composition`
**HEAD SHA:** runtime/source checkpoint `4f0529c72f430084e1f0f9e1ac148366f97e72be`; this handoff update is documentation-only
**Observed working-tree state:** No local worktree exists in this API-backed session; remote branch/main ancestry and changed-file delta are used as safety evidence.
**Observed uncommitted/dirty files:** Not applicable in API-backed session
**PR / tracker:** Linear TNYX-201; GitHub #260 parent; GitHub #368; Draft PR #369; TNYX-202/#261 separate and out of scope; #357 planning-only
**Current implementation state:** B4 source extraction complete. The four app-owned Onboarding composition symbols now live in `app/composition/onboarding_providers.dart`; `network_providers.dart` re-exports them and retains all remaining composition.
**Relevant execution surface:** `apps/app/lib/app/network_providers.dart`, new `apps/app/lib/app/composition/onboarding_providers.dart`, `apps/app/lib/main.dart`, `apps/app/lib/app/onboarding/onboarding_completion_use_case_provider.dart`
**Validation completed at SHA:** runtime/source checkpoint `4f0529c72f430084e1f0f9e1ac148366f97e72be` — Flutter CI #2776 / run `36222783073`: bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests all passed.
**Validation remaining:** Live PR exact-head CI after this documentation-only handoff update, then review-thread/scope audit. If that exact-head check passes, no further task-brief edit is required; live PR/Linear state is authoritative for the merge gate.
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Revalidate this documentation-only final head; if green, mark PR #369 ready for review, audit review threads and reconcile TNYX-201/#368 without another documentation-only commit.

## Global UI / Design-System Guardrail

No production UI is in scope. Existing rendered behavior must remain unchanged.

## 1. Discovery

### User Outcome

Continue #260 Slice B with the next smallest ownership-safe decomposition of `network_providers.dart`.

### Success Criteria

- app-owned Onboarding runtime composition has a dedicated composition module;
- current consumers keep the same provider/function symbols;
- internal `apps/features/onboarding` architecture remains untouched;
- no other provider group moves in B4.

### Scope

Move only:

- `onboardingRemoteFinalizerProvider`
- `appOnboardingDraftRepositoryProvider`
- `buildAppOnboardingCompletionValidator`
- `appOnboardingCompletionValidatorProvider`

to:

`apps/app/lib/app/composition/onboarding_providers.dart`

### Non-Goals

- no TNYX-202/#261 implementation
- no OnboardingController/provider/factory change inside feature package
- no public Onboarding API/barrel cleanup
- no consumer import migration
- no router/UI/persistence/schema redesign
- no other provider group extraction

## 2. Codebase Exploration

### Verified Evidence

- Read root `AGENTS.md`, `.ai/workflow.md`, task template, canonical ownership docs, #260/#368, TNYX-201 and TNYX-202.
- No nested `apps/app/AGENTS.md` or `apps/features/onboarding/AGENTS.md` exists; root rules apply.
- Current base: `main@d9edb55be00a7b2a520e3d1cba7fdfa37bd0252d`.
- `network_providers.dart`: 274 lines, blob `f86c67e53efcf90839af1c5681cee9aea43bfcf0`.
- TNYX-202 explicitly assigns `apps/app` composition-root cleanup to TNYX-201/#260 and keeps internal Onboarding package organization in TNYX-202/#261.
- Known consumers: `main.dart`, `onboarding_completion_use_case_provider.dart`, and `network_providers_test.dart`.
- After this extraction, `network_providers.dart` should no longer need `package:tio_feature_onboarding/onboarding.dart`.

## 3. Clarification

| Decision | Status | Rationale | Owner |
| --- | --- | --- | --- |
| Keep all four app composition seams together | Made | Same feature boundary; all are app-shell runtime composition | apps/app |
| Do not move feature-package providers/controllers | Made | TNYX-202 owns internal Onboarding package cleanup | TNYX-201/TNYX-202 |
| Keep `network_providers.dart` re-export | Made | Preserve current source compatibility | apps/app |

## 4. Architecture Design

### Chosen Approach

```text
apps/app/lib/app/composition/
├─ runtime_providers.dart
├─ auth_providers.dart
├─ hydration_preferences_providers.dart
├─ workout_providers.dart
└─ onboarding_providers.dart
```

`onboarding_providers.dart` owns only app-shell concrete runtime composition for Onboarding.

### Ownership and Data Flow

```text
Auth/API + Supabase runtime
        ↓
apps/app Onboarding composition
        ↓
Onboarding feature contracts
        ↓
main/bootstrap + completion use-case consumers
```

### Alternative Rejected

Moving OnboardingController/provider definitions from `apps/features/onboarding` was rejected because that is internal package architecture owned by TNYX-202/#261.

## 5. Implementation Plan

- [x] create `composition/onboarding_providers.dart`
- [x] move only the four approved symbols unchanged
- [x] re-export the new composition module from `network_providers.dart`
- [x] remove now-unused Onboarding import from `network_providers.dart`
- [x] preserve all existing consumers
- [x] audit exact branch delta
- [x] obtain focused/app validation and CI
- [ ] reconcile GitHub/Linear/task state for review

## 6. Quality Review

### Validation Run

```text
Flutter CI #2776 / run 36222783073 @ 4f0529c72f430084e1f0f9e1ac148366f97e72be
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
- `.ai/tasks/tnyx-201-b4-onboarding-composition.md`
- `apps/app/lib/app/composition/onboarding_providers.dart`
- `apps/app/lib/app/network_providers.dart`

### Actual Behavior

No product/runtime behavior change is intended. Existing consumers continue importing the same Onboarding symbols through `network_providers.dart`; only composition ownership location changed. `network_providers.dart` dropped from 274 to 232 lines.

### Known Limitations

Local Flutter tooling is unavailable in this connector-only session; GitHub CI supplies executable validation. Runtime/source validation is complete. This final handoff commit changes documentation only; once its automatically triggered exact-head CI passes, live PR/Linear state records review readiness without requiring another brief edit.

### Final Status

`REVIEW`
