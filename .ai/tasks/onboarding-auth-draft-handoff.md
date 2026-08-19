# Onboarding Pre-Auth Draft Persistence

**Status:** Core handoff implemented; Product Onboarding root-Back confirmation/logout implemented; CI + real-device revalidation pending
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

## Automated validation history

GitHub Actions run #97 on head `583ec1b08e12036e84088f48375d68fe4247fc5f`:

- workspace bootstrap: passed
- Flutter analyzers: all packages passed
- Dart analyzer: passed
- app local-draft/auth-resume tests: passed, including hydrated resolved-step notification
- app test total: 104 passed / 10 failed
- the 10 failures are the same pre-existing Welcome accessibility, avatar expectation, and AppMode router `pumpAndSettle` baseline failures
- no new failing test class was introduced by that slice

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

## Product Onboarding root Back follow-up (2026-08-19)

The Google-name forward-skip keeps Profile `Name` as a real editable first step while normal forward entry may begin at `Gender` when trusted Google identity metadata already supplied the name.

### Final acceptance contract

```text
Goal -> Back -> Gender
Gender -> Back -> Name
Name -> Back -> show logout confirmation card

Stay
-> close confirmation
-> remain on Name
-> remain authenticated
-> keep draft unchanged

Log out
-> sign out
-> refresh session bootstrap
-> Welcome
```

Visible top-bar Back and Android/system Back use the same root/internal navigation decision.

The confirmation is a session-exit confirmation, not a discard-progress action. Logging out must not call `clearDraft()` or otherwise erase the user-bound onboarding draft. The same account remains eligible to resume later.

### UI ownership

The confirmation is not an `AlertDialog` and does not define feature-local visual tokens.

- reusable `TioConfirmationCard` lives under `apps/core/lib/src/ui/components/cards/`;
- it composes existing `TioCard`, `TioButton`, runtime theme colors, semantic typography, spacing and size contracts;
- product-specific logout copy and behavior remain owned by Product Onboarding;
- the card is presented from a modal sheet with a transparent framework surface;
- `apps/core/lib/src/theme/README.md` documents the reusable component contract;
- no new component token family was introduced.

### Implemented follow-up

- [x] Added nested-aware `OnboardingState.hasPreviousScreen` so Profile/Workout/Targets child history participates in Back ownership.
- [x] Product Onboarding Back dispatch now uses one internal-vs-root decision for visible and system Back.
- [x] Profile `Name` is the Product Onboarding root exit boundary.
- [x] Root Back opens reusable themed `TioConfirmationCard` instead of immediately logging out.
- [x] `Stay` closes the card and remains on Name without calling the exit callback.
- [x] `Log out` delegates the confirmed exit.
- [x] App router confirmed exit now calls `authSessionRepositoryProvider.signOut()` and `appSessionBootstrapController.refresh()`; it no longer tries to route an authenticated incomplete user directly to `/auth`.
- [x] No draft clear/reset is part of this root logout path.
- [x] Added focused feature regression tests for `Gender -> Name`, Cancel, Confirm, and system/visible Back parity.
- [x] Added app router regression coverage for confirmed `signOut -> refresh -> Welcome` behavior.
- [ ] Latest GitHub CI on the final branch head must complete.
- [ ] Real-device verify fresh Google signup: `Gender -> Back -> Name -> Back -> confirmation -> Log out -> Welcome`, then re-login and confirm draft resume semantics.

### Follow-up implementation commits

- `c619f2a7` — add reusable core confirmation card.
- `51fd5639` — export reusable confirmation card.
- `e8134fa6` — expose nested Back availability.
- `cf6bc9ee` — confirm Product Onboarding root exit with themed reusable card.
- `77910081` — feature regression coverage for root confirmation and Back parity.
- `11a193c1` — confirmed Product Onboarding root exit signs out and refreshes bootstrap.
- `83110ec1` — app router regression for confirmed logout to Welcome.
- `d75e05fe` — document the reusable confirmation-card theme contract.
