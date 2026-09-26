# TNYX-201 B1 — Runtime/Auth Composition Split

**Status:** In progress
**Primary owner:** apps/app composition root
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Approved
**Approval evidence:** Owner requested on 2026-09-26: “Audit kare 260 ka next slice start kare. Follow agent.md.”
**Approved product/UI/data-shape boundaries:** Internal app composition refactor only.
**Explicit non-changes:** No provider rename/type/lifetime/override change; no Auth/session/runtime fallback change; no Profile/Wellness/Body/Workout/Nutrition/Onboarding extraction; no router work; no UI/UX change; no Supabase schema/RLS/Storage/Edge Function change; no backend/service implementation.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub API compare: branch identical to main at e838083376551c4f27885656aa2d027a4216a4db before this brief
**Branch:** tnyx/tnyx-201-b1-runtime-auth-composition
**HEAD SHA:** e0f1738df286f5ebee71165f8966fc6697030cf2 at validated runtime-code checkpoint; this handoff update is documentation-only
**Observed working-tree state:** No local worktree exists in this API-backed session; remote branch/main ancestry and changed-file delta are used as the equivalent safety evidence.
**Observed uncommitted/dirty files:** Not applicable in API-backed session
**PR / tracker:** Linear TNYX-201; GitHub #260 parent; GitHub #359; Draft PR #360; GitHub #357 remains planning-only Slice C
**Current implementation state:** B1 source extraction complete. Runtime/API and Auth/session composition are split into `app/composition/`; `network_providers.dart` remains the compatibility surface and owns the remaining feature composition.
**Relevant execution surface:** apps/app/lib/app/network_providers.dart; new apps/app/lib/app/composition/*
**Validation completed at SHA:** `e0f1738df286f5ebee71165f8966fc6697030cf2` — Flutter CI #2763 / run 36214859548: bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests all passed.
**Validation remaining:** Exact-head CI rerun after this documentation-only handoff update; final API scope/whitespace audit; review readiness.
**Current blocker:** No code blocker. Dedicated Linear child could not be created because the workspace free issue limit was reached, so TNYX-201 is the live Linear tracker. Local Flutter execution is unavailable in this connector-only session; GitHub CI supplies runtime validation.
**Open review finding IDs:** None
**Next exact action:** Revalidate the documentation-only final head, reconcile PR #360 / TNYX-201 / #359 to In Review, and stop before merge.

## Global UI / Design-System Guardrail

No production UI is in scope. Any unexpected visual/UI requirement is a follow-up and must not be implemented in B1.

## 1. Discovery

### User Outcome

Keep apps/app as a thin, maintainable composition root by beginning the approved Slice B decomposition of the 494-line network_providers.dart without changing runtime behavior.

### Success Criteria

- runtime/API providers live in composition/runtime_providers.dart
- Auth/session providers live in composition/auth_providers.dart
- current network_providers.dart importers remain source-compatible through re-exports
- all moved providers keep identical names, types, lifetimes, fallbacks and dependencies
- no feature provider group or router behavior changes

### Scope

Move only:

runtime_providers.dart:
- supabaseConfigProvider
- supabaseClientProvider
- apiConfigProvider
- publicApiClientProvider

auth_providers.dart:
- authCapabilityProvider
- authSessionRepositoryProvider
- authTokenProvider
- authenticatedApiClientProvider
- deviceIdentityProviderProvider
- backendUserSyncRepositoryProvider
- googleSignInProviderProvider
- backendUserStateProvider
- authSessionStateProvider
- authProductStateProvider
- userDeviceRepositoryProvider
- authSignInRepositoryProvider
- signInWithGoogleUseCaseProvider
- signInWithEmailUseCaseProvider
- signUpWithEmailUseCaseProvider
- sendPasswordResetEmailUseCaseProvider
- googleAuthUseCaseProvider

### Non-Goals

- no direct-consumer import migration
- no remaining Profile/Body/Wellness/Workout/Nutrition/Onboarding split
- no provider redesign
- no router.dart changes
- no UI or persistence changes

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: AGENTS.md, .ai/workflow.md, .ai/FEATURE_DEVELOPMENT.md, .ai/tasks/README.md, docs/ARCHITECTURE.md, docs/MODULE_OWNERSHIP.md, docs/PUSH_TEMPLATE.md, .github/PULL_REQUEST_TEMPLATE.md, docs/POST_MERGE_SYNC.md, network_providers.dart, network_providers_test.dart.
- Current head at audit: main@e838083376551c4f27885656aa2d027a4216a4db.
- network_providers.dart is 494 lines at blob b46ec114b27d565db6e714aabcedbaffa5724733.
- Existing pattern to follow: apps/app owns concrete runtime/provider composition; feature business logic remains in owning feature/domain packages.
- Existing import compatibility surface is package:tio_app/app/network_providers.dart across app source and tests.
- Existing tests already cover unavailable defaults, Firebase fallback, Supabase adapter selection, auth source-of-truth and provider overrides.
- No open TNYX-201 implementation branch/PR existed before B1; TNYX-271/#337 was Done/closed.
- GitHub #357 is Slice C planning-only.
- Dedicated Linear child creation failed at workspace free issue limit; this limitation is recorded in TNYX-201 and #359.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Execute Slice B before router Slice C | Made | TNYX-201/#260 frozen sequence is A → B → C → D | TNYX-201/#260 |
| Use B1 rather than one broad provider rewrite | Made | Keeps one small reviewable active implementation slice | Owner/agent workflow |
| Keep network_providers.dart as compatibility re-export | Made | Preserves current consumer import contract and reduces change surface | apps/app |
| Do not migrate feature provider groups in B1 | Made | Ownership risk is higher and belongs to later bounded B work | apps/app |

## 4. Architecture Design

### Chosen Approach

Create:

```text
apps/app/lib/app/composition/
├─ runtime_providers.dart
└─ auth_providers.dart
```

runtime_providers.dart owns environment/runtime selection and public API client composition.

auth_providers.dart imports runtime_providers.dart and owns Auth/session/token/sign-in/device/backend-user composition plus authenticatedApiClientProvider.

network_providers.dart imports/re-exports both files and continues to own the remaining feature composition until later bounded slices.

### Ownership and Data Flow

```text
runtime config -> Supabase/API runtime providers
                         ↓
                Auth composition providers
                         ↓
      remaining feature composition providers
```

### Alternative Rejected

Splitting the full network_providers.dart into every feature module in one PR was rejected because it increases ownership and regression risk, makes review harder, and conflicts with the repository's bounded-slice rule.

### Failure and Accessibility States

No product-visible failure or accessibility state changes are allowed. Existing null/fallback/fail-closed behavior must remain byte-for-byte equivalent in intent.

## 5. Implementation Plan

- [x] create composition/runtime_providers.dart
- [x] create composition/auth_providers.dart
- [x] remove only the approved moved definitions from network_providers.dart
- [x] import/re-export composition files from network_providers.dart
- [x] keep all current consumers source-compatible
- [x] review exact branch delta for scope
- [x] run/obtain focused + app validation
- [x] open/update PR only after scope audit

## 6. Quality Review

### Validation Run

```text
Flutter CI #2763 / run 36214859548 @ e0f1738df286f5ebee71165f8966fc6697030cf2
- Bootstrap workspace: PASS
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS

Initial CI #2762 failed only on one stale unused import in network_providers.dart; commit e0f1738d removed it and #2763 passed completely.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-b1-runtime-auth-composition.md`
- `apps/app/lib/app/composition/runtime_providers.dart`
- `apps/app/lib/app/composition/auth_providers.dart`
- `apps/app/lib/app/network_providers.dart`

### Actual Behavior

No product/runtime behavior is intentionally changed. Existing `network_providers.dart` consumers keep the same provider symbols via re-exports. `network_providers.dart` dropped from 494 to 314 lines after extracting runtime/API and Auth/session composition.

### Known Limitations

Local Flutter tooling is unavailable in this connector-only session. GitHub Flutter CI #2763 passed the full workspace analyze/test workflow at the validated runtime-code checkpoint. A final exact-head rerun is required after this documentation-only handoff update.

### Final Status

`REVIEW`
