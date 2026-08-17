# Account Setup Boundary

**Status:** Ready after PR #4 merge
**Primary owner:** App session/bootstrap + Account Setup flow
**Affected platforms:** Flutter phone app, Supabase-backed account/profile persistence
**Tracking issue:** #18 — `refactor(account-setup): separate username/mobile bootstrap from product onboarding`
**Implementation branch:** `codex/account-setup-boundary` from updated `main` after PR #4 merges

## 1. Discovery

### User Outcome

Fresh authenticated users complete account-level setup before entering product onboarding:

```text
Auth
→ Account Setup
   → Username (required)
   → Mobile (optional / provider-aware)
→ Product Onboarding
→ App
```

Authentication remains focused on establishing identity/session. Account Setup owns account bootstrap requirements. Product Onboarding owns fitness/product personalization.

### Current State

Current code is split across two conceptual owners:

```text
Auth success
→ AppSessionBootstrapRequiresUsername
→ standalone UsernameSetupPage
   → owns its own back/footer/Continue
→ AppSessionBootstrapRequiresOnboarding
→ OnboardingFlowPage
   → Mobile is still an onboarding step
   → Mobile uses onboarding parent navigation/footer
```

Verified current behavior:

- Username is outside `OnboardingFlowPage` and enforced by bootstrap routing.
- `AppSessionBootstrapRequiresUsername` is a dedicated bootstrap state.
- `UsernameSetupPage` is currently implemented in the Profile feature and owns its own `Scaffold`, back action, content shell, and fixed Continue footer.
- Mobile is still registered through `BuildOnboardingFlowUseCase` as `OnboardingStepId.mobile` / `OnboardingSectionId.mobile`.
- `MobileScreen` is content rendered inside the onboarding parent shell and does not own the onboarding CTA.
- Mobile inclusion is currently controlled by `includeMobile`, including provider-aware phone skip behavior.

### Problem

Username and Mobile are both account/bootstrap concerns, but currently live under different flow owners:

```text
Username → standalone pre-onboarding checkpoint
Mobile   → product onboarding step
```

This creates inconsistent:

- routing ownership;
- chrome/footer ownership;
- resume semantics;
- provider-aware step policy;
- progress semantics;
- future extensibility for account requirements.

## 2. Product Boundary

### Authentication

Authentication answers:

```text
Who is this user, and is there a valid authenticated session?
```

Auth owns:

- Welcome/auth entry;
- Login;
- Signup;
- Email authentication;
- Google authentication;
- future Phone OTP authentication;
- future Truecaller authentication;
- password reset/recovery;
- authenticated session/sign-out.

Auth does **not** own Username or optional profile Mobile collection merely because those occur after signup.

### Account Setup

Account Setup answers:

```text
Is this authenticated Tio account complete enough to enter product onboarding?
```

Account Setup owns:

- Username requirement;
- username availability/save/race behavior;
- optional Mobile collection;
- provider-aware Mobile skip policy;
- account-setup progress/navigation;
- shared account-setup chrome/footer;
- durable resume of incomplete account setup.

### Product Onboarding

Product Onboarding answers:

```text
How should Tio personalize the product experience for this user?
```

Product Onboarding owns:

- App Mode;
- Name;
- Gender;
- Goal;
- DOB/Age;
- Measurement Units;
- Height;
- Current/Target Weight;
- Activity;
- Health Conditions;
- Workout/Nutrition setup;
- Targets;
- Review/completion.

## 3. Target Architecture

Conceptual package:

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

Exact package/file names can follow existing workspace conventions during implementation.

### Flow ownership

```text
                    App session/bootstrap
                           |
                           v
              RequiresAccountSetup
                           |
                           v
                 AccountSetupFlowPage
                 /                  \
                v                    v
          UsernameStep          MobileStep
                \                    /
                 \                  /
                  shared navigation
                         |
                         v
               RequiresOnboarding
                         |
                         v
                 OnboardingFlowPage
```

## 4. Parent Shell Contract

`AccountSetupFlowPage` should own:

- `Scaffold` / `SafeArea`;
- back behavior;
- optional progress semantics;
- current step selection;
- Continue / Next behavior;
- fixed bottom CTA;
- navigation-level loading/error handling;
- flow reconciliation when provider/account state changes.

Step widgets should own content/state presentation only.

### Username step

```text
UsernameStep
→ title
→ description
→ username input
→ availability state
→ save/error feedback
```

It should not own route navigation or a separate bottom CTA.

### Mobile step

```text
MobileStep
→ title
→ description
→ optional mobile input
→ provider verification display when real evidence exists
→ privacy/help content
```

It should not own route navigation or a separate bottom CTA.

## 5. Bootstrap Contract

### Current

```text
AppSessionBootstrapRequiresUsername
```

### Target

Prefer one account-level state:

```text
AppSessionBootstrapRequiresAccountSetup
```

Then Account Setup determines the next required step from durable account/provider state.

Do not grow bootstrap into:

```text
RequiresUsername
RequiresMobile
RequiresTerms
RequiresRecoveryEmail
...
```

Bootstrap should know the account requires setup, not every individual setup step.

## 6. Account Setup Flow Planning

Introduce a planner/use case conceptually:

```text
BuildAccountSetupFlowUseCase
```

Inputs may include:

- authenticated provider/session identity;
- current username state;
- current mobile state;
- trusted provider/backend mobile verification evidence;
- durable account-setup resume state if needed.

Initial step model:

```text
AccountSetupStepId.username
AccountSetupStepId.mobile
```

### Email / Google

