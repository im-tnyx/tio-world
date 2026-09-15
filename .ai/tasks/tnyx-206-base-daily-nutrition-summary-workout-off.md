# TNYX-206 — N3A Base Daily Nutrition Summary (workout OFF)

**Status:** In progress  
**Primary owner:** `apps/features/nutrition`  
**Affected platform:** Flutter phone Meal Diary

## Owner Approval and Scope

**Approval:** Approved. The original N3A slice, incomplete-nutrient UX refinement, and bounded review-repair work were owner-authorized with `go` / `GO`.

N3A remains workout-OFF:

```text
Target - Eaten = Remaining
```

In scope: selected-day Daily Nutrition truth, Carbs/Protein/Fat/Fiber exact/partial/unknown presentation, calendar calorie progress from the same budget truth, recovery/accessibility correctness, and review fixes needed to complete this approved slice.

Out of scope: Workout/N10 behavior, schema/RLS changes, persisted daily aggregates, unrelated Diary redesign, N5D/TNYX-207 implementation, or new Core visual contracts.

## Active Handoff

**Planning owner:** ChatGPT  
**Implementation owner:** ChatGPT  
**Review owner:** ChatGPT after implementation  
**Branch:** `tnyx/tnyx-206-n3a-base-daily-nutrition-summary-workout-off`  
**Base:** `main@2866ded8a963b64a99e41b5007da4753a922c7cc`  
**PR:** #267 — Ready for review; merge not authorized  
**Linear:** TNYX-206 — In Progress; blocks TNYX-207  
**Repository state:** connector/API session; local `git status`/worktree state is unavailable and no local-clean claim is made.  
**R15 source/test HEAD:** `c76d85569c1de26e10f6a677b12065df37236ab8`; CI #2578 / run `34948866735` all green.  
**R15 review thread:** `PRRT_kwDOTOXwB86iaiJi`; resolution pending the exact metadata-head validation described below.  
**Actual Codex:** most recent final rerun attempt was blocked by the code-review usage limit; fallback exact-head review remains required if the limit persists.  
**Final metadata policy:** this handoff reconciliation is metadata-only. Validate the resulting exact SHA externally and pin final CI/review/thread evidence in the PR body; do not edit this brief again solely to chase its own resulting SHA.  
**Merge:** not authorized.

## Governance / Reconstruction Evidence

Fresh-read before R15 implementation:

- root `AGENTS.md`;
- `.ai/workflow.md`;
- `.ai/FEATURE_DEVELOPMENT.md`;
- `.ai/tasks/README.md`;
- `.ai/tasks/design-system-token-consolidation.md`;
- `apps/features/AGENTS.md`;
- `apps/core/lib/src/theme/README.md`;
- `docs/PUSH_TEMPLATE.md` and `.github/PULL_REQUEST_TEMPLATE.md`;
- current PR #267 metadata/review threads;
- Linear TNYX-206 status/relations;
- current Meal Diary provider/page source and focused recovery/integration tests.

This remains the same approved TNYX-206 slice. R15 is a correctness/review fix, not a new product slice, visible redesign, or data-shape change. No Core/theme public contract changed.

## Locked Truth Contract

- Exact consumed truth drives exact progress/Remaining only when all contributing facts are known.
- Partial known nutrients may show a confirmed lower bound with `+`, but never exact progress.
- Fully unavailable nutrients show `—`; missing facts never become fake zero.
- A successful known-empty day is exact zero.
- Production selected-day/calendar truth uses complete paged reads when range capability exists; non-range repositories retain selected-day truth and omit range decorations.
- Workout remains absent from this N3A slice.

## Review Findings

R1–R14 are implemented, CI-validated, and their GitHub threads are resolved. Durable behavior includes target-save coherence/retry, complete immutable-id keyset pagination, optional range capability, exact-safe incomplete nutrient truth, truthful over-target accessibility, stable retained-data explicit-refresh geometry, and error surfaces outside the calendar handle overlap band.

### R15 / P2 — target-change dependency reload can overlap loading surface

**Status:** Implemented and source/test validated; external thread resolution pending final metadata-head validation.  
**Observed bad HEAD:** `1b518e88dc1736d9684ee09612df1be44200b21d`  
**Fix HEAD:** `c76d85569c1de26e10f6a677b12065df37236ab8`  
**GitHub thread:** `PRRT_kwDOTOXwB86iaiJi` / comment `4013030118`.

Root cause: summary providers used `ref.watch(_nutritionTargetsChangesProvider(source))`, making a target-change stream event a dependency reload. Meal Diary overlap eligibility could retain `hasValue`, while default `AsyncValue.when` could render loading on that reload.

Fix: target changes are now an explicit refresh signal. Both summary providers `ref.listen` to the existing target-change stream provider and call `ref.invalidateSelf()` only when a real change value arrives. This reuses Riverpod's retained-value refresh path already exercised by R14, keeps first-load loading/error behavior unchanged, and requires no page/Core geometry change.

Focused regression: `_BlockingTargetsRepository` now exposes `NutritionTargetsChangeSource`; the recovery test blocks the target read, emits a target change, verifies the resolved summary remains rendered at the same top position with no loading card, then releases the read and verifies the new target value appears.

Rejected alternatives: changing calendar overlap geometry, making loading cards pointer-transparent, or adding a page-specific reload override would treat presentation symptoms instead of the target-change state transition.

## Validation Evidence

Pre-R15 runtime HEAD `1b518e88dc1736d9684ee09612df1be44200b21d` passed CI #2574 / run `34873686621`.

R15 source/test HEAD `c76d85569c1de26e10f6a677b12065df37236ab8` passed CI #2578 / run `34948866735`:

- Flutter analyze ✅
- Dart analyze ✅
- Flutter tests ✅
- Dart tests ✅

Incremental R15 delta from `1b518e88...` is bounded to this task brief, `meal_diary_nutrition_summary_providers.dart`, and `meal_diary_daily_nutrition_recovery_test.dart`; no schema, Core, route, or unrelated feature file changed.

## Completion Checklist

- [x] Reconcile root/nested governance, Linear, PR, task brief, exact source/tests.
- [x] Convert target-change dependency reload into explicit self-refresh.
- [x] Add target-change + blocked-read retained-geometry regression.
- [x] Inspect incremental delta for scope/visual boundary drift.
- [x] R15 source/test exact-head CI green (#2578).
- [ ] Validate this metadata-only resulting HEAD with exact-head CI.
- [ ] Reply to and resolve R15 with validated evidence.
- [ ] Fresh unresolved-thread audit = 0.
- [ ] Fresh exact-head final review has no new blocking P1/P2; use fallback Codex-style review if actual Codex remains usage-limited.
- [ ] Reconcile PR body to final exact-head evidence.
- [ ] Owner explicitly authorizes merge.

## Exit Gates

Before merge readiness:

- first-load loading and error/retry behavior remain correct;
- target changes refresh both selected/range summaries without putting a loading/error surface into the calendar handle overlap band;
- retained resolved summary geometry stays stable while refreshed target truth loads;
- new target truth replaces retained data after refresh completes;
- exact/partial nutrient semantics, range behavior, keyset pagination, and accessibility truth remain unchanged;
- exact final-head CI green;
- 0 unresolved review threads;
- fresh exact-head review has no new blocking P1/P2;
- PR body matches final HEAD/evidence;
- owner explicitly authorizes merge.

## Next Exact Action

Validate this metadata-only final handoff SHA, resolve R15 with evidence, audit threads, run fresh exact-head review, and reconcile PR body. Keep TNYX-206 In Progress and TNYX-207 blocked until explicit merge + post-merge sync.