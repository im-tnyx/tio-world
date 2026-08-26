# Phone-First Same-Screen Auth Entry UI

**Status:** In progress
**Primary owner:** `apps/features/auth`, reusable auth action presentation in `apps/core`, app composition in `apps/app`
**Related issue:** #128
**Parent issue:** #118
**Stack base:** PR #127 / `agent/auth-phone-otp-capability-clean` @ `c223d5874417b7e5dfb381890c56874d472387cc`
**Working branch:** `agent/auth-mobile-first-entry-ui`

## 1. Discovery

### User Outcome

Signup and Login open in Phone mode, use real Phone OTP through the #126 capability, and switch to Email + Password on the same surface. Google and the existing Truecaller action remain fixed. Email and Phone are reciprocal third actions rendered as reusable round icon + visible-label actions.

### Success Criteria

- Signup and Login default to Phone mode.
- Phone mode can request, resend, and verify Phone OTP through the #126 use cases.
- `PhoneOtpIntent.signup` is used for Signup and `PhoneOtpIntent.login` for Login.
- Code delivery never counts as authenticated success.
- Email ↔ Phone switching changes local page state only and does not push a route.
- Phone mode actions are Google / Truecaller / Email; Email mode actions are Google / Truecaller / Phone.
- Existing `/login`, `/login/email`, and `/login/email-signup` paths continue to resolve safely.
- Round provider/mode actions are shared through `apps/core`, visible-label and semantics-safe.
- No Account Setup, schema, migration, hook, Edge Function, or hosted Auth configuration change.

### Scope

- Auth entry mode presentation state;
- Signup/Login Phone form + OTP stage;
- Phone OTP use-case composition providers;
- reusable round action variant in core;
- existing Auth route compatibility;
- focused source/widget test coverage.

### Non-Goals

- #118 complementary Account Setup Email step;
- optional Mobile Account Setup changes;
- new Truecaller implementation;
- #125 Email/Google smoke;
- hosted SMS provider setup or real SMS smoke;
- password reset/change-password;
- Google linking/unlinking;
- any database change;
- Ready/merge.

## 2. Codebase Exploration

### Verified Evidence

- PR #127 supplies the dedicated real-session Phone OTP request/resend/verify capability and canonical E.164 boundary.
- `LoginPage` and `EmailSignupPage` now expose local `AuthEntryMode.phone/email` state and default to Phone.
- `PhoneOtpAuthSection` is shared by Login/Signup and delegates only to `RequestPhoneOtpUseCase`, `ResendPhoneOtpUseCase`, and `VerifyPhoneOtpUseCase`.
- Request success is represented by `PhoneOtpCodeSent`; only verification can emit `SignInSuccess`.
- Login uses `PhoneOtpIntent.login`; Signup uses `PhoneOtpIntent.signup`.
- `TioSocialButton.round` is a reusable core variant with a 56dp visible circular action, visible label, button semantics, and theme-governed colors/geometry.
- `AuthRoundActions` composes Google, existing Truecaller, and the reciprocal Email/Phone action without duplicating the core component.
- `PhoneOtpAuthScope` lets the app composition inject production Phone OTP use cases while pages still accept explicit dependencies for tests/isolated hosts.
- `AppRoutes.signup` currently aliases the existing `/login/email-signup` route so old links remain resolvable.
- `/login/email` also remains routable. The current router renders the same Phone-first `LoginPage`; if strict legacy semantic compatibility requires Email mode immediately on that deep link, an explicit router initial-mode adjustment remains a bounded follow-up before final acceptance.
- Fresh branch compare against PR #127 is linear with merge-base equal to the exact PR #127 head and no Account Setup/Supabase/schema files.

### Audit Correction Applied

The first Phone-first branch pass changed Signup defaults and round-action keys but left existing Email Signup widget tests assuming the old default Email form/full-width Google key. Those tests would fail when executable validation becomes available.

The audit corrected test source by:

- adding Phone-first Signup default/mode-switch/Signup-intent verification coverage;
- preserving Email-specific behavior tests with `initialMode: AuthEntryMode.email`;
- updating Google loading/signup assertions to the round-action keys.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Phone is default mode | Approved | #118 product contract |
| Mode switching is same-screen | Approved | avoid back-stack churn |
| Round action is core-owned | Approved | reused by Signup and Login |
| Existing Email route paths stay resolvable | Chosen | backwards compatibility |
| Phone OTP verify must return real session | Frozen | #126 trust boundary |
| No Account Setup work in this slice | Chosen | keep one bounded slice active |
| Runtime production acceptance remains gated | Frozen | PR #127 executable validation + hosted SMS/session smoke still pending |

