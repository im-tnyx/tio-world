# Material 3 Expressive Foundation

**Status:** In progress
**Primary owners:** `apps/core`, `apps/app`

## Outcome

Establish Material 3 Expressive as a consistent, accessible phone design system through `apps/core` tokens and shared components, without assuming unsupported Flutter framework APIs.

## Verified Starting Point

- Baseline Material 3 is enabled in the phone and Wear themes.
- `TioTheme` already owns semantic colors, typography, radius, spacing, and motion tokens.
- The phone shell now uses Material 3 `NavigationBar` with shared navigation tokens and App Mode-driven destinations.
- Shared `TioButton` variants use finite token-driven sizing and accessible interaction/loading states without constraining AppBar text actions to infinite width.
- Global `NoSplash` overrides have been removed so Material touch/state feedback remains perceptible.
- `TioThemeConfig` high-contrast and reduced-motion values now change semantic colors, route transitions, `MediaQuery.disableAnimations`, and the shared `TioMotionScheme`.
- The approved shared Flutter SDK is available outside PATH and validates this slice without adding machine-specific paths to the repository.

## In Scope

1. Define the phone token policy for expressive color, typography, shapes, spacing, motion, and touch feedback in `apps/core`.
2. Make high-contrast and reduced-motion settings change observable theme behavior.
3. Migrate one shared component at a time, starting with the primary navigation after App Mode branch mapping is ready.
4. Verify light, dark, OLED, high-contrast, reduced-motion, keyboard, and screen-reader behavior for each migrated component.
5. Keep Wear tokens and components compact; do not copy phone-scale navigation or motion to the watch.

## Out of Scope

- Adding an unverified third-party M3 Expressive package.
- Rewriting feature screens before shared token/component foundations are ready.
- Replacing Flutter Wear OS with native Wear code.
- Changing App Mode persistence, backend contracts, or data behavior.

## Acceptance Criteria

- Shared components consume `apps/core` semantic tokens rather than feature-local values.
- Touch feedback remains perceptible and accessible.
- High contrast and reduced motion are both testable behaviors, not unused configuration fields.
- Each migration passes analysis, targeted tests, and manual device checks with the approved Flutter toolchain.

## Implementation Evidence

- [x] Restore framework Material touch feedback instead of disabling splash, hover, and highlight globally.
- [x] Add high-contrast light/dark semantic color behavior and expose it through the existing theme extension.
- [x] Add a reduced-motion theme extension, zero custom motion durations, disable route transitions, and expose `MediaQuery.disableAnimations`.
- [x] Migrate guided primary navigation from `BottomNavigationBar` to token-driven Material 3 `NavigationBar`.
- [x] Extract `TioAvatar` with semantic size/shape, optional image, safe fallback, and accessibility contracts; migrate the shell profile entry.
- [x] Harden `TioButton` primary, secondary, and ghost variants with token-driven states, loading lockout, live semantics, and reduced-motion behavior; migrate App Mode save actions.
- [x] Fix Welcome image-control and feature-panel contrast, and move its entrance animation to the shared reduced-motion scheme.
- [x] Add focused automated tests for touch feedback, high contrast, reduced motion, navigation rendering/selection, avatar behavior, and button integration.
- [x] Verify Welcome and shared action rendering on a Pixel 9 emulator in light and dark mode, plus compact-width widget coverage.
- [x] Add OLED semantic-color, keyboard activation, guided-navigation semantics, and non-interactive-placeholder regression coverage.
- [x] Verify TalkBack service activation plus structural labels, roles, and the Home → Profile → Settings route on the updated Pixel 9 build.
- [ ] Complete spoken-output TalkBack traversal on a physical Android device before this task moves to `Validated`.
- [ ] Migrate the next approved shared component; feature-screen restyling remains out of scope until shared foundations are stable.

## Validation Evidence

- `apps/app`: `flutter analyze` passes.
- `apps/app`: full `flutter test` passes (45 tests).
- Focused theme/navigation/avatar/button/router/Welcome widget tests pass.
- Pixel 9 Android emulator (API 37): light and dark Welcome rendering pass after semantic contrast correction; a 393x852 widget viewport passes without layout exceptions.
- Android debug APK builds with the repository Gradle configuration when a compatible JDK 17 is supplied for the build process. No shared Flutter JDK configuration was changed.
- OLED and keyboard/focus contracts pass automated coverage. Pixel 9 TalkBack structural inspection confirms meaningful labels and roles across Home → Profile → Settings; spoken-output traversal on physical hardware remains before this task moves to `Validated`.

## Canonical Links

- [Architecture](../../docs/ARCHITECTURE.md)
- [Roadmap](../../docs/ROADMAP.md)
- [UI rules](../ui-rules.md)
