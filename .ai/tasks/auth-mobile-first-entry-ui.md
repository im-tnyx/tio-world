# Phone-First Same-Screen Auth Entry UI

**Status:** In progress
**Primary owner:** `apps/features/auth`, reusable auth action presentation in `apps/core`, app composition in `apps/app`
**Related issue:** #128
**Parent issue:** #118
**Stack base:** PR #127 / `agent/auth-phone-otp-capability-clean` @ `c223d5874417b7e5dfb381890c56874d472387cc`
**Working branch:** `agent/auth-mobile-first-entry-ui`

## 1. Discovery

### User Outcome

Signup and Login open in Phone mode, use real Phone OTP through the #126 capability, and switch to Email + Password on the same surface. Google and the existing Truecaller action remain fixed. Email and Phone are reciprocal third actions rendered as reusable round icon + label actions.

### Success Criteria

- Signup and Login default to Phone mode.
- Phone mode can request, resend, and verify real Phone OTP through the existing use cases.
- `PhoneOtpIntent.signup` is used for Signup and `PhoneOtpIntent.login` for Login.
- Code delivery never counts as authenticated success.
- Email ↔ Phone switching changes local page state only and does not push a route.
- Phone mode actions are Google / Truecaller / Email; Email mode actions are Google / Truecaller / Phone.
- Existing `/login`, `/login/email`, and `/login/email-signup` routes remain valid.
- Round provider/mode actions are shared through `apps/core`, visible-label and semantics-safe.
- No Account Setup, schema, migration, hook, Edge Function, or hosted Auth configuration change.

### Scope

- Auth entry mode presentation state;
- Signup/Login Phone form + OTP stage;
- Phone OTP use-case composition providers;
- reusable round action variant in core;
- focused source/widget tests where practical.

### Non-Goals

- #118 complementary Account Setup Email step;
- optional Mobile Account Setup changes;
- Truecaller implementation;
- #125 Email/Google smoke;
- hosted SMS provider setup or real SMS smoke;
- password reset/change-password;
- Google linking/unlinking;
- any database change;
- Ready/merge.

## 2. Codebase Exploration

### Verified Evidence

- `LoginPage` currently defaults to Email + Password and already owns Google + Truecaller actions.
- `EmailSignupPage` currently defaults to Email + Password and already owns Google + Truecaller actions.
- `TioSocialButton` already models `google`, `truecaller`, `email`, and `phone`, but only as full-width actions.
- `TioMobileNumberField` is the reusable Phone input and currently presents India `+91` national-number entry while persistence/Auth canonicalization remains outside the widget.
- PR #127 adds `RequestPhoneOtpUseCase`, `ResendPhoneOtpUseCase`, `VerifyPhoneOtpUseCase`, `PhoneOtpIntent`, and a real-session-only Supabase adapter.
- `apps/app/lib/app/network_providers.dart` currently composes Email/Google Auth use cases but not Phone OTP use cases.
- `apps/app/lib/app/router.dart` composes Login/Signup callbacks through the existing app-session bootstrap refresh path.
- Existing Email route contracts are compatibility surfaces and can keep their current paths while pages become mode-driven.
- `apps/core/lib/src/theme/README.md` explicitly permits a reusable component/variant when cross-context reuse is proven; Signup + Login provide that evidence.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Phone is default mode | Approved | #118 product contract |
| Mode switching is same-screen | Approved | avoid back-stack churn |
| Round action is core-owned | Approved | reused by Signup and Login |
| Existing Email route paths stay valid | Chosen | backwards compatibility |
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
→ reusable TioSocialButton round variant
   Google | Truecaller | reciprocal Email/Phone mode action
```

`Code sent` remains a request state, never `SignInSuccess`. Switching mode clears the active request/error state but does not mutate route history or Auth identity.

## 5. Implementation Plan

- [x] create bounded child issue #128 and clean stacked branch;
- [x] inspect current Auth pages, core actions, mobile input, routes, and app providers;
- [ ] add reusable round `TioSocialButton` presentation variant;
- [ ] add `AuthEntryMode` presentation state;
- [ ] wire Phone OTP providers in app composition;
- [ ] make Login Phone-first and same-screen switchable;
- [ ] make Signup Phone-first and same-screen switchable;
- [ ] add focused mode/action/OTP-stage source tests;
- [ ] run parent-to-head scope audit;
- [ ] run Flutter/Dart validation when executable environment is available;
- [ ] record #128/#118 checkpoint.

## 6. Quality Review

### Current Validation

```text
Task/source audit only so far.
Flutter/Dart executable validation: not run yet.
Hosted SMS delivery/session smoke: not run; separately gated.
Production Supabase mutation in this slice: none.
```

## 7. Final Handoff

### Current Status

`PARTIAL` — bounded slice is active; implementation pending.
