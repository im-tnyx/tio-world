# Auth Action Loading and Truecaller Fallback

**Status:** Complete
**Primary owner:** `apps/features/auth`
**Affected platforms:** Flutter phone app
**Tracking:** GitHub issue #9
**Source branch:** `codex/onboarding-mode-migration`

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
→ no auth/network request
→ no navigation
→ stay on Login
→ show: “Truecaller sign-in is not available yet.”
```

## 2. Guardrails Preserved

- No Truecaller SDK/provider integration in this slice.
- No fake Truecaller request or success result.
- #7 remains routing/bootstrap owner.
- AuthLanding/legal-copy behavior unchanged.
- Shared `TioSocialButton` component unchanged.
- Login geometry, spacing, typography, colors, assets, and button layout unchanged.

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
- [x] busy guard prevents duplicate overlapping submissions
- [x] cancellation/failure returns initiating action to idle through `finally`
- [x] Truecaller placeholder navigation removed
- [x] Truecaller uses existing Login feedback surface
- [x] back/forgot/signup continue to respect shared busy gating
- [x] shared button component untouched

## 4. Regression Coverage

`apps/features/auth/test/presentation/login_page_test.dart` covers:

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

Production diff audit confirmed changes are limited to action-state/interaction bindings and Truecaller feedback. No spacing/token/layout/asset values changed.

Shared `TioSocialButton` already exposed sufficient `enabled` and `loading` APIs, so no core component change was required.

## 6. Local Validation Evidence

```text
apps/features/auth
login_page_test.dart: 9 passed
auth_landing_page_test.dart: 1 passed
flutter analyze: No issues found

apps/app regression
app_session_bootstrap_controller_test.dart: 6 passed
app_session_route_policy_test.dart: 4 passed
flutter analyze: No issues found

Final reported worktree:
codex/onboarding-mode-migration synchronized with origin
working tree clean
```

The auth test runner emitted existing non-failing package/SVG notices (`uses-material-design` mismatch and SVG `<style/>` notice); all tests passed and analyzers were clean.

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

### Actual Behavior

- Email Login shows only its own spinner.
- Google Login shows only its own spinner.
- Other conflicting actions are temporarily non-interactive without inheriting another action's loading state.
- Truecaller remains intentionally unavailable, stays on Login, and shows a clear informational message.

### Deferred

Real Truecaller SDK/provider integration is intentionally deferred to a future dedicated task.

### Final Status

`COMPLETE`
