# Auth Phone OTP Capability

**Status:** In progress
**Primary owner:** `apps/features/auth`
**Affected platforms:** Flutter Auth + hosted Supabase Auth
**Related issue:** #126
**Parent tracker:** #34
**Consumer:** #118
**Deferred independent runtime acceptance:** #125
**Working branch:** `agent/auth-phone-otp-capability`
**Stack base:** PR #123 / `agent/auth-email-canonical-signup` @ `fb648f5cf739eae431958483dc6820e24d9d1dac`

## 1. Discovery

### User Outcome

Provide the real passwordless Phone OTP capability that #118 can consume without shipping fake/local OTP behavior, without changing the canonical account UUID, and without mixing Phone-first UI into this foundation slice.

### Success Criteria

- Phone input is canonical E.164 before any Supabase Auth call.
- Signup and Login express different account-creation intent.
- Request and resend use real Supabase passwordless Phone OTP.
- Verification uses `OtpType.sms` and succeeds only with a real authenticated Supabase session/user for the target phone.
- Request/resend/verify have bounded timeout and controlled typed failures.
- Existing `AuthSession.phone` / `isPhoneVerified` are populated from Supabase Auth.
- No client-written verification timestamp, new table/column, or Auth UI change.
- Focused source tests cover request, resend, verify, invalid input, timeout, intent, session absence, and identity mismatch.

### Scope

- dedicated Phone OTP domain models/repository/use cases;
- Supabase Phone OTP repository implementation;
- reuse existing `normalizePhoneNumberE164()`;
- request/resend/verify error mapping and timeout behavior;
- device sync only after authenticated verification success;
- package exports and focused tests.

### Non-Goals

- #118 Signup/Login presentation, mode switch, OTP screen, countdown, round provider actions, or Account Setup complementary Email;
- WhatsApp OTP;
- password reset/change-password;
- Google linking/unlinking;
- new Phone identity table/column;
- changing hosted SMS provider configuration;
- real SMS delivery smoke without a controlled phone number;
- deferred Email/Google smoke #125;
- Ready/merge of any PR.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected:
  - `apps/features/auth/lib/src/domain/repositories/auth_sign_in_repository.dart`
  - `apps/features/auth/lib/src/data/repositories/supabase_auth_sign_in_repository.dart`
  - `apps/features/auth/lib/src/domain/models/auth_session.dart`
  - `apps/features/auth/lib/src/data/repositories/supabase_account_contact_verification_repository.dart`
  - `apps/shared/lib/src/contact/phone_number.dart`
  - `supabase/config.toml`
  - live `auth.users` trigger metadata
  - #34, #118, #125, #126
  - `docs/SUPABASE_STRATEGY.md`, `docs/MODULE_OWNERSHIP.md`, `apps/features/AGENTS.md`
- Existing `AuthSignInRepository.signInWithOtp(email, token)` is Email magic-link verification only. There is no signed-out Phone OTP request/resend/verify contract.
- `SupabaseAccountContactVerificationRepository` already uses `auth.updateUser(phone)` + `verifyOTP(type: phoneChange)` for authenticated contact changes. That is a different trust state and must not be reused as signed-out Phone Login/Signup.
- `AuthSession` already carries `phone` and `isPhoneVerified`; the existing Supabase user mapper derives them from `User.phone` and `User.phoneConfirmedAt`.
- `normalizePhoneNumberE164()` is public through `package:tio_shared/shared.dart`; it accepts current India national input and explicit international `+E.164`, validates the 8–15 digit E.164 boundary, and fails invalid shapes.
- Hosted DB currently has zero Auth/public users. No real Phone OTP smoke identity exists.
- Live `auth.users` has two relevant AFTER triggers. Alphabetical trigger order is:
  1. `provision_tio_user_root_after_auth_insert`
  2. `reconcile_tio_user_contact_verification_after_auth_change`
  Therefore a new Auth row gets its `public.users` root before contact reconciliation projects the verified Phone.
- `public.users.mobile` and `mobile_verified_at` are nullable, and verified-only Mobile uniqueness is already live.
- Repo `supabase/config.toml` has Auth enabled but no SMS-provider block. Hosted SMS vendor/rate-limit readiness cannot be inferred from source config alone.
- Auth package currently depends on `supabase_flutter: ^2.8.0`.
- Current official Supabase Flutter contract supports `signInWithOtp(phone:, shouldCreateUser:)`, `verifyOTP(phone:, token:, type: OtpType.sms)`, and documents passwordless resend as calling `signInWithOtp()` again rather than `resend()`.

### Existing Pattern to Follow

- feature domain contract/use case/repository layering;
- Supabase SDK calls stay in data repositories;
- canonicalization/validation before SDK boundary;
- `SignInResult` means authenticated success only when a real Supabase session exists;
- secondary device sync is non-blocking and starts only after authenticated success.

### Tests or Validation Already Present

