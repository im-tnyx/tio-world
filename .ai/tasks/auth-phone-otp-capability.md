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

- Auth repository tests use lightweight fake Supabase clients and injectable SDK boundaries.
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

This slice has no production UI. Domain/data exposes stable failures for invalid phone/token, request/resend/verify timeout, backend request failure, missing authenticated session, and verified-Phone mismatch so #118 can render controlled accessible states later.

## 5. Implementation Plan

- [x] Read required repository/auth/data ownership docs.
- [x] Audit current Email OTP, contact-change Phone OTP, AuthSession, phone normalization, Supabase config, and live trigger order.
- [x] Freeze dedicated Phone OTP capability boundary.
- [x] Add Phone OTP intent/request result models.
- [x] Add `PhoneOtpAuthRepository` contract.
- [x] Add request/resend/verify use cases with E.164 normalization and timeouts.
- [x] Add `SupabasePhoneOtpAuthRepository` using `signInWithOtp` / `verifyOTP(OtpType.sms)`.
- [x] Require real authenticated session + confirmed target Phone on verify.
- [x] Start device sync only after verified authenticated success.
- [x] Export the new capability through public Auth package boundaries.
- [x] Add focused repository/use-case test source.
- [x] Run final parent-to-head GitHub scope audit.
- [ ] Run Flutter/Dart tests when a capable environment is available.
- [x] Record #126/#118 source checkpoint.

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

Source review:
Phone OTP domain/request/result/repository/use-case boundaries added.
Supabase request/resend path uses signInWithOtp + explicit shouldCreateUser intent.
Supabase verify path uses OtpType.sms and requires response.session.
Verified success requires exact target Phone + phoneConfirmedAt.
Device sync remains non-blocking and starts only after authenticated success.
No UI, migration, table, column, hook, Edge Function, or hosted Auth config change.

Final parent-to-head audit:
base                                      agent/auth-email-canonical-signup
base SHA                                  fb648f5cf739eae431958483dc6820e24d9d1dac
branch                                    agent/auth-phone-otp-capability
behind                                    0
changed scope                              Auth task/domain/data/tests only
unrelated Core/Onboarding/UI files         none
Supabase migration/config changes          none

Flutter/Dart executable validation: NOT RUN in current environment
Hosted SMS delivery/session smoke: NOT RUN; controlled phone/provider readiness unavailable
```

### Review Findings and Resolution

1. Existing `signInWithOtp` is Email magic-link verification and is not a Phone OTP foundation. A dedicated capability was added.
2. Signed-out Phone OTP and authenticated Phone change use different Supabase verification types (`sms` vs `phoneChange`). They remain separate.
3. Phone-only Auth root provisioning is safe only if provisioning precedes contact reconciliation. Live trigger order confirms that ordering today.
4. Repo source cannot prove hosted SMS provider readiness. Real delivery remains an operational smoke gate, not a source assumption.
5. Request-code success is represented by `PhoneOtpCodeSent`, not `SignInSuccess`; only OTP verification can establish authenticated success.
6. Verify does not fall back to a pre-existing `currentSession`; it requires the `verifyOTP` response session and exact confirmed target Phone, avoiding stale-session false success.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/auth-phone-otp-capability.md`
- `apps/features/auth/lib/src/domain/models/phone_otp_intent.dart`
- `apps/features/auth/lib/src/domain/models/phone_otp_request_result.dart`
- `apps/features/auth/lib/src/domain/repositories/phone_otp_auth_repository.dart`
- `apps/features/auth/lib/src/domain/usecases/request_phone_otp_use_case.dart`
- `apps/features/auth/lib/src/domain/usecases/resend_phone_otp_use_case.dart`
- `apps/features/auth/lib/src/domain/usecases/verify_phone_otp_use_case.dart`
- `apps/features/auth/lib/src/data/repositories/supabase_phone_otp_auth_repository.dart`
- `apps/features/auth/lib/src/domain/domain.dart`
- `apps/features/auth/lib/src/data/data.dart`
- `apps/features/auth/test/domain/phone_otp_use_case_test.dart`
- `apps/features/auth/test/data/supabase_phone_otp_auth_repository_test.dart`

### Actual Behavior

Repository source now provides a bounded Phone OTP capability that #118 can compose later. Signup requests allow Supabase user creation, Login requests prohibit it, resend repeats the passwordless request, and verification can return authenticated success only from a real Supabase SMS OTP session whose confirmed Phone matches the requested canonical E.164 value.

### Known Limitations

- Hosted SMS provider/vendor/rate-limit configuration has not been independently read back.
- No controlled phone number is available for real SMS/session smoke.
- Flutter/Dart tests are added as source but have not executed in the current environment.
- #125 Email/Google real hosted smoke remains deferred and independent.

### Final Status

`PARTIAL` — bounded Phone OTP source implementation and source/static review are complete; executable Flutter validation and hosted SMS/session smoke remain pending.
