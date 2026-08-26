# Phone-First Same-Screen Auth Entry UI

**Status:** Partial — source complete, executable/runtime validation pending
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
- `/login` remains Phone-first.
- Legacy `/login/email` resolves the same `LoginPage` directly in Email mode.
- Existing `/login/email-signup` remains the compatible Signup path while the page itself is Phone-first.
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
- `LoginPage` and `EmailSignupPage` expose local `AuthEntryMode.phone/email` state and default to Phone unless an explicit compatible route intent selects Email.
- `PhoneOtpAuthSection` is shared by Login/Signup and delegates only to `RequestPhoneOtpUseCase`, `ResendPhoneOtpUseCase`, and `VerifyPhoneOtpUseCase`.
- Request success is represented by `PhoneOtpCodeSent`; only verification can emit `SignInSuccess`.
- Login uses `PhoneOtpIntent.login`; Signup uses `PhoneOtpIntent.signup`.
- `TioSocialButton.round` is a reusable core variant with a 56dp circular action, visible label, button semantics, and theme-governed colors/geometry.
- `apps/core/lib/src/theme/README.md` now documents `TioSocialButton.round` as the shared provider/mode action contract and keeps provider ordering/state feature-owned.
- `AuthRoundActions` composes Google, existing Truecaller, and the reciprocal Email/Phone action without duplicating the core component.
- `PhoneOtpAuthScope` lets app composition inject production Phone OTP use cases while pages still accept explicit dependencies for tests/isolated hosts.
- `AppRoutes.signup` aliases the existing `/login/email-signup` route so old links remain resolvable.
- `LoginPage` resolves `/login/email` to `AuthEntryMode.email` when no explicit mode was supplied; isolated hosts/tests retain Phone-first default unless they opt into Email explicitly.
- Fresh branch compare against PR #127 remains linear with merge-base equal to the exact PR #127 head and no Account Setup/Supabase/schema files.

### Audit Corrections Applied

The first Phone-first branch pass changed Signup defaults and round-action keys but left existing Email Signup widget tests assuming the old default Email form/full-width Google key. Those tests would fail when executable validation becomes available.

The audit corrected source/test drift by:

- adding Phone-first Signup default/mode-switch/Signup-intent verification coverage;
- preserving Email-specific behavior tests with `initialMode: AuthEntryMode.email`;
- updating Google loading/signup assertions to the round-action keys;
- adding a route-aware Login regression proving legacy `/login/email` opens the same `LoginPage` in Email mode;
- documenting the new public `TioSocialButton.round` contract in the design-system README.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Phone is default mode | Approved | #118 product contract |
| Mode switching is same-screen | Approved | avoid back-stack churn |
| Round action is core-owned | Approved | reused by Signup and Login |
| `/login/email` opens Email mode | Chosen | preserve strict legacy deep-link intent without duplicating a screen |
| `/login/email-signup` remains compatible but Phone-first | Chosen | it is also the canonical generic Signup path through `AppRoutes.signup` |
| Phone OTP verify must return real session | Frozen | #126 trust boundary |
| No Account Setup work in this slice | Chosen | keep one bounded slice active |
| Runtime production acceptance remains gated | Frozen | executable validation + hosted SMS/session smoke still pending |

## 4. Architecture Design

```text
/login
→ LoginPage
→ Phone mode

/login/email
→ same LoginPage
→ Email mode

Signup route
→ same EmailSignupPage
→ Phone mode

Phone form
→ TioMobileNumberField
→ Request/ResendPhoneOtpUseCase
→ OTP input
→ VerifyPhoneOtpUseCase
→ SignInSuccess
→ existing app bootstrap refresh callback

Email form
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
- [x] update `apps/core/lib/src/theme/README.md` for the new public reusable round-action contract;
- [x] preserve `/login/email` strict Email-mode intent on the same `LoginPage`;
- [x] run parent-to-head GitHub ancestry/scope audit;
- [ ] run Flutter/Dart validation when an executable environment is available;
- [ ] run controlled hosted SMS delivery/session smoke now that Phone Auth is enabled;
- [ ] record runtime acceptance only after those gates pass.

## 6. Quality Review

### Current Validation

```text
Stack base                         c223d5874417b7e5dfb381890c56874d472387cc
Merge base                        exact stack base
Branch state                      ahead 24 / behind 0 before this task update
Changed files                     16 before this task update
Scope                             apps/features/auth, apps/core auth UI/routing/docs,
                                  apps/app Phone OTP composition, focused task/tests
Account Setup changes             none
Supabase migration/config changes none
Production Supabase mutation      none

Flutter/Dart executable validation: NOT RUN, toolchain unavailable here.
Hosted SMS delivery/session smoke: NOT RUN yet; user reports Phone Auth is enabled.
```

### Review Findings and Resolution

1. **Signup test drift found and repaired.** Old widget tests assumed Email was still the default and referenced removed full-width social-action keys.
2. **Legacy Email route intent preserved.** `/login/email` now resolves the same mode-driven Login page in Email mode instead of silently becoming Phone-first.
3. **Core contract documentation complete.** `TioSocialButton.round` is documented without introducing an Auth token bag.
4. **No scope contamination found.** No Account Setup, onboarding, profile, database, migration, hook, or Edge Function file is in the branch delta.
5. **Runtime acceptance remains intentionally pending.** Source/test coverage is not equivalent to executed Flutter tests or a real hosted SMS verification.

## 7. Final Handoff

### Changed Areas

- `.ai/tasks/auth-mobile-first-entry-ui.md`
- `apps/app/lib/app/app.dart`
- `apps/app/lib/app/auth_phone_otp_providers.dart`
- `apps/core/lib/src/routing/routes/app_routes.dart`
- `apps/core/lib/src/theme/README.md`
- `apps/core/lib/src/ui/components/buttons/tio_social_button.dart`
- `apps/features/auth/lib/src/presentation/**`
- focused Auth presentation tests

### Actual Behavior

Source now implements the bounded #128 Phone-first Signup/Login entry surface. Phone OTP request/resend/verify is consumed from #126; Email + Password remains same-screen; Google/Truecaller remain fixed round actions; request-code success is not treated as authentication; and `/login/email` preserves direct Email-mode intent without maintaining a duplicate Login screen.

### Known Limitations

- Flutter/Dart tests have not executed in this environment.
- Real hosted SMS delivery/session smoke remains unverified.
- PR #127 remains Draft and is not yet runtime-accepted.
- #125 Email/Google hosted smoke remains deferred.

### Final Status

`PARTIAL` — source-review items are complete and scope remains clean; only executable Flutter/Dart validation plus controlled real SMS/session validation remain before runtime acceptance.
