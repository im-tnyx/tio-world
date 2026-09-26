# TNYX-201 B6 — Body + Wellness Composition Split

**Status:** Validated
**Completion date:** 2026-09-26
**Primary owner:** apps/app composition root
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Approval status:** Approved
**Approval evidence:** Owner said “Go” after B5 post-merge audit identified Body + Wellness as the next bounded Slice B.
**Approved boundary:** Internal app-composition refactor only.
**Explicit non-changes:** No TNYX-154 package-boundary cleanup; no Body Goal behavior; no Settings UI/routes; no Progress feature source; no Profile extraction; no router #357; no Supabase schema/backend changes.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned
**Implementation ownership state:** Complete
**Repository state last verified:** 2026-09-26 after PR #375 squash merge; GitHub `main` is `91e6758bd5ba72617a1e5cf84d39c89ec8c1be58`.
**Branch:** `tnyx/tnyx-201-b6-body-wellness-composition` (merged via PR #375; branch cleanup remains optional and was not performed without a separate request).
**HEAD SHA:** final reviewed PR head `2fc15ef06c69028f5a8eeaf8c47697d63511a339`; squash-merged to `main` as `91e6758bd5ba72617a1e5cf84d39c89ec8c1be58`.
**PR / tracker:** PR #375 merged; GitHub #374 closed by merge; Linear TNYX-201 / GitHub #260 remain the umbrella for later separately authorized work; TNYX-154 remains separate; #357 remains planning-only pending fresh next-slice audit.
**Current blocker:** None.
**Next exact action:** None for B6. Fresh post-merge audit decides whether Slice B is complete or whether a separately authorized Profile composition slice is still warranted before router #357.

## 1. Discovery

### User outcome

Continue decomposing the catch-all `network_providers.dart` without changing Body/Wellness behavior or ownership.

### Scope

Move exactly:

- `wellnessTargetsRepositoryProvider`
- `wellnessTargetsDataProvider`
- `bodySetupRepositoryProvider`
- `bodyRepositoryProvider`
- `bodyStateDataProvider`
- private `_BodyAndWellnessSetupRepository`

to `apps/app/lib/app/composition/body_wellness_providers.dart`.

### Non-goals

- no TNYX-154 implementation
- no Settings ↔ Progress dependency redesign
- no Body/Wellness domain or persistence change
- no Profile composition move
- no route/UI changes
- no consumer import migration

## 2. Codebase Exploration

### Verified evidence

- Root `AGENTS.md`, canonical architecture/ownership docs, workflow, feature-development, push and PR guidance read.
- Current `network_providers.dart` contains Profile plus Body/Wellness composition after B1–B5.
- Body/Wellness contracts and repositories are canonically Progress-owned; `apps/app` owns concrete provider wiring.
- `_BodyAndWellnessSetupRepository` only delegates `saveBodySetup`, Wellness `read`, and Wellness `upsert`; it adds no product rule.
- TNYX-154 separately audits Settings ↔ Progress package dependency and must not be mixed into B6.
- Existing consumers/tests use the stable `network_providers.dart` composition surface.

## 3. Clarification

| Decision | Status | Rationale |
| --- | --- | --- |
| Move Body + Wellness together | Made | `bodySetupRepositoryProvider` composes both canonical owners through the existing adapter |
| Keep adapter app-owned | Made | It is composition glue, not domain logic |
| Preserve compatibility re-export | Made | Avoid consumer/override migration |
| Defer TNYX-154 and Profile | Made | Separate ownership/package concerns |

## 4. Architecture Design

```text
apps/app/lib/app/composition/
├─ runtime_providers.dart
├─ auth_providers.dart
├─ hydration_preferences_providers.dart
├─ workout_providers.dart
├─ onboarding_providers.dart
├─ nutrition_providers.dart
└─ body_wellness_providers.dart
```

## 5. Implementation Plan

- [x] create `composition/body_wellness_providers.dart`
- [x] move exactly five public providers unchanged
- [x] move private adapter unchanged
- [x] re-export module from `network_providers.dart`
- [x] preserve all existing consumer imports/overrides
- [x] audit parent-to-head scope
- [x] obtain exact-head CI
- [x] record API-mode equivalent parent/head whitespace/conflict audit
- [x] reconcile GitHub/Linear/task state for review

## 6. Quality Review

```text
Flutter CI #2782 / run 36227047861 @ e7ad38bda7ba297217ae618637c7b37c1e56e90d
- Bootstrap workspace: PASS
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS

API-mode equivalent scope/whitespace validation
- base ancestor: PASS
- ahead / behind: 5 / 0
- changed files: exactly 4 B6-owned paths
- added-line trailing whitespace/conflict markers: 0 findings
- moved Body/Wellness block: byte-for-byte identical to base
- review threads: 0 at validated checkpoint

Non-required GHAS failed before code analysis because the configured model returned `400 The requested model is not supported`; no code-scanning finding was produced.
```

Final reviewed head `2fc15ef06c69028f5a8eeaf8c47697d63511a339` was revalidated by Flutter CI #2783 / run `36227524389`: bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests all passed. Commit attribution guard and Attribution guard runner passed. Non-required GHAS failed before code analysis because the configured model was unsupported; no code-scanning finding was produced.

## 7. Final Handoff

### Changed files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-b6-body-wellness-composition.md`
- `apps/app/lib/app/composition/body_wellness_providers.dart`
- `apps/app/lib/app/network_providers.dart`

### Source checkpoint

- base: `main@804b1087ff57c70ee3b87ea157b9b37ae0f6d4b9`
- source checkpoint: `a0fa67d1f59504d4291ba15e5b5ba4c5ab4e731b`
- exact branch scope: four B6-owned files
- `network_providers.dart`: 166 → 88 lines
- new Body/Wellness module: 83 source lines
- no consumer, feature-package, router, UI, backend or schema paths changed

### Final status

`PASS`: merged via PR #375 as `91e6758bd5ba72617a1e5cf84d39c89ec8c1be58` on 2026-09-26T07:53:14Z (UTC). Exact final head `2fc15ef06c69028f5a8eeaf8c47697d63511a339` passed Flutter CI #2783 and attribution guards; API-mode whitespace/conflict audit was clean; 0 unresolved review threads remained.
