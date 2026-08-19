# Onboarding Pre-Auth Draft Persistence

**Status:** Validated for the #13 auth/account/onboarding handoff and root logout/resume flow
**Tracking:** GitHub issue #13 (related historical work: #10 and profile persistence #8)
**Source branch:** `codex/onboarding-mode-migration`
**Current follow-up branch:** `agent/app-mode-pre-signup` / PR #36
**Primary owner:** `apps/app` + `apps/features/onboarding` + affected owner repositories

## Durable outcome

The original task fixed draft loss and wrong-step rendering around the older pre-auth onboarding/auth handoff. The active #13 architecture is now auth-first:

```text
Welcome
→ App Mode (pre-auth local selection)
→ Signup
→ Account Setup
→ authenticated Product Onboarding
→ App
```

The durable ownership rules that remain relevant are:

- signed-out sensitive onboarding/profile draft state stays encrypted device-local;
- authenticated unfinished onboarding state is user-bound and may persist remotely behind the repository contract;
- an existing user-owned remote draft remains authoritative when present;
- identity mismatch/stale local state is rejected safely;
- completion clears only safely committed obsolete draft state;
- Product Onboarding hydration is gated so an unresolved default step does not flash before the real resume draft resolves;
- root logout is a session exit, not a discard-progress action.

## Product Onboarding root Back/logout contract

Profile Name remains the authenticated root exit boundary.

```text
Gender -> Back -> Name
Name -> Back -> logout confirmation

Stay
→ remain on Name
→ remain authenticated
→ keep draft

Log out
→ persist the safe resume draft
→ sign out
→ refresh session bootstrap
→ Welcome
```

Visible Back and Android/system Back use the same internal-vs-root decision. The confirmation uses reusable `TioConfirmationCard` and does not introduce feature-local visual tokens.

## Resume semantics

Back navigation is not durable progress rewind.

```text
furthest reached = Activity
Activity -> Back -> ... -> Name
Name -> Logout
same account login -> Activity
```

The controller may show earlier screens for review/edit while `ResumePreservingOnboardingDraftRepository` preserves the furthest still-valid persisted checkpoint. Earlier invalid edits reconcile to the prerequisite instead of resuming into an invalid downstream screen.

The focused implementation/validation brief is `.ai/tasks/onboarding-back-resume-checkpoint.md`.

## Implemented safeguards retained from the original handoff

- encrypted local draft storage;
- auth-aware local/remote draft repository;
- identity binding and mismatch protection;
- remote read failures are not treated as confirmed missing data;
- hydration readiness gate before Product Onboarding content renders;
- owner-data persistence/mapping regressions from the earlier flow;
- root logout does not call draft clear/reset;
- explicit awaited final draft save before confirmed root logout;
- automated coverage for auth resume, Back parity, root confirmation/logout, and resume checkpoint preservation.

## Automated validation

Latest validated PR head before this documentation-only closure update:

```text
head: 81d187300a528a5d41ececaf374cf6637639c8e4
Flutter CI: #927
run: 32287172622

Bootstrap workspace      PASS
Analyze Flutter packages PASS
Analyze Dart packages    PASS
Test Flutter packages    PASS
Test Dart packages       PASS
```

This supersedes the older CI #897 validation note for the active #13 branch.

## Real-device acceptance — 2026-08-20

Owner/device smoke passed for the active product flow:

- Back works through Product Onboarding.
- Next/Continue works through the tested flow.
- Profile completion card appears correctly.
- Backing to Name and logging out returns to Welcome.
- Signing in again with the same account resumes at the previously reached valid onboarding step rather than the Back destination.
- Back remains available after resume for further review/edit.

This closes the real-device acceptance gate for the #13 Product Onboarding root logout/resume behavior.

## Historical nutrition projection note

The older handoff task also tracked projection of collected height/current weight/target weight/activity into nutrition-owned persistence. That historical data projection work is not the blocking acceptance gate for the current #13 App Mode/account/onboarding flow. Any additional read-only production-data revalidation/backfill decision remains separate and must not be inferred from this device smoke.

## Exit criteria for #13 handoff

- [x] authenticated Product Onboarding resumes without wrong default-step flash;
- [x] root Back reaches Name before logout confirmation;
- [x] Stay preserves authenticated draft state;
- [x] confirmed logout returns to Welcome without clearing onboarding progress;
- [x] Back does not permanently rewind the next-login resume checkpoint;
- [x] same-account relogin restores the furthest still-valid step;
- [x] automated CI green;
- [x] primary real-device flow green.

## Final handoff

`VALIDATED FOR #13` — ready for PR #36 review/merge. Keep Issue #13 open until the PR merges.