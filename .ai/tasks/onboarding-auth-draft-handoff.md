# Onboarding Pre-Auth Draft Persistence

**Status:** Core handoff implemented; Product Onboarding root-Back exit follow-up open; real-device revalidation pending
**Tracking:** GitHub issue #13 (related to #10 and profile persistence #8)
**Source branch:** `codex/onboarding-mode-migration`
**Current follow-up branch:** `agent/app-mode-pre-signup` / PR #36
**Primary owner:** `apps/app` + `apps/features/onboarding` + `apps/features/nutrition`

## User-reported regressions

### 1. Pre-auth draft loss

```text
Get Started
-> choose App Mode
-> complete Profile (name/height/weight/etc.)
-> Google auth checkpoint
-> select fresh Google account
-> bootstrap requires onboarding
-> app restarts at App Mode
```

### 2. Resolved-step flash after first local-draft fix

Real-device retest showed the flow eventually resumed correctly at Workout Intro, but briefly rendered App Mode for about one second first.

### 3. Entered profile metrics missing from nutrition owner

Real-device completion collected height, current weight, target weight and activity level. Read-only Supabase audit showed those values were correctly persisted in `public.users`, while the matching columns in `public.user_nutrition_profiles` were still null.

Latest audited completed account showed:

```text
public.users
height_cm             = 129.54
current_weight_kg     = 76.0
target_weight_kg      = 75.2
activity_level        = dynamic

public.user_nutrition_profiles
height_cm             = null
current_weight_kg     = null
target_weight_kg      = null
activity_level        = null
steps_target          = 10000
water_target_ml       = 2500
sleep_target_minutes  = 480
```

No production row was mutated or backfilled during this audit.

## Verified root causes

### Pre-auth ownership

Before authentication there is no Supabase `user_id`, so the user-owned remote draft cannot safely own pre-auth answers. The previous implementation kept those answers only in an auto-disposed controller, allowing the auth redirect to destroy them.

### App Mode flash

`OnboardingController` is constructed with a default/fresh draft before asynchronous local/remote hydration finishes. The default first step is App Mode. The hydrated resume draft then replaces that state with Workout Intro, creating the visible one-second wrong-step flash.

### Nutrition projection gap

`ProfileSetupMapper` and `SupabaseProfileSetupRepository` already persisted collected measurements into `public.users`.

However, `TargetsSetupData` did not contain height/current weight/target weight/activity level. `TargetsSetupMapper` therefore could not project those collected Profile values into the nutrition owner, and `SupabaseTargetsSetupRepository` never wrote the corresponding existing `user_nutrition_profiles` columns.

## Frozen ownership contract

```text
SIGNED OUT
-> onboarding/profile draft stays encrypted device-local only
-> no onboarding/profile draft write to Supabase

AUTH CHECKPOINT
-> keep current signed-out draft
-> store separate resume-after-auth checkpoint locally

AUTHENTICATED
-> bind local record to selected Supabase user id
-> existing remote onboarding draft wins when present
-> otherwise migrate matching local resume checkpoint to onboarding_drafts
-> clear local temporary copy after successful migration

ONBOARDING COMPLETION
-> persist entered canonical owner data
-> entered height/current weight/target weight/activity project to users + nutrition profile
-> optional/uncollected nutrition fields may remain null
```

## Local data protection

Pre-auth onboarding includes profile/health-adjacent fields such as DOB, height, weight, goals and health conditions. Production local persistence uses platform secure storage (`flutter_secure_storage`), not plain SharedPreferences.

The local record keeps two snapshots:

- `draft`: signed-out screen state. App restart or cancelled auth resumes here.
- `resumeAfterAuth`: first valid post-Profile state. Only an authenticated matching identity can migrate/use it.

## Implemented changes

- [x] Encrypted device-local pre-auth onboarding draft store.
- [x] Auth-aware local/remote draft repository.
- [x] Signed-out autosaves remain local only.
- [x] Identity binding and one-time local -> remote draft migration after auth.
- [x] Existing remote user-owned draft remains authoritative.
- [x] Separate current signed-out draft and post-auth resume snapshot.
- [x] Identity mismatch / stale bound local state protection.
- [x] Remote draft read failures are not treated as confirmed missing rows.
- [x] Production hydration render gate: default App Mode content is hidden until the resume draft resolves.
- [x] Hydration gate is an explicit production policy; feature/default contexts retain backwards-compatible eager rendering.
- [x] `TargetsSetupData` carries optional collected profile measurements.
- [x] `TargetsSetupMapper` maps entered height/current weight/target weight/activity.
- [x] `SupabaseTargetsSetupRepository` writes/reads those existing nutrition profile columns.
- [x] Null/optional projection fields are omitted on write instead of fabricating values.
- [x] Regression coverage for local-only persistence, migration, identity isolation, resume hydration and measurement mapping.

## Relevant commits

