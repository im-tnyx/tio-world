# Mobile-First Auth Mode Switch + Complementary Contact Setup

**Status:** Blocked
**Primary owner:** `apps/features/auth`, `apps/features/account_setup`, `apps/core` reusable auth action UI; `apps/app` routing/composition
**Affected platforms:** Flutter phone app
**Related issue:** #118

## Global UI / Design-System Guardrail

This task has explicit owner approval for the visible Auth changes described below: Phone-first Signup/Login, same-screen Email ↔ Phone mode switching, and round provider/mode actions based on the supplied reference. No other Auth/Welcome redesign is authorized.

Follow `apps/core/lib/src/theme/README.md`, `.ai/tasks/design-system-token-consolidation.md`, and `apps/features/AGENTS.md`. Reuse `package:tio_core/core.dart` contracts. Do not create an Auth-specific token bag.

## 1. Discovery

### User Outcome

A user should be able to create an account or log in from a Phone-first surface, switch to Email + Password on the same screen through the Email round action, and switch back through the Phone round action.

After authentication, Account Setup should ask only for the missing complementary optional contact:

```text
Google / Email authenticated
→ trusted Email identity
→ Username
→ Mobile (optional)

Phone OTP authenticated
→ trusted Mobile identity
→ Username
→ Email (optional)
```

The already trusted contact must never be collected again merely because Account Setup runs.

### Success Criteria

- Signup defaults to Phone mode.
- Login defaults to Phone mode.
- Phone mode shows round `Google`, existing `Truecaller`, and `Email` actions.
- Tapping `Email` swaps the same surface to Email + Password mode; it does not push a second Auth screen.
- Email mode shows round `Google`, existing `Truecaller`, and `Phone` actions.
- Tapping `Phone` swaps back to Phone mode without navigation-history churn.
- Phone OTP uses real Supabase Auth and produces a canonical authenticated session.
- Google/Email trusted Email leads to the existing optional Mobile Account Setup step.
- Trusted Phone leads to a new optional Email Account Setup step.
- Complementary contact may be skipped.
- No client-generated verification truth or UUID/account switching occurs.

### Scope

- generic auth entry mode state (`phone`, `email`) for Signup and Login;
- Phone-first default Auth UX;
- reusable round provider/mode action contract in `apps/core`;
- reciprocal Email/Phone mode switching;
- route/deep-link compatibility for existing Email routes;
- Account Setup planner/session evidence expanded to distinguish trusted Email and trusted Phone;
- existing Mobile optional step for Google/Email-authenticated accounts;
- new Email optional step for Phone-authenticated accounts;
- focused state, accessibility, route, and Account Setup matrix tests.

### Non-Goals

- Facebook auth;
- implementing Truecaller auth beyond its existing capability/state;
- WhatsApp OTP;
- password policy, reset-completion, Change Password, provider linking/unlinking;
- identifier uniqueness implementation itself;
- broad Welcome/Auth visual redesign;
- Product Onboarding changes after Account Setup.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected:
  - `apps/features/auth/lib/src/presentation/email_signup/pages/email_signup_page.dart`
  - `apps/features/auth/lib/src/presentation/login/pages/login_page.dart`
  - `apps/features/auth/lib/src/domain/repositories/auth_sign_in_repository.dart`
  - `apps/core/lib/src/ui/components/buttons/tio_social_button.dart`
  - `apps/core/lib/src/theme/README.md`
  - `apps/features/account_setup/lib/src/domain/usecases/build_account_setup_flow_use_case.dart`
  - `apps/features/account_setup/lib/src/presentation/account_setup_flow_page.dart`
  - `apps/features/profile/lib/src/domain/repositories/account_setup_repository.dart`
  - `apps/features/profile/lib/src/data/repositories/supabase_account_setup_repository.dart`
  - `apps/app/lib/app/router.dart`
  - `apps/core/lib/src/routing/routes/app_routes.dart`
- Existing pattern to follow:
  - reusable `TioSocialButton` already owns Google/Truecaller/Email/Phone provider concepts, but currently renders full-width buttons;
  - `TioMobileNumberField` already exists in core and should be reused for Phone entry;
  - Account Setup already skips its Mobile collection step when a trusted Phone identity is present;
  - existing Auth contact verification work keeps Supabase Auth as the trusted verification authority.
- Current gaps:
  - `AuthSignInRepository` has no bounded Phone OTP request/resend/verify session contract;
  - Signup route/page is Email-specific in naming and default behavior;
  - Login defaults to Email + Password;
  - round provider/mode action presentation does not exist;
  - Account Setup state/planner models only optional Mobile, not complementary Email;
  - router only passes `hasTrustedPhoneIdentity`, not trusted Email + Phone evidence.
- Existing tests to extend:
  - Auth Signup/Login presentation tests;
  - Account Setup planner and flow tests;
  - route/bootstrap tests around Account Setup and auth entry.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Signup default is Phone | Approved | Mobile-first account creation UX | Product owner |
