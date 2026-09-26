# TNYX-201 B6 — Body + Wellness Composition Split

**Status:** In progress
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
**Implementation ownership state:** Active
**Repository state last verified:** `main@804b1087ff57c70ee3b87ea157b9b37ae0f6d4b9` after B5 archive PR #373.
**Branch:** `tnyx/tnyx-201-b6-body-wellness-composition`
**HEAD SHA:** source checkpoint `a0fa67d1f59504d4291ba15e5b5ba4c5ab4e731b`; subsequent handoff update is documentation-only.
**PR / tracker:** Linear TNYX-201; GitHub #260 parent; GitHub #374 B6 child; TNYX-154 separate; #357 planning-only.
**Current blocker:** None.
**Next exact action:** Open Draft PR, run exact-head CI, then complete scope/whitespace/review audit.

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
- [ ] obtain exact-head CI
- [ ] run/record `git diff --check`
- [ ] reconcile GitHub/Linear/task state for review

## 6. Quality Review

Source checkpoint `a0fa67d1`; exact-head GitHub CI pending.

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

`IMPLEMENTED — VALIDATION PENDING`
