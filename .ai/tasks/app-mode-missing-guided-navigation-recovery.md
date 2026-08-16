# Missing AppMode Guided Navigation Recovery

**Status:** In progress — compatibility navigation implemented; durable Supabase mode/tab contract added to plan
**Tracking:** GitHub issue #11
**Source branch:** `codex/onboarding-mode-migration`

## Problem

A returning completed user can authenticate and reach Home while the bottom navigation is missing.

Observed/runtime state:

```text
remote onboarding completion = completed
local app_mode = null
→ router visibleTabs = [Home]
→ shell hides NavigationBar for single-tab safety
→ Home renders without guided bottom navigation
```

The single-destination safety remains necessary because Flutter Material `NavigationBar` requires at least two destinations. The product bug is that durable completion can survive while confirmed AppMode is missing locally.

## Root cause

- Remote `public.users.is_onboarded` is durable onboarding completion authority.
- `AppModeController` currently reads/writes `SharedPreferencesAppModePreference` only.
- `CompleteOnboardingUseCase` persists owner data, then writes selected AppMode through the local preference adapter.
- Live Supabase schema inspection confirms there is currently no `app_mode` or active-tab column in `public.users`.
- Therefore fresh installs, cleared app data, migrated completed accounts, or cross-device sessions can restore completion without restoring AppMode/tab configuration.

## Slice A — immediate compatibility navigation

Guardrails:

- Do not remove generic single-destination NavigationBar safety.
- Do not silently persist Hybrid or any AppMode for the user.
- Existing configured Workout/Nutrition/Hybrid users must retain current guided routing and visuals.
- No production Supabase mutation in this slice.
- AI/Coach remains deferred and must not appear in compatibility navigation.

Implemented contract:

```text
bootstrap Ready + onboarding completed + selectedMode == null
→ Home shell receives legacy [Home] visible state
→ shell expands only that missing-mode sentinel to:
   Home / Workout / Nutrition / Progress
→ route policy allows those compatibility shell routes
→ AI/Coach direct route still redirects Home
→ no AppMode preference is written
```

Implemented:

- [x] canonical `missingModeCompatibilityShellTabs` added in core shell state
- [x] `TioShell` expands only single-Home missing-mode state to compatibility tabs
- [x] arbitrary other single-destination states still hide Material NavigationBar safely
- [x] null-mode completed route policy allows Home/Workout/Nutrition/Progress
- [x] null-mode completed route policy still redirects AI/Coach to Home
- [x] configured mode behavior remains unchanged
- [x] regression coverage updated for compatibility tabs and single-destination safety
- [ ] core/app analyzers green locally
- [ ] route-policy regression green locally
- [ ] shell bottom-nav regression green locally
- [ ] device validation: bottom nav visible and tabs navigable

## Slice B — durable Supabase AppMode + active tabs

### Product intent

Persist enough account-level preference data in Supabase to answer both:

1. Which Tio service experience is the user primarily using?
2. Which bottom-navigation tabs are active for this user right now?

This supports returning sessions, fresh installs, cross-device restore, future personalized navigation, and later custom-tab configuration.

### Proposed `public.users` columns

```sql
app_mode    text null
active_tabs text[] null
```

`app_mode` semantic values:

```text
workout
nutrition
hybrid
```

`active_tabs` stores ordered stable tab IDs, for example:

```text
['home', 'workout', 'progress']
['home', 'nutrition', 'progress']
['home', 'workout', 'nutrition', 'progress']
```

Future tabs can be appended using stable IDs without changing the column shape.

### Future custom navigation

Bottom navigation is expected to support **3 to 6 active tabs**.

Current production-ready IDs:

```text
home
workout
nutrition
progress
```

Candidate/reserved future IDs from existing but not-yet-production-ready surfaces:

```text
meal_plan
library
social
tio_ai
```

`meal_plan` and `library` are separate destinations. `meal_plan` is the stable domain ID for the meal-plan / diet-plan experience; its visible UI label can be `Meal Plan` or `Diet Plan` without changing stored data. `library` is a distinct browsing/library destination.

These are only stable ID reservations. They must not render or be written into `active_tabs` until their feature/route contracts are explicitly enabled.

Future validation contract:

```text
3 <= active_tabs.length <= 6
home required
IDs unique
order preserved
all IDs registered
rendered IDs must also be currently enabled/eligible
```

Keep three concepts separate:

```text
registered tab ID
→ app recognizes the identity

enabled capability
→ feature is production-ready and eligible to render

active_tabs
→ user's saved ordered preference among enabled/eligible tabs
```

If a saved tab later becomes temporarily unavailable, do not blindly delete the remote preference. Filter effective runtime navigation through the enabled registry and apply a safe fallback if needed.

### Ownership / source-of-truth rule

Do not treat `app_mode` and `active_tabs` as two competing authorities.

```text
app_mode
→ high-level service/product intent
→ drives default guided destinations

active_tabs
→ effective ordered navigation configuration
→ initially derived from app_mode
→ later may represent explicit user customization
```

Initial invariant:

```text
new onboarding completion or App Mode change
→ write app_mode
→ derive canonical tabs from AppMode.guidedDestinations
→ write active_tabs in the same persistence operation
```

Read/restore precedence:

```text
authenticated user
→ read remote app_mode + active_tabs
→ if active_tabs valid/non-empty: restore effective tabs
→ if app_mode valid but active_tabs missing: derive tabs from app_mode and repair/backfill later
→ if both missing on completed legacy user: use Slice A compatibility navigation; do not invent a mode
```

### Validation / data integrity

Before migration implementation:

- [ ] define CHECK constraint or equivalent validation for supported `app_mode` values
- [ ] define canonical stable IDs for every allowed `active_tabs` entry
- [ ] reject unknown/duplicate tab IDs at application/domain boundary
- [ ] preserve array order because it represents navigation order
- [ ] Home must remain present in every effective configuration
- [ ] AI/Coach remains excluded until its route/product contract is explicitly enabled

### Persistence changes

- [ ] create reviewed migration adding `public.users.app_mode`
- [ ] create reviewed migration adding `public.users.active_tabs`
- [ ] preserve existing `public.users` RLS ownership (`auth.uid() = id`)
- [ ] persist both fields on onboarding completion
- [ ] persist both fields when App Mode changes in Settings
- [ ] restore both fields during authenticated bootstrap before Home routing/navigation configuration
- [ ] keep `SharedPreferencesAppModePreference` only as local cache/fast-path
- [ ] define legacy-null reconciliation without silently choosing Hybrid
- [ ] add repository/domain tests for read/write/validation
- [ ] add cross-device/fresh-install restoration regression
- [ ] add future custom-tab regression coverage for 3–6 active tabs and readiness filtering
- [ ] run Supabase advisors/security review before production migration

### Schema guardrail

No production schema mutation from this planning step. Migration must be reviewed, versioned in the repository, validated, and only then applied deliberately.

## Validation gate for Slice A

```powershell
Set-Location "G:\projects\Tio-World"
git status --short --branch
git pull --ff-only

Set-Location "G:\projects\Tio-World\apps\core"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World\apps\app"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/app_mode_route_policy_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/tio_shell_bottom_nav_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World"
git status --short --branch
```

Expected device behavior for a completed user with missing local mode:

```text
Home
→ bottom nav visible: Home / Workout / Nutrition / Progress
→ Workout/Nutrition/Progress tabs navigate normally
→ Tio/AI tab is not shown
→ no NavigationBar assertion
```
