# Missing AppMode Guided Navigation Recovery

**Status:** In progress — immediate recovery slice implementation pending local validation
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

The single-tab shell guard is correct and must remain because Flutter Material `NavigationBar` requires at least two destinations. The product bug is the missing confirmed AppMode.

## Root cause

- Remote `public.users.is_onboarded` is durable onboarding completion authority.
- `AppModeController` currently reads/writes `SharedPreferencesAppModePreference` only.
- `CompleteOnboardingUseCase` persists owner data, then writes selected AppMode through the local preference adapter.
- Live Supabase schema inspection confirms there is currently no `app_mode`/mode column in `public.users`.
- Therefore fresh installs, cleared app data, or migrated completed accounts can restore completion without restoring AppMode.

## Slice A — immediate missing-mode recovery

Guardrails:

- Do not remove the single-tab NavigationBar safety guard.
- Do not silently persist Hybrid as the user's AppMode.
- Existing configured users must retain current routing and visuals.
- No production Supabase mutation in this slice.

Implementation contract:

```text
bootstrap Ready + onboarding completed + selectedMode == null
→ route to existing App Mode selection surface
→ user explicitly chooses Workout / Nutrition / Hybrid
→ AppModeController.select(mode)
→ local preference persists
→ Home
→ guidedShellTabs(mode)
→ correct bottom navigation appears
```

Required changes:

- [ ] route policy redirects completed+missing-mode users to App Mode recovery instead of Home-only
- [ ] AppMode Settings surface accepts a missing current mode for first selection
- [ ] recovery route allows save and returns Home
- [ ] configured mode behavior remains unchanged
- [ ] regression: completed+missing mode routes to recovery
- [ ] regression: selecting a mode restores correct guided tabs
- [ ] analyzers green
- [ ] device validation: bottom nav visible after explicit mode selection

## Slice B — durable AppMode persistence/restoration

Separate follow-up after Slice A is green:

- design authenticated Supabase storage for AppMode
- add reviewed migration (do not mutate production blindly)
- persist confirmed mode remotely on onboarding completion and Settings changes
- restore remote mode before routing Home on returning/fresh-install sessions
- keep local preference as cache/fast-path, not durable authority
- define legacy null migration policy explicitly

## Validation gate

```powershell
Set-Location "G:\projects\Tio-World"
git status --short --branch
git pull --ff-only

Set-Location "G:\projects\Tio-World\apps\features\settings"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World\apps\app"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/app_mode_route_policy_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/app_mode_router_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/tio_shell_bottom_nav_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World"
git status --short --branch
```
