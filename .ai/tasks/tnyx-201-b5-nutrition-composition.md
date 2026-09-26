# TNYX-201 B5 — Nutrition Composition Split

**Status:** In progress
**Primary owner:** apps/app composition root
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped architecture slice under approved #260 sequence
**Approval status:** Approved
**Approval evidence:** Owner requested “Go next” and then “Go” after B4 merge-gate review.
**Approved product/UI/data-shape boundaries:** Internal app composition refactor only.
**Explicit non-changes:** No Nutrition feature-package restructure; no provider rename/type/lifetime/override change; no Supabase/in-memory/null selection change; no Body/Wellness/Profile extraction; no router/UI/schema/backend change.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned
**Implementation ownership state:** Complete
**Repository state last verified:** GitHub `main@eb7b041b5a078d6e0e846792d3587a521de7024d`; B4 merged and archived via PRs #369/#370.
**Branch:** `tnyx/tnyx-201-b5-nutrition-composition`
**HEAD SHA:** validated review checkpoint `796dd778030046a01300e2928f89f8cc984e4a30`; this handoff reconciliation is documentation-only.
**Observed working-tree state:** No local repository worktree is available in this connector session; branch/main refs and GitHub file blobs are used as repository-state evidence.
**Observed uncommitted/dirty files:** Not applicable in API-backed session.
**PR / tracker:** Linear TNYX-201; GitHub #260 parent; GitHub #371 B5 child; TNYX-153 related Nutrition package restructure is separate; #357 router remains planning-only.
**Current implementation state:** Source extraction complete. Six Nutrition composition symbols now live in `app/composition/nutrition_providers.dart`; `network_providers.dart` re-exports them and retains Profile/Wellness/Body composition.
**Relevant execution surface:** `apps/app/lib/app/network_providers.dart`, new `apps/app/lib/app/composition/nutrition_providers.dart`, existing app consumers/tests.
**Validation completed at SHA:** review checkpoint `796dd778030046a01300e2928f89f8cc984e4a30` — Flutter CI #2779 / run `36224251418`: bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests all passed. `git diff --check HEAD` also returned exit 0 in an isolated git repo reconstructed from the exact GitHub PR diff hunks.
**Validation remaining:** exact-head CI for this documentation-only handoff update, then final review-thread/scope audit. If green, live PR/Linear state is authoritative and no further task-brief-only commit is required.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Revalidate the documentation-only final head; if green, mark PR #372 ready for review and reconcile TNYX-201 to In Review.

## Global UI / Design-System Guardrail

No production UI is in scope. Existing rendered behavior must remain unchanged.

## 1. Discovery

### User Outcome

Continue #260 Slice B by removing the next ownership-clear feature group from the catch-all `network_providers.dart`.

### Success Criteria

- all six Nutrition app-composition providers live in `app/composition/nutrition_providers.dart`;
- existing consumers continue importing through `network_providers.dart`;
- Supabase/in-memory/null selection is unchanged;
- no Nutrition feature package source or behavior changes;
- no Body/Wellness/Profile/router work is mixed into B5.

### Scope

Move only:

- `nutritionProfileRepositoryProvider`
- `mealCategoriesRepositoryProvider`
- `nutritionProfileDataProvider`
- `nutritionTargetsDataProvider`
- `nutritionTargetsRepositoryProvider`
- `mealTextParseRepositoryProvider`

to `apps/app/lib/app/composition/nutrition_providers.dart`.

### Non-Goals

- no TNYX-153 implementation
- no Nutrition package file moves/public API changes
- no route/UI change
- no consumer import migration
- no Body/Wellness/Profile composition move
- no Supabase schema/RLS/RPC/Edge Function change

## 2. Codebase Exploration

### Verified Evidence

- Read root `AGENTS.md`, repository architecture/ownership docs, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, push/PR guidance, #260/#357, TNYX-201 and TNYX-153.
- Current base is `main@eb7b041b5a078d6e0e846792d3587a521de7024d`.
- B1–B4 are merged and archived.
- Current `network_providers.dart` retains Profile, Wellness, Body and Nutrition composition.
- Nutrition six-provider group uses the Nutrition public package plus existing `supabaseClientProvider` only.
- Direct consumers include router/settings, Product Onboarding completion, Meal Diary/bootstrap composition and app tests; they use the stable app composition surface.
- TNYX-153 owns internal Nutrition package feature-first organization and remains Backlog; B5 does not touch it.
- Profile is more coupled by canonical/legacy bridge behavior; Body/Wellness contains a cross-owner adapter, so both are deferred.

## 3. Clarification

| Decision | Status | Rationale | Owner |
| --- | --- | --- | --- |
| Move all six Nutrition app-composition symbols together | Made | Same feature boundary and runtime selection dependency | apps/app |
| Keep `network_providers.dart` re-export | Made | Preserves existing consumers and overrides | apps/app |
| Do not activate TNYX-153 | Made | B5 changes app composition only, not Nutrition internals | TNYX-201/TNYX-153 |
| Defer Body/Wellness/Profile | Made | Cross-owner/legacy coupling requires separate audit | #260 |

## 4. Architecture Design

### Chosen Approach

```text
apps/app/lib/app/composition/
├─ runtime_providers.dart
├─ auth_providers.dart
├─ hydration_preferences_providers.dart
├─ workout_providers.dart
├─ onboarding_providers.dart
└─ nutrition_providers.dart
```

`nutrition_providers.dart` owns only app-shell concrete implementation selection/read-provider composition for Nutrition contracts.

## 5. Implementation Plan

- [x] create `composition/nutrition_providers.dart`
- [x] move only the six approved symbols unchanged
- [x] re-export the new module from `network_providers.dart`
- [x] remove now-unused Nutrition import from `network_providers.dart`
- [x] preserve all existing consumer imports
- [x] audit exact branch delta
- [x] obtain exact-head CI
- [x] run/record `git diff --check`
- [ ] reconcile GitHub/Linear/task state for review

## 6. Quality Review

### Validation Run

```text
Flutter CI #2779 / run 36224251418 @ 796dd778030046a01300e2928f89f8cc984e4a30
- Bootstrap workspace: PASS
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS

Isolated exact-PR-hunk git repository
- git diff --check HEAD: PASS (exit 0)
```

The upcoming handoff update is documentation-only and requires one final exact-head CI recheck.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
| --- | --- | --- | --- | --- | --- |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-b5-nutrition-composition.md`
- `apps/app/lib/app/composition/nutrition_providers.dart`
- `apps/app/lib/app/network_providers.dart`

### Source Checkpoint

- base: `main@eb7b041b5a078d6e0e846792d3587a521de7024d`
- source checkpoint: `4a6ad75dcc23997a7048544a83b823e6722a6fc4`
- branch delta: exactly four B5-owned files
- `network_providers.dart`: 232 → 166 lines
- no consumer imports changed
- no feature/router/UI/backend/schema files changed

### Final Status

`REVIEW HANDOFF — FINAL HEAD REVALIDATION PENDING`