| Login default is Phone | Approved | Keep Signup/Login mental model symmetric | Product owner |
| Email and Phone are reciprocal third actions | Approved | Matches supplied reference; avoids showing both at once | Product owner |
| Email/Phone switching stays on the same screen | Approved | Avoids duplicate screens/navigation-history churn | Product owner |
| Google + existing Truecaller remain fixed provider actions | Approved | Preserve current provider set; no Facebook expansion | Product owner |
| Round icon + visible label treatment | Approved | Explicit visual direction from supplied reference | Product owner |
| Google/Email auth → optional Mobile | Approved | Existing trusted Email means Mobile is complementary | Product owner |
| Phone auth → optional Email | Approved | Trusted Mobile means Email is complementary | Product owner |
| Complementary contact is skippable | Approved | Missing secondary contact must not block Account Setup | Product owner |
| Optional Email does not automatically add Email + Password capability | Frozen | Password capability remains separate #34 work | Auth architecture |
| Phone OTP must be real Supabase Auth | Frozen | No local/fake verification truth | Auth architecture |

## 4. Architecture Design

### Chosen Approach

Use one generic mode-driven Signup composition and one generic mode-driven Login composition. The primary form changes in place based on a small Auth UI state (`phone` / `email`). Provider/mode actions come from one reusable core round-action component or an evidenced reusable variant of the current social-button family.

Account Setup evolves from `hasTrustedPhoneIdentity` to trusted contact evidence that can plan exactly one complementary optional contact step when appropriate.

### Ownership and Data Flow

```text
Signup/Login UI
→ Auth mode state
→ Phone OTP or Email/Google auth use case
→ Auth repository
→ Supabase Auth
→ canonical AuthSession
→ app bootstrap
→ Account Setup planner
→ optional complementary contact
→ trusted Auth contact update/verification adapter when verification is requested
```

Provider-neutral projection remains:

```text
auth.users Email/Phone confirmation evidence
→ trusted database reconciliation
→ public.users email/mobile + verified timestamps
```

### Route Compatibility

Existing `AppRoutes.emailSignup` / `emailLogin` deep links must not abruptly break. Preferred migration is a generic Signup/Login route with compatibility aliases/redirects or an explicit initial-mode parameter. Route names may be modernized only with backwards-compatible handling and focused tests.

### Alternative Rejected

- Separate Phone Signup page + Email Signup page pushed on every switch: rejected because the approved UX is same-surface mode switching and back-stack churn is undesirable.
- Feature-local round social buttons in both Login and Signup: rejected because the same presentation contract is reused across both surfaces.
- Writing optional Email/Mobile directly as verified Account data: rejected because Supabase Auth owns verification evidence.
- Treating optional Email on a Phone account as automatic password capability: rejected because sign-in capability and contact verification are distinct concerns.

### Failure and Accessibility States

- Phone OTP request/verify/resend must expose bounded loading, invalid/expired OTP, rate-limit/network failure, and retry states.
- Mode switching is disabled while the active auth request is non-cancellable/in flight unless the owner implementation proves safe cancellation.
- Round actions require visible labels, semantic labels, keyboard/focus compatibility where applicable, and at least a safe 48dp interaction target.
- Dark/OLED/High-Contrast/reduced-motion behavior must use existing Tio runtime theme contracts.
- Optional complementary contact failure must not report false success.

## 5. Implementation Plan

Implementation is blocked until the two dependencies below are satisfied.

### Dependency A — #34 identifier uniqueness foundation

- [ ] canonical Email/Mobile uniqueness backstop is implemented and validated;
- [ ] duplicate-account paths are controlled before additional auth entry methods ship.

### Dependency B — Phone OTP Auth capability

- [ ] bounded Phone OTP request/resend/verify repository/use-case contract;
- [ ] real Supabase Auth session result;
- [ ] typed invalid/expired/rate-limit/network failures;
- [ ] focused adapter tests.

### #118 runtime slice after dependencies

- [ ] introduce generic `AuthEntryMode.phone/email` UI state;
- [ ] make Signup Phone-first and same-screen switchable;
- [ ] make Login Phone-first and same-screen switchable;
- [ ] introduce/reuse round core provider/mode action contract;
- [ ] preserve Google behavior and existing Truecaller availability state;
- [ ] keep existing Email route compatibility;
- [ ] expand Account Setup contact evidence/planner;
- [ ] retain optional Mobile for trusted-Email users;
- [ ] add optional Email step for trusted-Phone users;
- [ ] route optional Email through trusted Supabase Auth contact update semantics;
- [ ] add focused Auth/Account Setup/accessibility regressions;
- [ ] run exact-SHA Flutter/Dart + Android validation;
- [ ] record acceptance evidence in #118 and related owners.

## 6. Quality Review

### Validation Run

```text
Not run yet. This commit is planning/audit only; runtime implementation is blocked by #34 uniqueness and Phone OTP capability.
```

### Review Findings and Resolution

- Current Auth UI and repository contracts prove this is not a visual-only change.
- Existing Account Setup architecture already has the correct skip pattern for trusted Phone identity, so complementary Email should extend that planner rather than creating a second onboarding subsystem.
- Round actions have real cross-context reuse evidence in both Signup and Login, so shared core ownership is justified.

## 7. Final Handoff

### Changed Files

Planning-only task brief.

### Actual Behavior

No runtime behavior changed by this task brief.

### Known Limitations

- Phone OTP auth capability is not yet present in the current repository contract.
- #34 identifier uniqueness foundation must be complete before production acceptance.
- Existing Truecaller action remains outside this slice's implementation ownership.

### Final Status

`BLOCKED`
