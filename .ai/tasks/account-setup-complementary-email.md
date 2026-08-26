# Account Setup Complementary Email

**Status:** Source complete, executable validation pending
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
- app composition from trusted Auth session evidence;
- Account Setup completion-marker semantics needed to distinguish completed setup from merely verified Mobile;
- focused planner/presentation/bridge tests;
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

- Source/config inspected: `AGENTS.md`, `.ai/workflow.md`, `.ai/tasks/TEMPLATE.md`, `.ai/tasks/design-system-token-consolidation.md`, `docs/MODULE_OWNERSHIP.md`, `docs/SUPABASE_STRATEGY.md`, `apps/features/AGENTS.md`, `apps/core/lib/src/theme/README.md`, `docs/PUSH_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE.md`.
- Account Setup originally planned only `username` + optional `mobile` through `BuildAccountSetupFlowUseCase` and accepted only `hasTrustedPhoneIdentity`.
- `AuthSession` already exposes provider-derived `isEmailVerified` and `isPhoneVerified`; `SupabaseAuthSessionRepository` maps them from Auth confirmation state.
- `SupabaseAccountContactVerificationRepository.requestEmailVerification()` already owns Supabase Auth Email add/change + confirmation-request semantics and never writes verification timestamps.
- `accountSetupRepositoryProvider` is an app-composition seam already consumed by Account Setup routing and session bootstrap.
- `SupabaseAccountSetupRepository.readAccountSetupState()` previously treated a verified Mobile as equivalent to completed Account Setup. That would incorrectly skip optional Email for a fresh Phone-authenticated account, so completion now means the durable `account_setup_completed_at` marker only.
- Existing legacy planner/widget callers predate the Email step. Production app composition therefore supplies explicit Email trust while omitted Email evidence keeps the historical trusted-Phone planning contract for old tests/non-composed callers.
- Flutter/Dart executable validation is unavailable in the current environment.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Trusted Email / Phone source | Made | Use `AuthSession.isEmailVerified` / `isPhoneVerified`; Supabase Auth confirmation is only a fallback while session state resolves | Auth boundary |
| Cross-feature dependency | Made | App composition implements a narrow `AccountSetupAuthContactBridge`; `tio_feature_account_setup` does not import `tio_feature_auth` | App composition |
| Router churn | Made | Keep the central router unchanged; the existing `accountSetupRepositoryProvider` returns a composite object that also exposes the narrow Auth bridge | App shell |
| Pending optional Email | Made | Request Auth add/change confirmation first, then Account Setup may complete; verification remains pending until Auth confirms it | Auth + Account Setup |
| Completion meaning | Made | `account_setup_completed_at` is the durable Account Setup acknowledgement; verified Mobile alone is contact evidence, not setup completion | Profile persistence |
| Legacy planner callers | Made | Omitted Email trust preserves old behavior; production bridge passes explicit Email trust so Phone-only accounts receive the new Email step | Account Setup |
| No trusted identity fallback | Made | Preserve optional Mobile fallback if explicit trusted evidence says neither contact is trusted | Account Setup |

## 4. Architecture Design

### Chosen Approach

Extend the Account Setup planner with explicit trusted Email + trusted Phone awareness and add a feature-owned optional Email step. App composition wraps the existing persistence repository and Auth contact-verification repository in one object implementing both `AccountSetupRepository` and the narrow `AccountSetupAuthContactBridge` capability.

This keeps the feature free of Auth SDK/provider dependencies and avoids widening the already-large central router for a bounded Account Setup concern.

### Ownership and Data Flow

```text
Supabase/Auth session
→ AuthSession verified-contact flags
→ apps/app accountSetupRepositoryProvider
→ _AppAccountSetupRepository
   ├─ AccountSetupRepository → profile persistence
   └─ AccountSetupAuthContactBridge → Auth contact verification
→ AccountSetupFlowPage planner
→ optional Email step
→ requestOptionalEmailVerification(email)
→ SupabaseAccountContactVerificationRepository
→ Supabase Auth updateUser/resend
→ Email remains pending until Auth confirmation
```

Account Setup completion remains owned by `AccountSetupRepository` / `public.users.account_setup_completed_at`. Email ownership proof remains Supabase Auth-owned. The canonical Auth UUID is never replaced.

### Alternative Rejected

- Importing the Auth feature directly into Account Setup, because app composition can bridge the bounded features without reversing package ownership.
- Adding more constructor wiring in the central router, because the existing Account Setup provider is already the correct composition seam and a bridge keeps router churn at zero.
- Writing Email directly to `public.users`, because that bypasses trusted Auth add/change confirmation semantics.
- Treating a non-empty Email/Phone string as verified, because verified-contact flags already exist.
- Treating `mobile_verified_at` as Account Setup completion, because Phone-authenticated users still need the new optional Email acknowledgement step.
- Adding an OTP/code verification screen here, because optional Email may remain pending and confirmation is Auth-owned.