- Auth repository tests use lightweight `FakeSupabaseClient` / `FakeGoTrueClient` implementations.
- Shared phone normalization is already used by Account contact verification and Account Setup persistence paths.
- No executable Flutter/Dart validation is available in the current connector environment; source tests must not be described as run until a toolchain executes them.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Supabase Auth owns Phone OTP verification/session | Frozen | #118/#34 trust boundary | Auth |
| Reuse existing E.164 helper | Chosen | Avoid normalization drift | Auth/Shared |
| Dedicated Phone OTP repository instead of overloading Email `signInWithOtp` | Chosen | Current method is Email magic-link semantics and has no request/resend intent | Auth |
| Signup request may create user | Chosen | Explicit signup intent | Product/Auth |
| Login request must not create user | Chosen | Returning Login must not create unknown accounts | Product/Auth |
| Resend repeats `signInWithOtp` | Chosen | Current Supabase passwordless contract | Auth |
| Verification requires real session + matching confirmed Phone | Chosen | User object alone is insufficient authenticated success | Security/Auth |
| Do not configure/select SMS vendor in this slice | Chosen | Hosted provider configuration is operational and not visible/authorized from repo source | Platform |
| No new DB migration | Chosen | Existing root/reconciliation/verified uniqueness already support Phone Auth | Data |

## 4. Architecture Design

### Chosen Approach

```text
#118 future UI
→ RequestPhoneOtpUseCase / ResendPhoneOtpUseCase
   → canonical E.164
   → PhoneOtpAuthRepository
      → Supabase auth.signInWithOtp(phone, shouldCreateUser)

OTP entry
→ VerifyPhoneOtpUseCase
   → canonical E.164 + non-empty token
   → PhoneOtpAuthRepository.verifyCode
      → Supabase auth.verifyOTP(type: sms)
      → require real session
      → require returned/current user Phone == target and phoneConfirmedAt != null
      → AuthSession
      → non-blocking device sync
```

Intent:

```text
PhoneOtpIntent.signup → shouldCreateUser = true
PhoneOtpIntent.login  → shouldCreateUser = false
```

Typed request state stays separate from authenticated `SignInResult` so `code sent` can never be confused with `signed in`.

### Ownership and Data Flow

```text
apps/features/auth domain
→ Phone OTP contracts/use cases
→ apps/features/auth data
→ Supabase Auth client-safe SDK
→ auth.users
→ DB-owned public.users root + trusted verification projection
```

### Alternative Rejected

- Reusing Account contact-change verification: wrong trust state and `OtpType.phoneChange`.
- Adding Phone methods directly to the already broad Email/Google `AuthSignInRepository`: would expand every fake/adapter and preserve a misleading `signInWithOtp` name.
- Using `auth.resend()` for passwordless Phone Login: current Supabase docs specify repeating `signInWithOtp()`.
- Treating `verifyOTP` user-only response as success: #118 requires a real authenticated session.
- Adding a new table/identity key: verified Mobile ownership already exists.

### Failure and Accessibility States

This slice has no production UI. Domain/data must expose stable failures for invalid phone/token, request/resend/verify timeout, backend request failure, missing authenticated session, and verified-Phone mismatch so #118 can render controlled accessible states later.

## 5. Implementation Plan

- [x] Read required repository/auth/data ownership docs.
- [x] Audit current Email OTP, contact-change Phone OTP, AuthSession, phone normalization, Supabase config, and live trigger order.
- [x] Freeze dedicated Phone OTP capability boundary.
- [ ] Add Phone OTP intent/request result models.
- [ ] Add `PhoneOtpAuthRepository` contract.
- [ ] Add request/resend/verify use cases with E.164 normalization and timeouts.
- [ ] Add `SupabasePhoneOtpAuthRepository` using `signInWithOtp` / `verifyOTP(OtpType.sms)`.
- [ ] Require real authenticated session + confirmed target Phone on verify.
- [ ] Start device sync only after verified authenticated success.
- [ ] Export the new capability through public Auth package boundaries.
- [ ] Add focused repository/use-case tests.
- [ ] Run parent-to-head scope audit.
- [ ] Run Flutter/Dart tests when a capable environment is available.
- [ ] Record #126/#118 source checkpoint.

## 6. Quality Review

### Validation Run

```text
Fresh live read-only DB audit:
auth.users                                      0
public.users                                    0
public.users.mobile nullable                    true
public.users.mobile_verified_at nullable        true
auth.users trigger order:
  provision_tio_user_root_after_auth_insert
  reconcile_tio_user_contact_verification_after_auth_change

Source/runtime mutation during audit: none
Flutter/Dart executable validation: not run yet
Hosted SMS delivery/session smoke: not run; controlled phone/provider readiness unavailable
```

### Review Findings and Resolution

1. Existing `signInWithOtp` is Email magic-link verification and is not a Phone OTP foundation. Use a dedicated capability.
2. Signed-out Phone OTP and authenticated Phone change use different Supabase verification types (`sms` vs `phoneChange`). Keep them separate.
3. Phone-only Auth root provisioning is safe only if provisioning precedes contact reconciliation. Live trigger order confirms that ordering today.
4. Repo source cannot prove hosted SMS provider readiness. Treat real delivery as an operational smoke gate, not a source assumption.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/auth-phone-otp-capability.md`

### Actual Behavior

No runtime behavior changed yet. The bounded Phone OTP architecture and evidence are recorded before implementation.

### Known Limitations

- Hosted SMS provider/vendor/rate-limit configuration has not been independently read back.
- No controlled phone number is available for real SMS/session smoke.
- Flutter/Dart executable validation remains unavailable in the current tool environment.

### Final Status

`PARTIAL` — audit/architecture complete; source implementation pending.
