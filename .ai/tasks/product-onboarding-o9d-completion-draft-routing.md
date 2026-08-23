# Product Onboarding O9D — Completion / Draft Lifecycle / Routing

**Status:** Active  
**Tracker:** GitHub Issue #93  
**Parent O9:** #88  
**O9A:** #89 ✅ / CI #1627  
**O9B:** #90 ✅ / CI #1630  
**O9C:** #91 ✅ / CI #1634  
**Implementation PR:** #50 Draft/open/unmerged

## Starting exact validated checkpoint

```text
b5fe3ce741c3ba093e284ae0dbf893ae4e960ca9
Flutter CI #1634 / run 32637390199 / job 97189092932 ✅
Android Native CI #46 / run 32637390197 / job 97189105902 ✅
```

## Audit result

Domain/controller lifecycle is already correct:

- durable completion precedes draft clear;
- failed completion does not clear draft;
- draft clear is best-effort after success;
- `OnboardingController` uses `isCompleting` as a single-flight guard;
- Finish errors remain retryable on Review.

App router has an ordering race: it calls `onboardingStatusController.markCompleted()` before explicit Congratulations navigation. Because that controller refreshes GoRouter and completed `/onboarding` redirects to Home, the intended Congratulations screen can be skipped.

## Scope

- navigate to Congratulations first when context is mounted;
- publish in-memory completed status immediately after that navigation;
- still mark completed if context is unexpectedly unmounted after durable completion;
- preserve bootstrap completion handoff;
- add route-policy acceptance that Congratulations is allowed both before and after completed status, while stale completed `/onboarding` still redirects Home.

## Acceptance

- [ ] Congratulations route allowed in-progress;
- [ ] Congratulations route allowed completed;
- [ ] stale completed onboarding route still redirects Home;
- [ ] router order is durable use-case → Congratulations navigation → in-memory completed publish;
- [ ] controller finish remains single-flight/retryable;
- [ ] draft failure/success semantics unchanged;
- [ ] no schema/owner/migration change;
- [ ] all Flutter/Dart gates + Android native build green on exact SHA.

## Exit

Freeze O9D, close #93, then run O9E integrated O9 acceptance.
