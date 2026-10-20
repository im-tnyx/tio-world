# Testing Guide

Document Status: Canonical Live Doc
Last Verified: 2026-10-20
Owner: repository developer experience
Truth Boundary: Authoritative for repository testing expectations and validation coverage; not evidence that tests or CI currently pass.

Testing depth should match product risk.

## Test Pyramid

Prefer:

1. Pure unit tests for domain and calculation logic.
2. Controller/notifier tests for state transitions.
3. Widget tests for important UI behavior.
4. Integration tests for critical flows.
5. Manual device checks for Flutter Wear OS and native watchOS flows.

## Flutter Mobile

For mobile changes:

```bash
cd apps/app
flutter analyze
flutter test
```

When integration tests exist:

```bash
flutter test integration_test
```

## Dart Packages

For package changes:

```bash
cd apps/shared
dart analyze
dart test
```

When Melos is configured:

```bash
melos analyze
melos test
```

## Wear OS

For the Flutter `apps/wear` package, validate with Flutter and Android Studio.

Expected checks:

```bash
cd apps/wear
flutter pub get
flutter analyze
flutter test
```

Manual checks should include:

- real watch or emulator launch
- startup time sanity check
- workout start/pause/resume
- rest timer behavior
- sync state behavior
- screen readability on round display
- battery/background behavior where relevant

## Supabase And Protected Backend

For Supabase changes, run the approved feature's migration/RLS/security checks. For the future protected backend, run the selected runtime's lint and unit/integration checks once that workspace exists.

## Docs Only

Docs-only changes do not require app builds, but should run:

```bash
git diff --check
```

## What To Test By Area

| Area | Minimum validation |
| :--- | :--- |
| README/docs | `git diff --check` |
| Flutter UI | `flutter analyze`, widget/manual check |
| Flutter state | controller/notifier unit tests |
| Onboarding flow | mode-plan unit tests, controller transitions, fixed-shell widget tests, router completion gate, restart/resume integration, and accessibility traversal |
| Workout engine | calculation unit tests |
| Nutrition engine | calculation unit tests |
| API client | mapping and error handling tests |
| Sync | queue and retry behavior tests |
| Wear OS | `flutter analyze`, `flutter test`, and manual watch/emulator check |
| Supabase | migration/RLS/security checks defined by the approved feature task |
| Protected backend | selected runtime lint + unit/integration tests |

## Risk-Based Regression Selection

Choose the **smallest meaningful verification that can detect a regression in the changed behavior**, not a fixed test suite for every PR. First identify the approved outcome, affected owner/package, data/security boundary, failure states and tests already present. The table below is **review/validation selection guidance**, not a statement that every test exists or an addition to CI/branch-protection requirements. A docs-only change does not trigger unrelated Flutter or Supabase tests; a sensitive change cannot skip applicable security evidence because a general CI job is green.

