# TNYX-206 — N3A Base Daily Nutrition Summary (workout OFF)

**Status:** In progress  
**Primary owner:** `apps/features/nutrition`  
**Affected platform:** Flutter phone Meal Diary

## Owner Approval and Scope

**Approval:** Approved. The N3A slice, incomplete-nutrient refinement, and bounded review-repair work were owner-authorized with `go` / `GO`.

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
**R15 metadata HEAD:** `36adcf5196476b18a36f7925ff2c4295fadf6df3`; CI #2579 / run `34949844224` all green.  
**R17/R18 first candidate:** `efbb9b4a6bb10885a91c4e69f94b5f7a042867ed`; CI #2583 / run `34965550401` failed only because the new semantics test leaked its test-owned `SemanticsHandle`.  
**R17/R18 validated source/test HEAD:** `fe73557cade2f97e519a4d15f4ed991e941956ab`; CI #2585 / run `34967042877` all green across Flutter analyze, Dart analyze, Flutter tests, and Dart tests.  
**Branch compare at validated source/test HEAD:** 116 ahead / 0 behind current base; 39 changed files.  
**Merge:** not authorized.

This file is the final handoff reconciliation for R17/R18. The resulting commit is metadata-only and must be validated by CI, but this brief must not be edited again solely to chase the resulting metadata SHA. Pin that final SHA/CI/review evidence in PR #267 instead.

## Governance / Reconstruction Evidence

Fresh-read during this repair sequence:

- root `AGENTS.md`;
- `.ai/workflow.md`;
- `.ai/FEATURE_DEVELOPMENT.md`;
- `.ai/tasks/README.md`;
- `.ai/tasks/design-system-token-consolidation.md`;
- `apps/features/AGENTS.md`;
- `apps/core/lib/src/theme/README.md`;
- `docs/PUSH_TEMPLATE.md` and `.github/PULL_REQUEST_TEMPLATE.md`;
- current PR #267 metadata/review threads and actual Codex reviews;
- Linear TNYX-206 status/relations;
- current Daily Nutrition widget/provider/recovery/summary tests;
- existing Core `TioButton` contract (`ghost` variant).

R17/R18 remain inside the approved TNYX-206 review-repair scope. R17 preserves the existing Retry action intent while using the already-governed shared button surface; no new Core contract is introduced. R18 changes accessibility truth only; visual progress remains clamped.

## Locked Truth Contract

- Exact consumed truth drives exact progress/Remaining only when all contributing facts are known.
- Partial known nutrients may show a confirmed lower bound with `+`, but never exact progress.
- Fully unavailable nutrients show `—`; missing facts never become fake zero.
- A successful known-empty day is exact zero.
- Visual progress bars/rings may clamp at 100%, but accessibility percentages must report the raw exact consumed/target ratio when that ratio is known.
- Production selected-day/calendar truth uses complete paged reads when range capability exists; non-range repositories retain selected-day truth and omit range decorations.
- Workout remains absent from N3A.

## Review Findings

R1–R16 are implemented/reconciled, validated where runtime-affecting, and resolved.

### R17 / P1 — Retry bypasses shared button contract

**Status:** Implemented and validated; thread resolution pending final evidence reply.  
**Thread:** `PRRT_kwDOTOXwB86icgC_` / comment `4013803731`.

`MealDiaryDailyNutritionSummaryStatus.error` keeps the same Retry key/label/invalidation callback but now uses `TioButton.ghost` instead of raw `TextButton`. The focused contract test verifies the rendered Retry is the governed ghost variant and remains tappable. That test passed in both the first candidate run and final source/test CI #2585.

### R18 / P2 — macro semantics announce clamped percentage

**Status:** Implemented and validated; thread resolution pending final evidence reply.  
**Thread:** `PRRT_kwDOTOXwB86icgDI` / comment `4013803742`.

Nutrient-cell spoken percentage derives from raw exact `consumed / target` when both values are known and target is positive; `LinearProgressIndicator.value` continues using the existing clamped visual progress. Focused coverage locks 260 g / 250 g as `104 percent` while the bar remains `1.0`.

