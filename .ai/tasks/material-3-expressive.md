# Material 3 Expressive Foundation

**Status:** Ready
**Primary owners:** `apps/core`, `apps/app`

## Outcome

Establish Material 3 Expressive as a consistent, accessible phone design system through `apps/core` tokens and shared components, without assuming unsupported Flutter framework APIs.

## Verified Starting Point

- Baseline Material 3 is enabled in the phone and Wear themes.
- `TioTheme` already owns semantic colors, typography, radius, spacing, and motion tokens.
- The phone shell still uses `BottomNavigationBar` and disables splash feedback globally.
- `TioThemeConfig` exposes high-contrast and reduced-motion values, but the theme does not apply them.
- Flutter, Dart, and Melos are not currently available on PATH, so no UI migration may be treated as validated until the approved toolchain is available.

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

## Canonical Links

- [Architecture](../../docs/ARCHITECTURE.md)
- [Roadmap](../../docs/ROADMAP.md)
- [UI rules](../ui-rules.md)
