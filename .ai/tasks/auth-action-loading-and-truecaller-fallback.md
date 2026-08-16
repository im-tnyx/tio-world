# Auth Action Loading and Truecaller Fallback

**Status:** In progress — awaiting local validation
**Primary owner:** `apps/features/auth`
**Affected platforms:** Flutter phone app
**Tracking:** GitHub issue #9

## 1. User Outcome

Login auth actions now have independent visual loading ownership, and unavailable Truecaller is non-destructive.

```text
Email tap
→ only Login spinner
→ Google + Truecaller disabled, no spinner

Google tap
→ only Google spinner
→ Login + Truecaller disabled, no spinner

Truecaller tap
→ no spinner
→ no auth/network
→ no navigation
→ show: “Truecaller sign-in is not available yet.”
```

## 2. Guardrails

- No Truecaller SDK/provider integration in this slice.
- No fake Truecaller request/success.
- #7 remains routing/bootstrap owner.
- No AuthLanding/legal-copy changes.
- No shared `TioSocialButton` redesign.
- Login geometry, spacing, typography, colors, assets, and button layout remain unchanged.

## 3. Implementation

`LoginPage` now uses explicit action identity:

```text
idle
emailLoading
googleLoading
```

There is no `truecallerLoading` state.

Implemented behavior:

- [x] replace global `_isLoading` with `_activeAction`
- [x] Email owns only Login button loading
- [x] Google owns only Google button loading
- [x] conflicting auth actions are disabled without spinner duplication
- [x] busy guard prevents duplicate overlapping auth submissions
- [x] cancellation/failure returns initiating action to idle through `finally`
- [x] Truecaller placeholder navigation removed
- [x] Truecaller uses existing Login feedback surface with informational copy
- [x] back/forgot/signup continue to respect shared busy gating
- [x] shared button component untouched

## 4. Tests Added

`apps/features/auth/test/presentation/login_page_test.dart` now covers:

- [x] Email request: only Login loading
- [x] Google/Truecaller conflict-gated during Email without spinners
- [x] Google request: only Google loading
- [x] Login/Truecaller conflict-gated during Google without spinners
- [x] Email cancellation returns actions to idle
- [x] Google cancellation returns actions to idle
- [x] unavailable Truecaller stays on Login
- [x] unavailable Truecaller emits no success callback
- [x] unavailable Truecaller shows `Truecaller sign-in is not available yet.`
- [x] existing Login render/success/error tests retained

## 5. Quality Review

Production diff audit confirms changes are limited to action state/interaction bindings and Truecaller feedback. No spacing/token/layout/asset values changed.

## 6. Validation Required

Run locally with the pinned Flutter SDK:

```powershell
Set-Location "G:\projects\Tio-World"
git status --short --branch
git pull --ff-only

Set-Location "G:\projects\Tio-World\apps\features\auth"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/presentation/login_page_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/presentation/auth_landing_page_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World\apps\app"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/session/app_session_bootstrap_controller_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/session/app_session_route_policy_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World"
git status --short --branch
```

## 7. Final Handoff

### Changed runtime file

```text
apps/features/auth/lib/src/presentation/login/pages/login_page.dart
```

### Changed test/task files

```text
apps/features/auth/test/presentation/login_page_test.dart
.ai/tasks/auth-action-loading-and-truecaller-fallback.md
```

### Final Status

`IMPLEMENTED — LOCAL VALIDATION PENDING`