### Failure and Accessibility States

- blank Email is valid and skips the optional contact;
- malformed Email disables Continue;
- Auth request happens before completion, so request failure leaves the user on the Email step and does not falsely complete Account Setup;
- Email field uses the existing `TioInput`, Email keyboard, design-system typography/spacing, and explicit pending-verification helper copy;
- helper copy states that adding Email here does not create Email + Password capability;
- existing Back/progress/footer behavior remains unchanged;
- Mobile-only explanatory info action remains Mobile-specific.

## 5. Implementation Plan

- [x] add `email` Account Setup step ID and complementary-contact planner matrix;
- [x] add optional Email step UI using existing Tio design-system primitives;
- [x] extend `AccountSetupFlowPage` with Email state, validation, skip, and Auth request-before-completion behavior;
- [x] add `AccountSetupAuthContactBridge` and compose it at app level from verified Auth evidence + existing Auth contact-verification repository;
- [x] keep the central router unchanged while preserving thin app-shell composition;
- [x] make `account_setup_completed_at` the explicit durable completion signal instead of inferring completion from verified Mobile;
- [x] add focused planner, Email presentation, and app-bridge source tests;
- [x] audit branch diff against #129 head for unrelated files;
- [x] keep PR Draft and unmerged;
- [ ] run focused Flutter/Dart tests when a toolchain is available.

## 6. Quality Review

### Validation Run

```text
Source / branch validation:
- parent: f2fc821c4e9b781662a65b26502c57aa4fc1ef1a (#129 head)
- branch compare: ahead only, behind 0
- merge base: exact #129 head
- changed-file audit: Account Setup task/app composition/Account Setup feature/narrow profile persistence only
- Supabase directory changes: none
- production Supabase mutations: none
- Flutter executable: unavailable (`flutter` not installed)
- Dart executable: unavailable (`dart` not installed)
```

### Review Findings and Resolution

1. **Fresh Phone-authenticated accounts would have skipped Email because verified Mobile was treated as completed setup.** Resolved by making the explicit completion marker authoritative.
2. **Directly editing the central router would add unnecessary churn.** Resolved by using the existing app-level Account Setup provider as a composite bridge seam.
3. **Legacy planner/tests only know about trusted Phone.** Resolved with nullable Email evidence for legacy callers; production bridge always supplies explicit trusted Email/Phone values.
4. **Email request failure must not leave a false completion marker.** Resolved by calling the Auth request before `completeAccountSetup()`.
5. **Optional Email must not imply password capability.** Resolved in helper copy and by delegating only to the existing Email verification request boundary.

No production schema/config/data mutation was performed.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/account-setup-complementary-email.md`
- `apps/app/lib/app/account_setup/account_setup_providers.dart`
- `apps/features/account_setup/lib/src/domain/domain.dart`
- `apps/features/account_setup/lib/src/domain/models/account_setup_step_id.dart`
- `apps/features/account_setup/lib/src/domain/repositories/account_setup_auth_contact_bridge.dart`
- `apps/features/account_setup/lib/src/domain/usecases/build_account_setup_flow_use_case.dart`
- `apps/features/account_setup/lib/src/presentation/account_setup_flow_page.dart`
- `apps/features/account_setup/lib/src/presentation/steps/email_step.dart`
- `apps/features/account_setup/test/domain/complementary_contact_flow_test.dart`
- `apps/features/account_setup/test/presentation/account_setup_auth_contact_bridge_test.dart`
- `apps/features/account_setup/test/presentation/account_setup_complementary_email_test.dart`
- `apps/features/profile/lib/src/data/repositories/supabase_account_setup_repository.dart`

### Actual Behavior

```text
verified Email only
→ Username if needed
→ optional Mobile
→ complete Account Setup

verified Phone only
→ Username if needed
→ optional Email
   ├─ blank → complete Account Setup
   └─ entered → Auth Email confirmation request → complete Account Setup while pending

verified Email + verified Phone
→ Username if needed
→ no complementary contact collection
→ durable completion marker
```

### Known Limitations

- Focused Flutter widget/unit tests are source-authored but could not be executed because the current environment has neither Flutter nor Dart installed.
- This slice does not verify the optional Email inside Account Setup; confirmation remains a later Auth-owned action.
- Existing Auth contact-verification normalization behavior is intentionally unchanged; broader canonical contact-change hardening remains outside #130.

### Final Status

`PARTIAL` — source implementation and clean stacked-branch audit are complete. Executable Flutter/Dart validation remains pending, so the PR must stay Draft/unmerged.