- `aecfec8946fe143755c9624479662b792b7b88be` — encrypted local-first onboarding draft persistence.
- `6348478a58dfbfe00bce0de1a4b333fbb264d418` — local-draft analyzer cleanup.
- `88aaf6aadc410dd6be08e7e1ec9be803d556daad` — extend nutrition target owner with profile metrics.
- `754e1233ec7d4ef2e2196623b206e297aefc234e` — map Profile measurements to nutrition owner.
- `84f5cbce66bc3250bbdbd6a8f69d518c8ed89eab` — persist/read metrics in `user_nutrition_profiles`.
- `aa94e7dfb6d4d19ac4c0d87efa926372c6784739` — mapper regression coverage.
- `871e052900475a8981e5cbbd7e8157abc9d32a12` / `d76d9db958cba24a127b72ba1dbf744712133a18` — publish hydration readiness and hide unresolved default step.
- `fe812228d9883a950f9c9ba79cd150e79ed57f2e` — hydration-resume regression coverage.
- `3fad862a8a43e79a5a712949ef305d26016c10b8` / `7d7b66087cfa0483fd48ad0cea8922ee99dcf7ed` / `146adcc5ec814b2ff7b573bb8866c173274d7e2c` / `583ec1b08e12036e84088f48375d68fe4247fc5f` — make hydration gate explicit and enable it only in production app wiring.

## Automated validation

GitHub Actions run #97 on head `583ec1b08e12036e84088f48375d68fe4247fc5f`:

- workspace bootstrap: passed
- Flutter analyzers: all packages passed
- Dart analyzer: passed
- app local-draft/auth-resume tests: passed, including hydrated resolved-step notification
- app test total: 104 passed / 10 failed
- the 10 failures are the same pre-existing Welcome accessibility, avatar expectation, and AppMode router `pumpAndSettle` baseline failures
- no new failing test class was introduced by this slice

`apps/features/onboarding/test/domain/targets_setup_mapper_test.dart` additionally covers collected metric projection and null preservation for uncollected optional values. Because workspace tests currently use fail-fast and the app package hits the known baseline failures first, this later-package test still needs targeted local execution or a future CI non-fail-fast improvement.

## Remaining device gate

Use a fresh onboarding completion after pulling the latest branch:

```text
Get Started
-> App Mode
-> fill Profile height/current weight/target weight/activity
-> Google fresh signup
-> auth/bootstrap
-> direct resolved next step (Workout Intro for workout flow)
-> no App Mode flash
-> complete onboarding
```

Then read-only Supabase verification must show:

```text
public.users
entered measurement fields = persisted

public.user_nutrition_profiles
same entered height/current weight/target weight/activity = persisted
optional/skipped fields = allowed to remain null
```

Do not backfill earlier completed rows until separately approved.

## Audit follow-up — Product Onboarding root Back (2026-08-19)

Read-only audit of PR #36 found a navigation/session boundary gap around the Google-name forward-skip behavior.

Current intended Google flow is:

```text
Google signup/auth succeeds
-> trusted Google display name seeds Profile Name
-> forward entry starts at Gender
-> Back from Gender reveals editable Name
```

Controller behavior already supports `Gender -> Back -> Name`, and Name remains the first/root Profile child. The page/router exit path is not yet aligned with that root boundary.

### Verified gap

`OnboardingFlowPage` decides whether Back is internal or an exit primarily from the outer `OnboardingState.hasPreviousStep`. That value is based on top-level onboarding steps and does not represent nested Profile child history. This creates a mismatch between controller-level child navigation and page-level Back ownership.

At the Product Onboarding root, the current router `onExitRequested` may `pop()` or `go(AppRoutes.auth.path)` without signing out. For an authenticated user whose bootstrap state is `RequiresOnboarding`, routing to Auth is not a real exit because session policy redirects the authenticated incomplete account back to `/onboarding`.

### Required acceptance contract

```text
Gender -> Back -> Name
Goal -> Back -> Gender
Name -> Back -> sign out -> refresh session bootstrap -> Welcome
```

Visible top-bar Back and Android/system Back must use the same contract.

The root exit must end the authenticated session before navigating to Welcome. It must not rely on `go('/auth')` while the session is still authenticated.

### Draft retention contract

Root Back/logout must not discard the user-bound onboarding draft by default. A later login by the same user should remain eligible to resume the existing draft. Draft deletion should require a separate explicit discard/reset product action.

### Open implementation / validation items

- [ ] Make nested Profile Back ownership explicit at page/controller boundary instead of inferring it only from top-level `hasPreviousStep`.
- [ ] Treat Profile `Name` as the Product Onboarding root exit boundary.
- [ ] On root exit, call the auth session sign-out contract and refresh session bootstrap before resolving to Welcome.
- [ ] Keep visible Back and system Back behavior identical.
- [ ] Preserve the user-bound onboarding draft across this logout flow.
- [ ] Add regression coverage for `Gender -> Name`, `Name -> logout -> Welcome`, and system/visible Back parity.
- [ ] Real-device verify fresh Google signup: `Gender -> Back -> Name -> Back -> Welcome`, then re-login and confirm draft resume semantics.

No source-code change was made during the audit that added this follow-up.