# Auth Phone OTP Capability

**Status:** In progress
**Primary owner:** `apps/features/auth`
**Affected platforms:** Flutter Auth + hosted Supabase Auth
**Related issue:** #126
**Consumer:** #118
**Deferred independent Auth smoke:** #125
**Working branch:** `agent/auth-phone-otp-capability-clean`
**Draft PR:** #127
**Immediate parent:** `agent/auth-email-canonical-signup` @ `fb648f5cf739eae431958483dc6820e24d9d1dac`

## 1. Discovery

### User Outcome

Provide the real passwordless Phone OTP capability required by #118 without fake/local OTP success, without changing the canonical account UUID, and without bundling Phone-first UI.

### Success Criteria

- canonical E.164 before every Phone Auth call;
- Signup and Login have explicit create-user intent;
- request/resend use real Supabase `signInWithOtp`;
- verify uses `OtpType.sms` and requires a real returned authenticated session;
- authenticated success requires the exact confirmed target Phone;
- request/resend/verify have bounded timeout and controlled typed failures;
- no client-written verification timestamp, new schema, or UI change;
- focused test source covers intent, normalization, timeout, session absence, mismatch, and backend failures.

### Scope

Phone OTP domain result/intent models, repository contract, request/resend/verify use cases, Supabase repository, package exports, and focused tests.

### Non-Goals

#118 UI/OTP screen/countdown, WhatsApp OTP, password recovery/change, Google linking, SMS-vendor selection, schema changes, #125 smoke, PR Ready/merge.

## 2. Codebase Exploration

### Verified Evidence

- `AuthSignInRepository.signInWithOtp(email, token)` is Email magic-link verification only; there was no signed-out Phone OTP request/resend/verify capability.
- Authenticated Phone contact change already uses `auth.updateUser(phone)` + `verifyOTP(type: phoneChange)` and is a different trust state.
- `AuthSession` already owns `phone` and `isPhoneVerified` from Supabase `User.phone` / `phoneConfirmedAt`.
- `normalizePhoneNumberE164()` is already public through `tio_shared`; it accepts the current India national form and explicit international `+E.164`.
- Live DB audit during this slice: `auth.users=0`, `public.users=0`; `public.users.mobile` and `mobile_verified_at` are nullable.
- Live `auth.users` trigger order is root provisioning first, contact reconciliation second, so Phone-only Auth root creation is compatible with the existing verified projection.
- Verified-only Mobile uniqueness is already live; no new DB migration is needed.
- Repo `supabase/config.toml` has no SMS-provider block, so source cannot prove hosted SMS delivery readiness.
- Current Supabase Flutter contract supports `signInWithOtp(phone:, shouldCreateUser:)`, `verifyOTP(phone:, token:, type: OtpType.sms)`, and passwordless resend by repeating `signInWithOtp()`.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Supabase Auth owns Phone verification/session | Frozen | #34/#118 authority boundary |
| Reuse existing E.164 helper | Chosen | Avoid normalization drift |
| Dedicated `PhoneOtpAuthRepository` | Chosen | Existing OTP method is Email-only semantics |
| Signup uses `shouldCreateUser=true` | Chosen | Explicit account-creation intent |
| Login uses `shouldCreateUser=false` | Chosen | Login must not create unknown users |
| Resend repeats `signInWithOtp` | Chosen | Supabase passwordless contract |
| Verify requires response session + exact confirmed Phone | Chosen | Prevent user-only/stale-session false success |
| No SMS vendor/config mutation | Chosen | Operational scope is separate |
| No DB migration | Chosen | Existing root/reconciliation/uniqueness is sufficient |

## 4. Architecture Design

```text
#118 future UI
→ RequestPhoneOtpUseCase / ResendPhoneOtpUseCase
→ normalizePhoneNumberE164()
→ PhoneOtpAuthRepository
→ Supabase signInWithOtp(phone, shouldCreateUser)

OTP entry
→ VerifyPhoneOtpUseCase
→ canonical Phone + trimmed token
→ verifyOTP(type: sms)
→ require response.session
→ require session.user.phone == target
→ require phoneConfirmedAt
→ SignInSuccess(AuthSession)
→ non-blocking device sync
```

`PhoneOtpCodeSent` is deliberately separate from `SignInSuccess`, so accepted SMS delivery can never be interpreted as authentication.

## 5. Implementation Plan

- [x] Audit current Auth/Phone/contact verification/runtime ownership.
- [x] Freeze dedicated Phone OTP boundary.
- [x] Add `PhoneOtpIntent` and request result types.
- [x] Add `PhoneOtpAuthRepository`.
- [x] Add request/resend/verify use cases with E.164 normalization and timeouts.
- [x] Add `SupabasePhoneOtpAuthRepository` using `signInWithOtp` and `OtpType.sms`.
- [x] Require real response session + exact confirmed target Phone.
- [x] Start device sync only after authenticated success.
- [x] Export public capability.
- [x] Add focused test source.
- [x] Create clean stacked Draft PR #127.
- [ ] Run Flutter/Dart executable validation in a capable environment.
- [ ] Run real hosted SMS/session smoke when controlled Phone + provider readiness exist.

## 6. Quality Review

### Validation Run

```text
Live read-only DB audit              PASS
Parent branch                        agent/auth-email-canonical-signup
Parent SHA                           fb648f5cf739eae431958483dc6820e24d9d1dac
Clean PR branch                      agent/auth-phone-otp-capability-clean
Initial PR compare                   ahead 2 / behind 0
Initial changed-file audit           12 files, Auth task/domain/data/tests only
Core/Onboarding/Account Setup UI     none
Supabase migration/config changes    none
Production mutation                  none
Flutter/Dart executable tests        NOT RUN
Hosted SMS/session smoke             NOT RUN
```

### Review Findings

- Signed-out Phone OTP and authenticated `phoneChange` stay separate.
- Login cannot create a new account because intent maps to `shouldCreateUser=false`.
- Verify never falls back to a pre-existing current session; it requires the `verifyOTP` response session.
- Real SMS provider/rate-limit readiness remains an operational runtime gate, not a source assumption.

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

Source now provides a bounded Phone OTP capability for #118. Signup can create a Phone Auth user, Login cannot, resend repeats the passwordless request, and only a real Supabase SMS verification session for the exact confirmed E.164 Phone returns authenticated success.

### Known Limitations

Executable Flutter validation and real hosted SMS/session smoke are pending. #125 remains the separate deferred Email/Google runtime smoke.

### Final Status

`PARTIAL` — source implementation and bounded branch review are complete; executable and real hosted SMS validation remain pending.
