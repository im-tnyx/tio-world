# Product Onboarding O10 — Integrated Final Acceptance

**Status:** Active  
**Tracker:** GitHub Issue #95  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O9:** #88 ✅ / final CI #1641  
**Implementation PR:** #50 Draft/open/unmerged  
**O11 cleanup:** #54 blocked until O10 exact acceptance

## Starting exact validated runtime checkpoint

```text
86870c0a4164500455877af05f67ba5f2a197e2d
Flutter CI #1641 / run 32638397470 / job 97191529443 ✅
Android Native CI #53 / run 32638397482 / job 97191531402 ✅
```

Later O9 bookkeeping commits are docs-only and do not replace this runtime baseline.

## Goal

Prove O1–O9 together as one Product Onboarding system boundary before any destructive canonical schema cleanup or PR readiness decision.

## Execution

```text
O10A all-mode first-run completion matrix
O10B completed-session rebootstrap + canonical readback
O10C interruption/retry/resume + no duplicate completion publication
O10D final canonical/legacy dependency + guardrail audit
O10E exact O1–O10 integrated freeze
```

## O10A

Run complete finalization for Workout, Nutrition, Hybrid setupNow and Hybrid later. Validate active/inactive owner publication, App Mode destinations, remote/local completion and successful draft cleanup together.

## O10B

Prove a fresh completed session boots from canonical completion/mode/owner truth and does not depend on `onboarding_drafts` or resurrect inactive branches.

## O10C

Prove interrupted/resumed and failed/retried flows remain recoverable, do not publish false completion and do not duplicate semantic owner/completion state.

## O10D

Inventory remaining legacy dependencies for O11. Do not remove columns or edit applied migrations. Reconfirm no fabricated Health state, generated plan owner, permanent dual write or sensitive-data logging expansion.

## O10E

Freeze one exact source checkpoint with all O10 evidence plus:

```text
Flutter analyze ✅
Dart analyze ✅
Flutter tests ✅
Dart tests ✅
Android debug APK/native compile ✅
```

## Guardrails

- one durable owner per concept;
- no schema drops/applied migration edits during O10;
- no fake defaults/Health authorization/generated plan truth;
- PR #50 remains Draft/open/unmerged unless explicitly authorized;
- O11/#54 remains blocked until O10 exact acceptance.
