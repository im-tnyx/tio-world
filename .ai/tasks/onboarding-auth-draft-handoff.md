# Onboarding Auth Draft Handoff

**Status:** Implemented — automated slice validation green; real-device validation pending
**Tracking:** GitHub issue #13 (related to #10)
**Source branch:** `codex/onboarding-mode-migration`
**Primary owner:** `apps/app`

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

Google signup establishes a Supabase session and bootstrap can redirect `/login -> /onboarding` before the original `context.push()`/controller continuation resumes. The original auto-disposed onboarding controller can therefore disappear with the pre-auth draft. A fresh account has no remote draft yet, so a newly built onboarding controller would otherwise fall back to App Mode.

## Implemented behavior

```text
profile completed
-> AppOnboardingController prepares the exact next top-level draft
-> OnboardingAuthDraftHandoff stages it before opening auth
-> fresh Google signup establishes Supabase identity
-> handoff binds to that identity
-> bootstrap may redirect immediately to /onboarding
-> production onboarding provider consumes the staged draft once for that user
-> normal hydrateDraft() still runs
-> if a remote user-owned draft exists, remote draft wins
-> otherwise staged draft continues
-> App Mode/Profile are not repeated
```

Existing completed Tio accounts remain governed by authenticated bootstrap and route Home. A handoff that is not consumed remains bound to that identity and is cleared on sign-out; it cannot be consumed by a different user.

## Guardrails preserved

- No rendered UI/layout change.
- No Supabase schema/data migration.
- No account row mutation/deletion.
- Auth-state redirect race does not depend on `context.pop(true)`.
- Unauthenticated routes cannot consume a staged draft.
- A conflicting authenticated identity invalidates the staged draft.
- Remote `onboarding_drafts` remains user-scoped and authoritative when present.
- Cancellation/failure clears the transient handoff when no Supabase session was established.

## Implementation

- [x] Make the auth checkpoint expose a resume-after-auth draft that has already advanced past Profile.
- [x] Add app-owned transient one-shot `OnboardingAuthDraftHandoff`.
- [x] Stage the resume draft before AuthLanding is opened by the existing callback.
- [x] Override the production `onboardingControllerProvider` so a redirected authenticated onboarding route can consume the staged draft.
- [x] Bind/consume the staged draft by authenticated Supabase user ID.
- [x] Keep normal `hydrateDraft()` after seeding so an existing remote draft remains authoritative.
- [x] Preserve completed-account bootstrap -> Home behavior.
- [x] Add focused resume, cancellation, identity-isolation, one-shot, and remote-precedence tests.
- [x] Run automated analyzer/test validation.
- [ ] Real-device test fresh Google signup resumes after Profile instead of App Mode.

## Automated validation

GitHub Actions run #68 on commit `e12d5233b50dc800054bc8145f334739df6cee64`:

- Flutter analyzers: all packages passed.
- Dart analyzer: passed.
- `apps/app/test/app/onboarding_auth_draft_handoff_test.dart`: 5/5 passed.
  - unauthenticated/wrong-identity isolation
  - matching one-shot consumption
  - exact first post-Profile resume step staged before auth returns
  - cancellation clears unconsumed handoff
  - remote user-owned draft overrides transient seed
- Existing session bootstrap regression tests passed.

The workspace test job remains red because of 10 unrelated pre-existing app test failures (`welcome_accessibility_test.dart`, `tio_avatar_test.dart`, and `app_mode_router_test.dart`). Baseline run #57 on pre-handoff commit `42dc360feb466511c0119d807db1f6aaa97670cb` had the same 10 failures and 97 passing tests. Run #68 has the same failure set and 102 passing tests, with the +5 being this slice's new passing tests.

## Device gate

Expected fresh-account flow:

```text
Get Started
-> App Mode
-> Profile
-> Continue/auth checkpoint
-> choose a fresh Google account
-> session/bootstrap
-> resume at first post-Profile onboarding step
-> must NOT show App Mode or Profile again
```
