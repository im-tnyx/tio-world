# Account Setup Complementary Email

**Status:** In progress
**Primary owner:** `apps/features/account_setup` with app composition through `apps/app`
**Affected platforms:** Flutter mobile

## Global UI / Design-System Guardrail

This slice follows `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md`. It preserves the existing Account Setup visual language and uses existing core tokens/components. No unrelated redesign is authorized.

## 1. Discovery

### User Outcome

Complete the Account Setup part of #118 so the flow asks only for the contact method that is complementary to the trusted authenticated identity.

```text
trusted Email / Google identity
→ Username
→ Mobile optional

trusted Phone identity
→ Username
→ Email optional
```

### Success Criteria

- trusted Email + no trusted Phone plans optional Mobile;
- trusted Phone + no trusted Email plans optional Email;
- both trusted identities require no complementary contact step;
- optional Email can be left blank and Account Setup completes;
- entered Email delegates to Auth-owned Supabase Email add/change + confirmation request semantics;
- no Flutter code writes Email verification timestamps;
- canonical authenticated UUID is unchanged;
- no Supabase schema, migration, hook, Edge Function, or production data mutation.

### Scope

- Account Setup step model/planner;
- Account Setup Email step presentation and focused validation;
- app route composition from trusted Auth session evidence;
- focused planner/presentation/router source tests where present;
- Issue #130 under parent #118.

### Non-Goals

- Phone OTP capability or Phone-first Login/Signup UI;
- password creation/reset/change;
- Google linking/unlinking;
- Account Settings contact redesign;
- Product Onboarding changes;
- Supabase schema/runtime production changes.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `AGENTS.md`, `.ai/workflow.md`, `.ai/tasks/TEMPLATE.md`, `.ai/tasks/design-system-token-consolidation.md`, `docs/MODULE_OWNERSHIP.md`, `docs/SUPABASE_STRATEGY.md`, `apps/features/AGENTS.md`, `apps/core/lib/src/theme/README.md`.
- Account Setup currently plans only `username` + optional `mobile` through `BuildAccountSetupFlowUseCase` and accepts only `hasTrustedPhoneIdentity`.
- `AccountSetupFlowPage` currently has no Email step and completes directly after Username for trusted-Phone accounts.
- `AuthSession` already exposes provider-derived `isEmailVerified` and `isPhoneVerified`; `SupabaseAuthSessionRepository` maps them from `emailConfirmedAt` / `phoneConfirmedAt`.
- `accountContactVerificationRepositoryProvider` already composes `SupabaseAccountContactVerificationRepository` at app level.
- `AccountContactVerificationRepository.requestEmailVerification()` already owns trusted Supabase Auth Email add/change + confirmation-request semantics and never writes verification timestamps.
- Existing pattern to follow: keep cross-feature Auth dependency in app composition and inject a narrow callback into Account Setup instead of importing the Auth feature into `tio_feature_account_setup`.
- Tests already present: planner tests and `account_setup_flow_page_test.dart`; Flutter/Dart executable validation is currently unavailable in this environment.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Trusted Email / Phone source | Made | Use `AuthSession.isEmailVerified` / `isPhoneVerified`, not non-empty strings | Auth boundary |
| Cross-feature dependency | Made | Inject optional Email request callback from app composition; do not add `tio_feature_auth` dependency to Account Setup | App composition |
| Pending optional Email | Made | Request trusted Auth add/change confirmation, then Account Setup may complete; verification remains pending until Auth confirms it | Auth + Account Setup |
| No trusted identity fallback | Made | Preserve existing optional Mobile fallback for compatibility; authenticated production flows should normally have trusted Email or Phone | Account Setup |

## 4. Architecture Design

### Chosen Approach

Extend the Account Setup planner with trusted Email + trusted Phone awareness and add a feature-owned optional Email step. The feature receives only a narrow `requestOptionalEmailVerification(email)` callback and initial Auth Email from app composition.

### Ownership and Data Flow

```text
Supabase Auth session
→ AuthSession verification flags
→ app router composition
→ AccountSetupFlowPage planner
→ optional Email step
→ injected request callback
→ AccountContactVerificationRepository
→ Supabase Auth updateUser/resend
→ confirmation remains Auth-owned
```

Account Setup completion remains owned by `AccountSetupRepository` / `public.users.account_setup_completed_at`; Email ownership proof remains Supabase Auth-owned.

### Alternative Rejected

- Importing the Auth feature directly into Account Setup, because app composition can bridge the two bounded features.
- Writing Email directly to `public.users`, because that bypasses trusted Auth add/change confirmation semantics.
- Treating a non-empty session Email/Phone as verified, because the domain model already exposes authoritative confirmation flags.
- Adding an OTP/code verification screen to this slice, because optional Email may remain pending and confirmation is already owned by Auth.

### Failure and Accessibility States

- blank Email is valid and skips the optional contact;
- malformed Email disables Continue;
- Auth request failures remain on the Email step and show the existing flow error pattern;
- Email field uses email keyboard/autofill and clear helper copy that verification is required before it becomes trusted;
- existing Back/progress/footer behavior remains unchanged.

## 5. Implementation Plan

- [ ] add `email` Account Setup step ID and planner matrix;
- [ ] add optional Email step UI using existing Tio design-system primitives;
- [ ] extend `AccountSetupFlowPage` with trusted Email planning, initial Email, and injected Auth request callback;
- [ ] use authoritative `AuthSession` verification flags in app route composition;
- [ ] add focused planner and presentation tests;
- [ ] audit branch diff against #129 head for unrelated files;
- [ ] keep PR Draft and unmerged.

## 6. Quality Review

### Validation Run

```text
Planned:
- source-level review
- branch compare / changed-file audit
- Flutter focused tests if a toolchain becomes available
```

### Review Findings and Resolution

Pending implementation.

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

Executable Flutter/Dart validation is unavailable in the current environment unless toolchain availability changes.

### Final Status

`PARTIAL`
