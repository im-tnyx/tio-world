# Product Onboarding O9 — Plan Building / Finalization

**Status:** Active / audit  
**Tracker:** GitHub Issue #88  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Predecessor O8:** #82 ✅ / CI #1621  
**Implementation PR:** #50 Draft/open/unmerged  
**O10:** pending  
**O11 cleanup:** #54 blocked until O10

## Starting exact validated checkpoint

```text
bbe78206ac06344c243b633b22f2598f33e5a703
Flutter CI #1621 / run 32629836907 / job 97170826659 ✅
Android Native CI #33 / run 32629836917 / job 97170803705 ✅
```

Later O8 task/tracker commits are documentation-only and do not replace this runtime baseline.

## Goal

Validate the transition from reviewed onboarding state into finalized canonical owner-backed state without false completion, partial publication, fabricated values or destructive failure handling.

## Audit-first questions

- What exact UI/controller action leaves Review and invokes finalization?
- Is completion eligibility recomputed at commit time?
- Which canonical owners are written and in what order?
- Which writes are conditional on App Mode / Hybrid setup choice?
- What plan/recommendation artifacts, if any, are created during O9 versus later feature-specific flows?
- What happens if Profile, Body, Wellness, Workout, Nutrition or completion publication fails midway?
- Can retry safely converge without duplicate durable truth?
- When is `onboarding_drafts` cleared, and does failure preserve a recoverable draft?
- What durable state makes subsequent app bootstrap route away from onboarding?
- Does finalization preserve O8 historical unknown/provenance semantics?

## Expected slices

```text
O9A finalization runtime + completion eligibility contract      ACTIVE / AUDIT
O9B canonical owner write ordering + failure atomicity          PENDING
O9C plan/recommendation publication + mode-specific semantics   PENDING
O9D successful completion, draft lifecycle + routing            PENDING
O9E integrated O9 acceptance                                    PENDING
```

Slice boundaries may be narrowed after source/test audit.

## Guardrails

- source/config and canonical owner contracts are behavior truth;
- test-first when a behavior gap is suspected;
- no fabricated defaults or health authorization;
- no permanent dual write;
- no broad finalization rewrite without focused evidence;
- no schema-version bump unless proven necessary;
- no applied migration edits or legacy-column drops;
- no destructive O11 cleanup before O10;
- PR #50 remains Draft/open/unmerged.

## Exit

Freeze O9 exact source + Flutter/Android CI evidence, then activate O10 Integrated Final Acceptance.
