# Onboarding Auth Draft Handoff

**Status:** In progress — root cause verified, implementation pending
**Tracking:** GitHub issue #13 (related to #10)
**Source branch:** `codex/onboarding-mode-migration`
**Primary owner:** `apps/features/onboarding` + `apps/app`

## User-reported regression

Real-device validation after the Google login admission fix:

```text
Login
fresh Google -> no-account message (correct)
existing Tio Google -> login (correct)

Get Started / onboarding
choose App Mode
complete Profile
Google auth checkpoint
select fresh Google account
-> app returns to App Mode (incorrect)
```

## Verified root cause

`OnboardingController.next()` triggers `onAuthRequired` only after the final Profile sub-step. The in-memory draft already contains App Mode and Profile answers at that point.

Before authentication, `SupabaseOnboardingDraftRepository` cannot save that draft because there is no authenticated `user_id`.

Google signup establishes a Supabase session and bootstrap can redirect `/login -> /onboarding` before the original `context.push()`/controller continuation resumes. The original auto-disposed onboarding controller can therefore disappear with the pre-auth draft. The newly built onboarding route currently receives a fresh `OnboardingDraft`; a fresh account has no remote draft yet, so flow planning falls back to App Mode.

## Frozen behavior

```text
profile completed
-> prepare resume-after-auth draft at the next top-level step
-> stage that draft before opening auth
-> fresh Google signup
-> bootstrap may redirect immediately
-> authenticated /onboarding consumes the staged draft once
-> if a remote user-owned draft exists, hydrate/remote draft remains authoritative
-> otherwise continue the staged draft
-> do not repeat App Mode or Profile
```

Existing completed Tio account selected at the checkpoint remains governed by authenticated bootstrap and must route Home.

## Guardrails

- No rendered UI/layout change.
- No Supabase schema/data migration.
- Do not rely only on `context.pop(true)`; auth-state redirects can race it.
- Never consume an unbound staged draft while unauthenticated.
- Never leak a staged draft from one authenticated identity into another or into a later logged-out onboarding attempt.
- Remote `onboarding_drafts` remains user-scoped and authoritative when present.
- Cancellation/failure clears the transient handoff.

## Implementation plan

- [ ] Make the auth checkpoint expose a `resumeAfterAuth` draft that has already advanced past Profile.
- [ ] Add a small app-owned transient one-shot handoff object.
- [ ] Stage the resume draft before pushing AuthLanding.
- [ ] Seed a freshly redirected authenticated onboarding route from the staged draft.
- [ ] Ensure the staged draft is not consumed when unauthenticated and cannot cross identities.
- [ ] Keep existing completed-account bootstrap -> Home behavior unchanged.
- [ ] Add focused controller regression for the resume draft.
- [ ] Add handoff lifecycle/isolation unit tests.
- [ ] Run onboarding/app targeted tests and analyzers.
- [ ] Real-device test fresh Google signup resumes after Profile instead of App Mode.
