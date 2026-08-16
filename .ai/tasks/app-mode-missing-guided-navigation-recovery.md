# Missing AppMode Guided Navigation Recovery

**Status:** In progress — compatibility navigation implemented, local/device validation pending
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
- Live Supabase schema inspection confirms there is currently no `app_mode`/mode column in `public.users`.
- Therefore fresh installs, cleared app data, or migrated completed accounts can restore completion without restoring AppMode.

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

## Slice B — durable AppMode persistence/restoration

Separate follow-up after Slice A is green:

- design authenticated Supabase storage for AppMode
- add reviewed migration (do not mutate production blindly)
- persist confirmed mode remotely on onboarding completion and Settings changes
- restore remote mode before routing Home on returning/fresh-install sessions
- keep local preference as cache/fast-path, not durable authority
- define legacy null migration/recovery policy explicitly

## Validation gate

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
