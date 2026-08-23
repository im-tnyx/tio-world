# Product Onboarding O9D — Completion / Draft Lifecycle / Routing

**Status:** Completed ✅  
**Tracker:** GitHub Issue #93 ✅  
**Parent O9:** #88  
**O9A:** #89 ✅ / CI #1627  
**O9B:** #90 ✅ / CI #1630  
**O9C:** #91 ✅ / CI #1634  
**Implementation PR:** #50 Draft/open/unmerged

## Exact validated checkpoint

```text
1537c6f3a8d7b7b8d369f8b4a4d65456d695ae3c
Flutter CI #1638 / run 32637962253 / job 97190475798 ✅
Android Native CI #50 / run 32637962231 / job 97190450781 ✅
```

## Frozen result

Domain/controller lifecycle remains unchanged and correct:

- durable completion precedes draft clear;
- failed completion does not clear draft;
- draft clear is best-effort after success;
- `OnboardingController` uses `isCompleting` as a single-flight guard;
- Finish errors remain retryable on Review.

The app routing race is fixed. After durable completion, mounted onboarding context navigates to Congratulations before `onboardingStatusController.markCompleted()` notifies GoRouter. Completed status is still published even if the original context is unmounted, and bootstrap completion handoff is no longer incorrectly scoped under mounted context.

## Acceptance

- [x] Congratulations route allowed in-progress;
- [x] Congratulations route allowed completed;
- [x] stale completed onboarding route still redirects Home;
- [x] router order is durable use-case → Congratulations navigation → in-memory completed publish;
- [x] controller finish remains single-flight/retryable;
- [x] draft failure/success semantics unchanged;
- [x] no schema/owner/migration change;
- [x] all Flutter/Dart gates + Android native build green on exact SHA.

## Exit

O9D is frozen complete. Run O9E integrated O9 acceptance.