## CI #2583 Failure and Correction Evidence

First candidate `efbb9b4a6bb10885a91c4e69f94b5f7a042867ed`:

- Flutter analyze: passed;
- Dart analyze: passed;
- Flutter tests: failed;
- Dart tests: skipped because the prior test step failed.

The only new focused failure was `meal_diary_daily_nutrition_status_test.dart: over-target macro semantics announce the raw exact percentage`. The product assertion was not reported as mismatched. Flutter instead failed test-end verification because a `SemanticsHandle` remained active. The R17 ghost-action test immediately before it passed.

The correction was test-only: the test now disposes its own `SemanticsHandle` inside `try/finally`, before test-end binding verification. Production R17/R18 source was not changed for this harness failure.

Corrected exact source/test HEAD `fe73557cade2f97e519a4d15f4ed991e941956ab` passed CI #2585 / run `34967042877`:

- Flutter analyze: passed;
- Dart analyze: passed;
- Flutter tests: passed;
- Dart tests: passed.

## Validation Evidence

- R15 source/test HEAD `c76d85569c1de26e10f6a677b12065df37236ab8`: CI #2578 all four gates green.
- R15 metadata HEAD `36adcf5196476b18a36f7925ff2c4295fadf6df3`: CI #2579 all four gates green.
- Actual Codex review `PRR_kwDOTOXwB88AAAABNmiG8Q` on `c76d85569c...` produced R16/R17/R18.
- R17/R18 first candidate `efbb9b4a...`: analyzers green; Flutter tests failed only on test-owned semantics lifecycle; Dart tests skipped.
- R17/R18 corrected source/test HEAD `fe73557c...`: CI #2585 all four gates green.
- Exact source/test compare to current base at `fe73557c...`: 116 ahead / 0 behind; 39 changed files.

## Implementation Checklist

- [x] Reconcile root/nested governance, Linear, PR, task brief, exact source/tests.
- [x] R15 fix, regression, exact CI, and thread resolution.
- [x] Resolve R16 as superseded by reconciled handoff/CI evidence.
- [x] R17 replace raw Retry `TextButton` with `TioButton.ghost` without changing callback/key intent.
- [x] R17 focused shared-button coverage.
- [x] R18 derive spoken exact macro percentage from raw consumed/target while visual bar remains clamped.
- [x] R18 over-target semantics regression.
- [x] Correct the R18 test-owned `SemanticsHandle` lifecycle without production mutation.
- [x] Exact corrected source/test CI #2585 green across all four gates.
- [x] Reconcile final task-handoff metadata checkpoint.
- [ ] Validate the resulting metadata-only final SHA with all four CI gates.
- [ ] Reply to/resolve R17/R18 and audit 0 unresolved threads.
- [ ] Fresh exact-head review has no new blocking P1/P2.
- [ ] Reconcile PR body to final exact-head evidence.
- [ ] Owner explicitly authorizes merge.

## Exit Gates

Before merge readiness:

- Retry remains functional and uses the governed shared button contract;
- first-load/loading/error/retry behavior remains correct;
- target changes retain stable resolved geometry while refreshed truth loads;
- calendar and macro accessibility percentages report truthful over-target ratios while visuals remain clamped;
- exact/partial nutrient semantics, range behavior, and keyset pagination remain unchanged;
- exact final-head Flutter/Dart analyze/tests green;
- 0 unresolved review threads;
- fresh exact-head review has no blocking P1/P2;
- PR body matches final HEAD/evidence;
- owner explicitly authorizes merge.

## Next Exact Action

Validate this metadata-only resulting HEAD with the four CI gates. If green, reply to and resolve R17/R18, confirm 0 unresolved threads, request a fresh exact-head actual Codex review (fall back to a Codex-style exact-head review only if the actual bot is usage-limited), then pin the final HEAD/CI/review/thread evidence in PR #267. Keep TNYX-206 In Progress and TNYX-207 blocked until explicit merge + post-merge sync.
