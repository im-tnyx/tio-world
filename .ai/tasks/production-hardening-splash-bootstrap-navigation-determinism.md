# Production Hardening — Splash / Bootstrap Navigation Determinism

Status: AUDIT COMPLETE / IMPLEMENTATION REQUIRED
Owner: #5 item 15
Implementation PR: #50 (Draft/open/unmerged)
Audit date: 2026-08-25

## Goal

Keep startup destination and timeout ownership singular. `SplashScreen` must be presentation-only while `AppSessionBootstrapController` + `GoRouter.redirect` own startup session resolution, failure/retry, and destination routing.

## Fresh current-head audit

### Production app owner is already router/bootstrap

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

`apps/app/lib/app/session/app_session_route_policy.dart` and its focused tests already define deterministic destination policy for Loading, Failure, Unauthenticated, Account Setup, Onboarding, and Ready states.

### Reproducible remaining gap

`apps/features/splash/lib/src/presentation/screen/splash_screen.dart` still exposes a legacy second navigation authority:

```text
onCheckInitialDestination
→ private init flow
→ independent 4-second timeout
→ fallback to Auth
→ direct context.go(destination)
```

Production does not currently pass this callback, but leaving it available creates a latent duplicate timeout/navigation owner and allows future callers to bypass the canonical bootstrap route policy.

Code search found no production consumer of `onCheckInitialDestination`; only Splash source/tests reference it.

## Owner decision

```text
Startup session resolution + timeout  → AppSessionBootstrapController
Startup destination policy            → appSessionBootstrapRedirect / GoRouter
Splash presentation + Retry UI        → SplashScreen
```

`SplashScreen` must not resolve destinations or call router navigation directly.

## Implementation

- [ ] remove `onCheckInitialDestination` from `SplashScreen`;
- [ ] remove Splash-owned post-frame init/destination resolution;
- [ ] remove Splash-owned 4-second timeout and Auth fallback;
- [ ] remove direct `context.go(...)` / `go_router` dependency from Splash source;
- [ ] keep failure feedback, loading UI, and Retry callback behavior;
- [ ] update Splash tests to presentation-only contracts;
- [ ] add app-level source-boundary regression preventing Splash from becoming a navigation authority again;
- [ ] preserve existing `appSessionBootstrapRedirect` routing matrix unchanged;
- [ ] no Supabase/schema/auth-provider change;
- [ ] exact-head Flutter/Dart + Android CI green.

## Acceptance invariants

1. `SplashScreen` exposes no destination-resolution API.
2. `SplashScreen` contains no direct router navigation call.
3. `SplashScreen` contains no startup timeout/fallback policy.
4. App bootstrap failure remains recoverable on Splash.
5. Retry delegates to app-owned bootstrap refresh.
6. Loading/Failure/Auth/Account Setup/Onboarding/Home routing remains governed by the existing app route policy.
7. PR #50 remains Draft/open/unmerged unless separately authorized.
