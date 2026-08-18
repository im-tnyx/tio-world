# Account Setup Boundary

**Status:** Implementation complete; automated and real-device QA passed; ready for review
**Primary owner:** App session/bootstrap + `tio_feature_account_setup`
**Affected platforms:** Flutter phone app, Supabase-backed account/profile persistence
**Tracking issue:** #18 — `refactor(account-setup): separate username/mobile bootstrap from product onboarding`
**Implementation branch:** `codex/account-setup-boundary` from `main@4209083`
**PR:** #20

## User Outcome

Fresh authenticated users now follow one explicit boundary sequence:

```text
Authentication
→ Account Setup
   → Username (required)
   → Mobile (optional / provider-aware)
→ Product Onboarding
→ App
```

Authentication establishes identity/session. Account Setup owns account bootstrap requirements. Product Onboarding owns fitness/product personalization.

## Implemented Architecture

### Account Setup package

```text
apps/features/account_setup/
  account_setup.dart
  src/
    domain/
      models/
        account_setup_step_id.dart
        account_setup_flow_plan.dart
      usecases/
        build_account_setup_flow_use_case.dart
    presentation/
      account_setup_flow_page.dart
      steps/
        username_step.dart
        mobile_step.dart
```

`AccountSetupFlowPage` owns:

- `Scaffold` / `SafeArea`;
- visible Back and system Back behavior;
- progress semantics;
- current-step selection;
- fixed Continue footer;
- loading/error/retry state;
- durable resume from account state.

Step widgets own content/state only.

### Planner

`BuildAccountSetupFlowUseCase` uses account/provider evidence to produce typed steps:

```text
username missing
→ Username

username complete + Account Setup incomplete + no trusted phone
→ Mobile

trusted phone identity / trusted backend mobile verification
→ Mobile skipped

Account Setup complete
→ Product Onboarding
```

Username remains required even if persisted completion state is inconsistent.

## Bootstrap / Routing

Username-specific bootstrap state was replaced with:

```text
AppSessionBootstrapRequiresAccountSetup
```

Routes:

```text
/account-setup     canonical Account Setup route
/username-setup    compatibility redirect → /account-setup
```

Session policy now enforces:

```text
signed out
→ Auth

authenticated + Account Setup incomplete
→ Account Setup

authenticated + Account Setup complete + onboarding incomplete
→ Product Onboarding

completed legacy account
→ App
```

Unauthenticated Product Onboarding deep links are redirected to Auth. Welcome `Get Started` routes through signup/authentication rather than directly into Product Onboarding.

## Username Contract

Username behavior was moved from Profile-owned `UsernameSetupPage` into Account Setup `UsernameStep` while preserving:

- lowercase normalization;
- availability RPC checks;
- server suggestions;
- uniqueness race handling;
- retryable save feedback.

The old Profile-owned Username setup page/layout tests were removed. Equivalent availability/race/layout tests now live under `tio_feature_account_setup`.

## Mobile Contract

Mobile is optional.

Rules:

- blank Mobile may complete Account Setup;
- entered Mobile is stored but never marked verified by typing alone;
- changing an entered Mobile clears `mobile_verified_at`;
- trusted provider/backend phone evidence may skip the Mobile step;
- Account Settings remains the later edit/verification surface.

## Durable Completion

Because blank Mobile is a valid completion state, field values alone cannot distinguish “pending” from “completed blank”. A narrow durable marker was added:

```text
public.users.account_setup_completed_at timestamptz nullable
```

Migration:

```text
20260817185654_add_account_setup_completion_marker
```

No legacy rows were backfilled. Historical completed accounts bypass Account Setup through the existing onboarding-completion contract.

Trusted `mobile_verified_at` also counts as effective completion evidence for the optional Mobile requirement.

## Account-Owned Persistence Protection

Product Onboarding no longer owns Username or Mobile persistence.

`ProfileSetupMapper` intentionally does not forward legacy onboarding Mobile fields into `ProfileSetupData`.

`SupabaseProfileSetupRepository.saveProfileSetup` now treats null account-owned values as “preserve existing durable value”:

```text
username == null → preserve existing account Username
mobile == null   → preserve existing account Mobile + verification evidence
```

This prevents Product Onboarding completion or Profile Settings reconstruction from wiping Account Setup state.

## Product Onboarding Migration

Active Product Onboarding plans no longer schedule Mobile.

Current product flows:

```text
Workout
Mode → Profile → Workout Preferences → Targets → Review

Nutrition
Mode → Profile → Targets → Review

Hybrid
Mode → Profile → Workout Intro → optional Workout Preferences → Targets → Review
```

Updated progress totals:

```text
Workout gym       25
Workout home      26
Nutrition         17
Hybrid setupNow   26 / 27
Hybrid later      18
```

Legacy Mobile draft identifiers may remain only as compatibility decoding/plumbing; they are not part of active flow planning or progress. Product Onboarding no longer receives provider-aware Mobile inclusion policy from app routing.

## Automated Coverage

Account Setup tests cover:

- fresh Username → Mobile planning;
- resume directly at Mobile after Username is persisted;
- trusted phone Mobile skip;
- completed boundary produces no setup steps;
- inconsistent completion state still requires missing Username;
- Username availability and server suggestions;
- Username save-race retry behavior;
- blank Mobile completion;
- entered Mobile remains unverified;
- shared footer/layout at phone size;
- visible Back behavior;
- system Back behavior;
- bootstrap Account Setup gating;
- legacy completed-account bypass;
- unauthenticated setup/onboarding redirect to Auth;
- Product Onboarding planner contains no active Mobile step;
- updated Product Onboarding progress totals;
- legacy onboarding Mobile is not forwarded into account-owned profile persistence.

Latest validation on the final implementation branch head is fully green in Flutter CI #394:

- Flutter analyze;
- Dart analyze;
- Flutter tests;
- Dart tests.

## Supabase Verification

Applied migration is present in live migration history.

Verified column contract:

```text
account_setup_completed_at
- type: timestamptz
- nullable: yes
- default: none
```

Existing Supabase advisor warnings are pre-existing username SECURITY DEFINER / Auth / RLS performance items; this migration introduced no new Account Setup-specific warning.

## Manual QA Completed

Real-device Account Setup acceptance QA was completed and approved by the owner on Android. The reviewed acceptance contract includes:

1. Fresh Email signup:
   `Auth → Username → Mobile → Product Onboarding`.
2. Fresh Google signup:
   same boundary order.
3. Blank Mobile may Continue into Product Onboarding.
4. Entered Mobile remains unverified without trusted provider/backend evidence.
5. Relaunch after Username resumes at Mobile.
6. Back from Mobile returns to Username; Back from the first Account Setup step exits/signs out deterministically.
7. Product Onboarding completion preserves Account Setup Username/Mobile in `public.users`.
8. Returning completed legacy account goes directly to the app.
9. Existing completed account is not retroactively gated by a null `account_setup_completed_at` marker.
10. Product Onboarding progress/UI contains no Mobile screen.
11. Login and signup flows were exercised successfully on a real mobile device.

No blocking issue was reported during the final real-device review.

## Merge Gate

Satisfied before marking PR #20 ready for review:

- latest implementation CI fully green;
- real-device Login/Signup and Account Setup flow reviewed;
- Account Setup navigation/resume acceptance contract approved;
- durable Username/Mobile preservation covered and accepted;
- Product Onboarding no longer owns provider-aware Mobile policy.

PR #20 is ready for review/merge approval. Do not merge without explicit approval.
