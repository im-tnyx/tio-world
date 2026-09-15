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
**Actual Codex review:** `PRR_kwDOTOXwB88AAAABNmiG8Q`, reviewed `c76d85569c...`; it opened R16/R17/R18.  
**Merge:** not authorized.

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

This remains the same approved TNYX-206 slice. R17/R18 are review/correctness fixes inside that scope. R17 preserves the existing Retry action intent while moving it to the already-governed shared button surface; no new Core contract is introduced. R18 changes accessibility truth only; visual progress remains clamped.

## Locked Truth Contract

- Exact consumed truth drives exact progress/Remaining only when all contributing facts are known.
- Partial known nutrients may show a confirmed lower bound with `+`, but never exact progress.
- Fully unavailable nutrients show `—`; missing facts never become fake zero.
- A successful known-empty day is exact zero.
- Visual progress bars/rings may clamp at 100%, but accessibility percentages must report the raw exact consumed/target ratio when that ratio is known.
- Production selected-day/calendar truth uses complete paged reads when range capability exists; non-range repositories retain selected-day truth and omit range decorations.
- Workout remains absent from N3A.

## Review Findings

R1–R14 are implemented, CI-validated, and resolved.

### R15 / P2 — target-change dependency reload overlap

**Status:** Resolved and validated.  
**Fix HEAD:** `c76d85569c1de26e10f6a677b12065df37236ab8`.  
**Thread:** `PRRT_kwDOTOXwB86iaiJi` / comment `4013030118`.

Target changes are now explicit self-refresh signals (`ref.listen` + `ref.invalidateSelf()`), so retained data uses the refresh path instead of a dependency reload. The blocked-read target-change regression keeps resolved geometry stable and confirms the new target appears after release. CI #2578 and final metadata CI #2579 are all green; thread resolved with that evidence.

### R16 / P1 — R15 task brief stale on source checkpoint

**Status:** Superseded by `36adcf5196476b18a36f7925ff2c4295fadf6df3`; thread resolution pending.  
**Thread:** `PRRT_kwDOTOXwB86icgCz` / comment `4013803718`.

The current handoff records R15 implemented/validated and exact CI #2579. This finding was anchored to pre-reconciliation `c76d85569c...` and requires no source change.

### R17 / P1 — Retry bypasses shared button contract

**Status:** Open; accepted for bounded repair.  
**Thread:** `PRRT_kwDOTOXwB86icgC_` / comment `4013803731`.

Current error status uses a raw `TextButton` despite the feature-package reusable-first rule and existing `TioButton.ghost`. Repair: keep the same Retry label, key, invalidation callback, and error-card composition; replace only the local raw action with `TioButton.ghost`. Add focused coverage that the Retry action uses the ghost shared contract and still recovers the page.

### R18 / P2 — macro semantics announce clamped percentage

**Status:** Open; accepted for bounded repair.  
**Thread:** `PRRT_kwDOTOXwB86icgDI` / comment `4013803742`.

Current nutrient-cell semantics derive percentage from `summary.progressFor`, which is intentionally visual/clamped. Repair: when exact consumed and target are known and target is positive, derive the spoken percentage from raw `consumed / target`; keep `LinearProgressIndicator.value` on the existing clamped `progress`. Add an over-target macro semantics regression (260 g / 250 g → 104 percent).

## Validation Evidence

- Pre-R15 exact HEAD `1b518e88dc1736d9684ee09612df1be44200b21d`: CI #2574 / run `34873686621` green.
- R15 source/test HEAD `c76d85569c1de26e10f6a677b12065df37236ab8`: CI #2578 / run `34948866735` green across Flutter analyze, Dart analyze, Flutter tests, Dart tests.
- R15 metadata HEAD `36adcf5196476b18a36f7925ff2c4295fadf6df3`: CI #2579 / run `34949844224` green across the same four gates.
- Actual Codex subsequently reviewed `c76d85569c...` and produced R16/R17/R18; therefore #2579 is historical validation, not validation of the forthcoming R17/R18 repair.

## Implementation Checklist

- [x] Reconcile root/nested governance, Linear, PR, task brief, exact source/tests.
- [x] R15 self-refresh fix + blocked-read target-change regression.
- [x] R15 source/test CI #2578 green.
- [x] R15 metadata CI #2579 green.
- [x] Reply to and resolve R15.
- [ ] Resolve R16 as superseded by current handoff/CI evidence.
- [ ] R17 replace raw Retry `TextButton` with `TioButton.ghost` without changing callback/key intent.
- [ ] R17 focused shared-button/recovery coverage.
- [ ] R18 derive spoken exact macro percentage from raw consumed/target while visual bar remains clamped.
- [ ] R18 over-target semantics regression.
- [ ] Run exact source/test CI for R17/R18.
- [ ] Reconcile one final metadata checkpoint, validate exact final SHA, resolve findings, and audit 0 unresolved threads.
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

Resolve R16 with current evidence, implement R17/R18 in the Daily Nutrition widget plus focused tests, validate exact source/test HEAD, then complete final handoff/review gates. Keep TNYX-206 In Progress and TNYX-207 blocked until explicit merge + post-merge sync.