## 4. Architecture Design

```text
Login / Signup page
→ local AuthEntryMode(phone | email)

phone
→ TioMobileNumberField
→ Request/ResendPhoneOtpUseCase
→ OTP input
→ VerifyPhoneOtpUseCase
→ SignInSuccess
→ existing app bootstrap refresh callback

email
→ existing Email + Password use case

OR
→ reusable TioSocialButton.round
   Google | Truecaller | reciprocal Email/Phone action
```

`Code sent` remains a request state, never `SignInSuccess`. Switching mode clears the active request/error state by rebuilding the mode-owned form and does not mutate Auth identity or route history.

## 5. Implementation Plan

- [x] create bounded child issue #128 and stacked branch on exact PR #127 head;
- [x] inspect current Auth pages, core actions, mobile input, routes, and app providers;
- [x] add reusable round `TioSocialButton` presentation variant;
- [x] add `AuthEntryMode` presentation state;
- [x] wire Phone OTP providers in app composition;
- [x] make Login Phone-first and same-screen switchable;
- [x] make Signup Phone-first and same-screen switchable;
- [x] add focused Login mode/Phone OTP source tests;
- [x] audit and repair stale Signup tests for the new default/round-action contract;
- [ ] update `apps/core/lib/src/theme/README.md` for the new public reusable round-action contract;
- [ ] decide whether `/login/email` must open directly in Email mode or only remain a safe compatibility path;
- [x] run parent-to-head GitHub ancestry/scope audit;
- [ ] run Flutter/Dart validation when an executable environment is available;
- [ ] record final #128/#118 checkpoint after the remaining source-review items are resolved.

## 6. Quality Review

### Current Validation

```text
Stack base                         c223d5874417b7e5dfb381890c56874d472387cc
Merge base                        exact stack base
Branch state                      ahead 20 / behind 0 at audit checkpoint
Changed files                     15
Scope                             apps/features/auth, apps/core auth UI/routing,
                                  apps/app Phone OTP composition, focused task/tests
Account Setup changes             none
Supabase migration/config changes none
Production Supabase mutation      none

Flutter/Dart executable validation: NOT RUN, toolchain unavailable here.
Hosted SMS delivery/session smoke: NOT RUN, separately gated by controlled phone/provider readiness.
```

### Review Findings and Resolution

1. **Signup test drift found and repaired.** Old widget tests assumed Email was still the default and referenced removed full-width social-action keys.
2. **No scope contamination found.** No Account Setup, onboarding, profile, database, migration, hook, or Edge Function file is in the branch delta.
3. **Core contract documentation is still pending.** `TioSocialButton.round` materially expands a reusable core API, so the theme README must be updated before this slice can be handed off as complete.
4. **Email deep-link semantics need one final decision.** The paths remain valid, but `/login/email` currently inherits Phone-first default. This is safe routing, but may not preserve strict mode intent.
5. **Runtime acceptance remains intentionally deferred.** Test source is not equivalent to executed Flutter tests or real hosted SMS verification.

## 7. Final Handoff

### Changed Areas

- `.ai/tasks/auth-mobile-first-entry-ui.md`
- `apps/app/lib/app/app.dart`
- `apps/app/lib/app/auth_phone_otp_providers.dart`
- `apps/core/lib/src/routing/routes/app_routes.dart`
- `apps/core/lib/src/ui/components/buttons/tio_social_button.dart`
- `apps/features/auth/lib/src/presentation/**`
- focused Auth presentation tests

### Actual Behavior

Source now implements the bounded #128 Phone-first Signup/Login entry surface. Phone OTP request/resend/verify is consumed from #126; Email + Password remains same-screen; Google/Truecaller remain fixed round actions; and request-code success is not treated as authentication.

### Known Limitations

- Flutter/Dart tests have not executed in this environment.
- Hosted SMS provider readiness and real SMS/session smoke remain unverified.
- PR #127 remains Draft and not runtime-accepted.
- #125 Email/Google hosted smoke remains deferred.
- `apps/core/lib/src/theme/README.md` still needs the round-action usage contract before final source handoff.
- `/login/email` direct-Email-mode semantics remain to be confirmed/fixed if required.

### Final Status

`PARTIAL` — bounded implementation exists and scope audit is clean, with two source-review items plus executable/runtime validation still pending.
