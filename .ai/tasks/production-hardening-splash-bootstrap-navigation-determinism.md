# Production Hardening — Splash / Bootstrap Navigation Determinism

Status: **COMPLETE / FROZEN**
Owner: #5 P1 item 15
Implementation PR: #50 (Draft/open/unmerged)
Audit date: 2026-08-25

Fresh audit head:

```text
ccff219f9bd8ab0f58a0393e55df35f6079ca904
```

Accepted source/test checkpoint:

```text
8f91280634cfc3cf5002ee8c00b0df45df23f0fd
Flutter CI #1945 / run 32827016471 ✅
Android Native CI #357 / run 32827016528 ✅
```

## Goal

Keep startup destination and timeout ownership singular. `SplashScreen` is presentation-only while `AppSessionBootstrapController` + `GoRouter.redirect` own startup session resolution, failure/retry, and destination routing.

## Fresh audit result

Before this slice, the app-level router/bootstrap was already the active production owner:

`apps/app/lib/app/router.dart`:
- starts at `AppRoutes.splash.path`;
- listens to `appSessionBootstrapController`, App Mode, and onboarding status;
- evaluates `appSessionBootstrapRedirect(...)` before App Mode routing;
- renders Splash failure feedback from `AppSessionBootstrapFailure`;
- delegates Retry to `appSessionBootstrapController.refresh()`.

`apps/app/lib/app/session/app_session_bootstrap_controller.dart`:
- owns Auth session resolution;
- owns the bounded remote lookup timeout;
- maps lookup error/timeout to `AppSessionBootstrapFailure`;
- protects concurrent/stale resolutions with generation checks;
- owns retry through `refresh()`.

The remaining reproducible gap was a legacy second navigation authority in `SplashScreen`:

```text
onCheckInitialDestination
→ private init flow
→ independent 4-second timeout
→ fallback to Auth
→ direct context.go(destination)
```

Production did not call this API, but leaving it available allowed a future caller to bypass the canonical bootstrap route policy.

## Final owner decision

```text
Startup session resolution + timeout  → AppSessionBootstrapController
Startup destination policy            → appSessionBootstrapRedirect / GoRouter
Splash presentation + Retry UI        → SplashScreen
```

## Implementation

- [x] removed `onCheckInitialDestination` from `SplashScreen`;
- [x] removed Splash-owned post-frame destination resolution;
- [x] removed Splash-owned 4-second timeout and Auth fallback;
- [x] removed direct `context.go(...)` / `go_router` dependency from Splash source;
- [x] preserved failure feedback, loading UI, and Retry callback behavior;
- [x] updated Splash tests to presentation-only contracts;
- [x] added app-level source-boundary regression preventing Splash from becoming a navigation authority again;
- [x] preserved existing `appSessionBootstrapRedirect` routing matrix unchanged;
- [x] made no Supabase/schema/auth-provider change;
- [x] exact-head Flutter/Dart + Android CI green.

## Regression evidence

`apps/features/splash/test/presentation/screen/splash_screen_test.dart` covers:
- passive loading while app bootstrap resolves;
- recoverable failure feedback;
- Retry callback delegation;
- in-flight Retry progress and duplicate-tap suppression.

`apps/app/test/app/production_hardening_splash_navigation_ownership_test.dart` locks the ownership boundary by asserting that Splash contains no:
- `onCheckInitialDestination`;
- direct `context.go(...)`;
- startup `.timeout(...)`;
- `go_router` dependency;
- Auth fallback destination policy.

The same regression confirms the app router still owns `initialLocation`, `appSessionBootstrapRedirect(...)`, bootstrap Retry, and bootstrap failure handling.

## Acceptance invariants

1. [x] `SplashScreen` exposes no destination-resolution API.
2. [x] `SplashScreen` contains no direct router navigation call.
3. [x] `SplashScreen` contains no startup timeout/fallback policy.
4. [x] App bootstrap failure remains recoverable on Splash.
5. [x] Retry delegates to app-owned bootstrap refresh.
6. [x] Loading/Failure/Auth/Account Setup/Onboarding/Home routing remains governed by the existing app route policy.
7. [x] Exact-SHA Flutter/Dart + Android CI is green.
8. [x] PR #50 remains Draft/open/unmerged unless separately authorized.
