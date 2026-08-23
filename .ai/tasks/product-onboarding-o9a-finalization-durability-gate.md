# Product Onboarding O9A — Finalization Durability Gate

**Status:** Active  
**Tracker:** GitHub Issue #89  
**Parent O9:** #88  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Predecessor O8:** #82 ✅ / CI #1621  
**Implementation PR:** #50 Draft/open/unmerged

## Starting exact validated checkpoint

```text
bbe78206ac06344c243b633b22f2598f33e5a703
Flutter CI #1621 / run 32629836907 / job 97170826659 ✅
Android Native CI #33 / run 32629836917 / job 97170803705 ✅
```

## Audit result

The domain finalizer already rechecks completion eligibility and orders completion publication after owner persistence. The app composition currently overstates durability:

- Review/UI validator uses `hasDurableOwnerPersistence: true` unconditionally;
- router finalization repeats `const hasDurableStorage = true`;
- readiness can become true when Supabase is unavailable;
- without Supabase, canonical Body/Wellness/Workout/Nutrition repositories are in-memory fallbacks.

O9A must fail closed unless the canonical Supabase owner path exists and the Supabase user is authenticated.

## Scope

- add a single app-level durability/readiness contract builder;
- Supabase client absent → not durable / not backend-ready;
- Supabase client present but user absent → durable capability exists / backend not ready;
- Supabase client + authenticated user → durable / backend ready;
- use the same contract for the Review validator provider and router commit-time validator;
- preserve in-memory fallback providers for tests/local harness construction only.

## Acceptance

- [ ] no-Supabase regression test blocks completion;
- [ ] helper truth table is explicit for absent client, unauthenticated client capability and authenticated client;
- [ ] app provider no longer hard-codes durable persistence true;
- [ ] router no longer hard-codes durable persistence true or treats Supabase absence as finalization-ready;
- [ ] existing completion order/failure/retry/idempotency tests remain green;
- [ ] no owner/schema/migration changes;
- [ ] all Flutter/Dart gates green on exact SHA;
- [ ] Android native debug build green on same SHA.

## Guardrails

- fail closed;
- no removal of safe test/local in-memory repositories;
- no O9B/O9C scope;
- no O11 cleanup;
- PR #50 remains Draft/open/unmerged.

## Exit

Freeze O9A exact CI, close #89, then continue O9B owner write ordering + failure atomicity audit.
