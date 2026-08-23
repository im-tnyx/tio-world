# Product Onboarding O9B — Owner Write Failure + Retry Convergence

**Status:** Active  
**Tracker:** GitHub Issue #90  
**Parent O9:** #88  
**O9A:** #89 ✅ / CI #1627  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged

## Starting exact validated checkpoint

```text
d2898b56784fc815a6df893b504673641d20050e
Flutter CI #1627 / run 32636013590 / job 97185796250 ✅
Android Native CI #39 / run 32636013591 / job 97185787171 ✅
```

## Audit result

Canonical owner writes are ordered and per-owner downstream failure coverage already exists. Independent owner tables are not one transaction, so O9B must lock **completion atomicity + retry convergence**, not pretend successful upstream upserts can be rolled back.

## Scope

Integrated Hybrid `setupNow` acceptance with a fail-once late Nutrition Targets owner:

1. Profile, Body, Wellness, Nutrition Profile, Workout Profile and Workout Targets succeed;
2. Nutrition Targets fails;
3. no remote/local onboarding completion is published;
4. draft remains recoverable;
5. retry after repository recovery repeats safe upserts and succeeds;
6. final owner values match the draft and completion publishes only after all owners succeed;
7. successful retry clears the obsolete draft.

## Acceptance

- [ ] late owner failure leaves already-successful upstream canonical values present;
- [ ] failed attempt does not publish remote/local completion;
- [ ] failed attempt does not clear draft;
- [ ] retry safely repeats owner upserts and converges;
- [ ] successful retry publishes completion only after owner success;
- [ ] successful retry clears draft;
- [ ] existing mode-specific/per-owner failure tests remain green;
- [ ] no production source change unless acceptance exposes a real mismatch;
- [ ] all Flutter/Dart gates + Android native build green on exact SHA.

## Guardrails

- no fake cross-table rollback claim;
- no new transaction/schema/migration architecture;
- no O9C scope;
- no O11 cleanup;
- PR #50 remains Draft/open/unmerged.

## Exit

Freeze O9B exact CI, close #90, then activate O9C plan/recommendation publication semantics.
