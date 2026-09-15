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
**PR:** #267 — Ready for review, not merge-ready  
**Linear:** TNYX-206 — In Progress; blocks TNYX-207  
**Repository state:** connector/API session; local `git status`/worktree state is unavailable and no local-clean claim is made.  
**Pre-R15 exact HEAD:** `1b518e88dc1736d9684ee09612df1be44200b21d`; CI #2574 / run `34873686621` all green.  
**Fallback review:** `5206810991` on `1b518e88...`; opened R15/P2.  
**Actual Codex:** final rerun requested on `1b518e88...`, but code-review usage limit prevented execution.  
**Merge:** not authorized.

## Governance / Reconstruction Evidence

Fresh-read before R15 source mutation:

- root `AGENTS.md`;
- `.ai/workflow.md`;
- `.ai/FEATURE_DEVELOPMENT.md`;
- `.ai/tasks/README.md`;
- `.ai/tasks/design-system-token-consolidation.md`;
- `apps/features/AGENTS.md`;
- `apps/core/lib/src/theme/README.md`;
- current PR #267 metadata/review threads;
- Linear TNYX-206 status/relations;
- current Meal Diary source and focused recovery/integration tests.

This is the same approved TNYX-206 slice. R15 is a review correctness fix, not a new product slice, visible redesign, or data-shape change. The repair must preserve current rendered resolved/error geometry and only remove the target-change reload mismatch.

## Locked Truth Contract

For each supported nutrient:

1. **Exact known** — every contributing entry has the nutrient; exact total may drive progress.
2. **Partial known / incomplete** — exact total unavailable; a confirmed minimum may display with `+`; exact progress stays unavailable.
3. **Fully unavailable** — display `—`; never fabricate `0g+`.
4. **Known empty day** — successful empty MealLog read is exact known zero.

`+` means “at least this much is confirmed”; it is presentation-only and never drives exact Remaining/progress.

Production selected-day and calendar truth use complete paged range reads when range capability exists. Repositories without `MealLogRangeReadRepository` retain selected-day truth and omit range decorations.

## Review Findings

R1–R14 are implemented, CI-validated, and their GitHub threads are resolved. Durable behavior includes:

- target-save cache coherence and retry paths;
- complete paged reads with immutable-id keyset pagination;
- stale range decorations suppressed on range error;
- optional range capability does not mask selected-day truth;
- incomplete nutrient lower-bound/unknown semantics remain exact-safe;
- over-target accessibility announces raw percentage while the visual ring clamps;
- explicit refresh with retained data keeps compact summary/calendar geometry;
- error surfaces remain outside the calendar handle overlap band.

### R15 / P2 — target-change dependency reload can overlap loading surface

**Status:** Open; approved bounded repair in progress.  
**Observed HEAD:** `1b518e88dc1736d9684ee09612df1be44200b21d`  
**GitHub thread:** `PRRT_kwDOTOXwB86iaiJi` / comment `4013030118`.

`canOverlapDailySummary` currently enables overlap when the selected summary has preserved value and no error. `_dailySummarySurface` uses default `AsyncValue.when`, which may render the loading branch on a dependency-driven reload. Nutrition Targets changes are watched through `NutritionTargetsChangeSource`, so target save/change can produce a loading `TioCard` while overlap is still enabled. Only the resolved data card is pointer-ignored.

Chosen repair direction: keep rendered branch and overlap predicate aligned by retaining previous data during dependency reload (`skipLoadingOnReload: true`) and add a focused target-change + blocked-read regression proving the resolved card/geometry remain stable until new target truth arrives. Do not change normal first-load loading, error behavior, calendar geometry, or Core contracts.

## Validation Evidence

Historical source/test repair HEAD `7e55df9c9275c97eff37e2b803387b14f5009c1c` passed CI #2573 / run `34872675496`.

Pre-R15 exact HEAD `1b518e88dc1736d9684ee09612df1be44200b21d` passed CI #2574 / run `34873686621`:

- Flutter analyze ✅
- Dart analyze ✅
- Flutter tests ✅
- Dart tests ✅

That validation predates R15 and cannot validate the upcoming source change.

## R15 Implementation Checklist

- [x] Reconcile root/nested governance, Linear, PR, task brief, exact source/tests.
- [x] Record R15 before source mutation and retain ChatGPT as the single Implementation owner.
- [ ] Align dependency-reload rendering with overlap predicate without changing first-load/error UX.
- [ ] Add focused target-change + blocked-read regression.
- [ ] Inspect incremental diff for visual/scope regressions.
- [ ] Run exact-head Flutter CI; require Flutter/Dart analyze + tests green.
- [ ] Reply to and resolve R15 only after validated fix evidence.
- [ ] Fresh unresolved-thread audit = 0.
- [ ] Run fresh exact-head fallback Codex-style review; actual Codex may be retried only if usage allows.
- [ ] Reconcile PR body to final exact-head evidence.
- [ ] Keep owner merge authorization as a separate explicit gate.

## Exit Gates

Before merge readiness:

- first-load loading and error/retry behavior remain correct;
- target-change dependency reload cannot put an interactive/loading card into the handle overlap band;
- retained resolved summary geometry stays stable while the target read reloads;
- new target truth replaces retained data after reload completes;
- exact/partial nutrient semantics, range behavior, keyset pagination, and accessibility truth remain unchanged;
- exact-head CI green;
- 0 unresolved review threads;
- fresh exact-head review has no new blocking P1/P2;
- PR body matches final HEAD/evidence;
- owner explicitly authorizes merge.

## Next Exact Action

Implement the minimal R15 presentation-state fix and focused dependency-reload regression, validate the exact resulting HEAD, resolve R15 with evidence, then run a fresh exact-head review. Keep TNYX-206 In Progress and TNYX-207 blocked until explicit merge + post-merge sync.