| Change class | Minimum meaningful verification (where applicable) | Regression, negative-path and review focus |
| :--- | :--- | :--- |
| Documentation / mechanical refactor | `git diff --check`; verify touched references, scope and stated behavior against source | No unintended files, broken critical references or invented completed work; no blanket app builds for docs-only edits |
| Shared Dart / pure domain calculations | Targeted unit tests plus applicable Dart/Flutter analysis for changed package | Invalid or boundary inputs, rounding/units, null/error behavior and unchanged contracts for other callers |
| Flutter controller, repository or API-client behavior | Focused state/contract tests; package/app analysis and relevant integration checks if available | Loading/success/empty/error transitions, retries/cancellation, malformed responses, offline/no-network behavior, restored state and ownership boundaries |
| Flutter UI, design system, navigation / routing | Targeted widget/route tests and applicable analysis; inspect manual visual outcome on affected states. Use an existing golden/screenshot baseline where practical and stable, **not** blanket snapshot regeneration | Approved visual scope vs actual rendering; loading/empty/error, theme, compact viewport, focus/semantics/accessibility, deep-link and auth-gated navigation; do not change unapproved visuals under a test-fix pretext |
| Wear OS and phone↔watch sync; native watchOS **only when implemented and affected** | Focused Flutter tests/analysis for `apps/wear` when touched; manual supported watch/emulator/phone checks for changed device interactions; platform-specific checks for actual native watch changes | Duplicate/out-of-order/failed sync, offline queue/retry, background/lifecycle/reconnect, stale state and user-visible timer/workout continuity, plus round-screen readability where relevant |
| Auth, sessions, health / biometric / personal-data access | Targeted session/access tests and applicable security-sensitive validation per `AGENTS.md`; exercise both allowed and denied access with synthetic data | Signed-out/expired/revoked sessions, cross-user/tenant isolation, privilege/role boundaries, safe logging/redaction and fail-closed denial, including offline/stale cache where the changed behavior uses it |
| Supabase migrations, RLS, grants, RPCs, functions / Storage policies | Task-specific migration compatibility and authorization/RLS/security tests against the **actual changed objects**; relevant Security Advisor/code-scanning inspection when available | Allow intended owner and deny `anon`/wrong user/tenant; check privileged grants, `SECURITY DEFINER`/search-path boundary where touched, migration rollback/compatibility risks, and deny-on-error paths. Do not infer deployed/live schema from repository SQL |
| Future approved protected API, AI providers or connectors | Only after a real approved service/integration exists: focused contract/unit/integration and auth/security checks for changed boundary | Server-side credentials, least-privilege scopes, unauthorized requests, malformed/upstream failures, timeouts/retries, private-data minimization and safe write/idempotency behavior where applicable; no speculative service scaffolding |

### Evidence, Unavailable Checks And Merge Gates

1. In the task/PR map each **applicable acceptance criterion → changed behavior/file → test or manual proof + actual result → reviewed HEAD SHA/environment → residual risk**. An analysis pass by itself is not proof of an untested user outcome; a previous SHA's result is historical after new commits.
2. Run relevant existing tests where feasible. If a **non-required/optional** test is unavailable or not applicable, record the reason, alternative manual/contract evidence and remaining risk; create a separately scoped follow-up if meaningful coverage is missing. Do **not** relabel a failed or impossible **required** check as optional, `PASS`, or "waived". Apply the [Final Status Decision Rule](../../.ai/FEATURE_DEVELOPMENT.md#final-status-decision-rule) at completion.
3. Verify what is **actually required** from the current branch/ruleset/PR gates, not the check name. Separately report security check **required vs supplemental** and **concrete code finding vs scanner/infrastructure failure** using [the existing security validation rules](../../AGENTS.md#security-sensitive-change-validation) and [push guidance](../../.github/PUSH_TEMPLATE.md#security-sensitive-validation-gate). A failed/incomplete required check blocks merge even if the failure is infrastructure; a concrete security finding requires triage even from a supplemental check. An unavailable supplemental scanner is not proof of security approval or of a vulnerability.
4. If appropriate validation cannot run, state **what did not run, why, what was verified instead and what must happen next**. Never present an unexecuted device check, RLS test, migration, deployment or independent review as completed. Split newly needed test automation, CI/ruleset enforcement or product behavior changes into independently approved work rather than silently expanding a documentation slice.

## Definition Of Done

A change is ready when:

- it solves the stated problem
- ownership boundaries are respected
- all applicable required validation actually passed at the stated SHA; any non-applicable or intentionally omitted optional check has a reason, fallback evidence and residual risk
- docs are updated if behavior or architecture changed
- no unrelated files are included
- no generated artifacts are committed

Record the exact result and applicable review/approval gate. For completion, apply the [Final Status Decision Rule](../../.ai/FEATURE_DEVELOPMENT.md#final-status-decision-rule); `REVIEW`, `PARTIAL` and `BLOCKED` are not interchangeable with `PASS`.