```text
Authenticated
→ Username if missing
→ Mobile optional if applicable
→ Product Onboarding
```

### Future Phone auth

```text
Phone-authenticated
→ Username if missing
→ Mobile skipped
→ Product Onboarding
```

### Future Truecaller

```text
Truecaller-authenticated
→ Username if missing
→ Mobile skipped only if trusted provider/backend phone evidence exists
→ Product Onboarding
```

Typed/entered mobile must never imply verification.

## 7. Persistence

Reuse the existing account/profile persistence boundary where appropriate:

```text
Account Setup
→ ProfileAccountRepository / account persistence adapter
→ Supabase public.users
```

Rules:

- Username remains required before product onboarding.
- Mobile remains optional for the current release.
- Blank mobile remains canonical blank/null behavior.
- A typed mobile number is not verified.
- `mobile_verified_at` remains null without real provider/backend proof.
- Do not create fake DOB/gender/height/weight values for pre-onboarding rows.
- Supabase dependencies remain in data adapters, not pure flow/domain code.

## 8. Onboarding Migration

Remove account-level Mobile ownership from product onboarding:

- remove `OnboardingStepId.mobile` from product onboarding flow planning;
- remove `OnboardingSectionId.mobile` if no longer used;
- remove Mobile from onboarding progress counts/titles;
- remove onboarding `includeMobile` policy once Account Setup owns the decision;
- update onboarding draft mapping only where Mobile state has moved to durable account setup/account persistence;
- ensure product onboarding starts with product-personalization steps only.

Do not move Username into product onboarding.

## 9. Returning / Legacy Accounts

Preserve existing completion contract:

```text
Returning completed account
→ bypass Account Setup
→ App
```

Do not retroactively force historical completed accounts through Username/Mobile because the account predates the new boundary.

Fresh/incomplete authenticated accounts should resume deterministically:

```text
username missing
→ Username

username complete + Mobile applicable/pending
→ Mobile

account setup complete
→ Product Onboarding
```

The exact durable completion marker versus field-derived resolution should be audited before implementation. Avoid introducing unnecessary duplicate state when account fields are already authoritative.

## 10. Migration Strategy

### Phase A — Domain foundation

- Introduce Account Setup step identifiers/flow plan.
- Introduce provider-aware planner.
- Add planner/reconciliation tests.
- Keep flow logic independent of Flutter widgets and Supabase.

### Phase B — Shared presentation shell

- Create `AccountSetupFlowPage`.
- Move Username presentation into `UsernameStep` semantics.
- Move Mobile presentation into `MobileStep` semantics.
- Parent owns Back and fixed Continue/Next.
- Preserve current Username availability/save feedback.

### Phase C — Bootstrap/routing

- Introduce `AppSessionBootstrapRequiresAccountSetup`.
- Replace Username-specific redirect with Account Setup redirect.
- Resolve current step inside Account Setup.
- Ensure Back/sign-out behavior remains deterministic.

### Phase D — Remove Mobile from onboarding

- Remove Mobile from `BuildOnboardingFlowUseCase`.
- Update onboarding sections/progress/plans/tests.
- Remove onboarding-owned provider Mobile decision.

### Phase E — Persistence/resume

- Reuse account/profile repository writes.
- Validate blank/entered mobile persistence.
- Preserve real provider verification semantics.
- Validate session restore/reinstall/new-device behavior.

### Phase F — Validation

- Account Setup planner tests.
- Username availability/save/race tests.
- Mobile blank/entered/provider-verified tests.
- shared footer/back layout tests.
- bootstrap redirect/state tests.
- completed-account bypass tests.
- incomplete-account resume tests.
- full Flutter/Dart analyze/tests.
- real-device fresh Email signup.
- real-device fresh Google signup.

## 11. Guardrails

- Do not implement this task on `codex/onboarding-mode-migration`.
- Do not fold Account Setup into Auth.
- Do not keep Mobile in product onboarding after migration.
- Do not make product onboarding inspect authentication-provider identity.
- Do not duplicate ProfileAccountRepository persistence.
- Do not create fake/default profile values for partial accounts.
- Do not fake mobile verification.
- Do not force completed legacy accounts through Account Setup.
- Do not combine Measurement Unit Preferences implementation into this refactor.
- Do not introduce a broad account/profile rewrite beyond what this boundary requires.

## 12. Branch Strategy

PR #4 remains the stabilization branch.

After PR #4 merges:

```powershell
Set-Location "G:\projects\Tio-World"

git checkout main
git pull --ff-only origin main
git checkout -b codex/account-setup-boundary
git push -u origin codex/account-setup-boundary
```

Implement Issue #18 only on the fresh branch.

Measurement Unit Preferences (#17) remains a separate feature task and should not be mixed into this architecture refactor.

## 13. Acceptance Criteria

- Authentication remains a clean identity/session boundary.
- Account Setup is an explicit flow between Auth and Product Onboarding.
- Username and Mobile share one flow owner.
- Username is required before product onboarding.
- Mobile is optional in the current release.
- Phone-authenticated users can skip Mobile.
- Entered mobile is not marked verified.
- Username and Mobile use shared Account Setup navigation/footer behavior.
- Product onboarding no longer contains Mobile.
- Product onboarding does not own provider-aware account identity decisions.
- Returning completed accounts bypass Account Setup.
- Fresh incomplete accounts resume the correct Account Setup step.
- Existing username policy/race handling remains intact.
- Existing Supabase/Profile persistence boundaries are reused safely.
- Full CI is green.
- Fresh Email and Google real-device flows pass manual QA.
