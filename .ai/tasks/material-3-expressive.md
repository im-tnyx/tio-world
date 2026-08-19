# Material 3 Expressive Foundation

**Status:** In progress
**Primary owners:** `apps/core`, `apps/app`
**Canonical token architecture:** `.ai/tasks/design-system-token-consolidation.md`
**Related issue:** #6
**Draft PR:** #22

## Outcome

Establish Material 3 Expressive as a consistent, accessible phone design system through centralized `apps/core` tokens and shared components, without assuming unsupported Flutter framework APIs.

This task does not own an independent token architecture. All visual ownership follows the canonical design-system task.

## Mandatory Visual Freeze

Existing screens/components must remain visually equivalent while token/theme ownership is migrated.

No screen design, layout, color appearance, typography appearance, spacing, radius, icon sizing, component geometry, or motion choreography may change without a separate explicit owner/design confirmation.

If an expressive/UI improvement is desirable, record it as a separate visual decision/task rather than silently applying it during ownership cleanup.

## Verified Starting Point

- Baseline Material 3 is enabled in the phone and Wear themes.
- The centralized core theme/token system owns semantic colors, typography, radius/spacing roles, motion, reusable component contracts, and Flutter theme composition.
- `TioTheme` is theme composition/configuration, not a second static token catalog.
- The phone shell uses Material 3 `NavigationBar` with shared navigation contracts and App Mode-driven destinations.
- Shared `TioButton` variants use governed sizing and accessible interaction/loading states without constraining AppBar text actions to infinite width.
- Global `NoSplash` overrides have been removed so Material touch/state feedback remains perceptible.
- `TioThemeConfig` high-contrast and reduced-motion values change semantic colors, route transitions, `MediaQuery.disableAnimations`, and the shared motion scheme.
- The approved shared Flutter SDK is available outside PATH and validates this slice without adding machine-specific paths to the repository.

## Design-System Ownership Rule

The target direction is:

```text
Primitive foundation tokens
        ↓
Foundation / semantic / typography / effects roles
        ↓
Component tokens
        ↓
Reusable core components
        ↓
Feature screens/widgets
```

Do not introduce feature-owned design-token systems as part of Material 3 work.

Examples not allowed as final architecture:

```text
WelcomeTokens
AuthTokens
HomeTokens
feature-local color/layout/theme token bags
```

Component contracts describe meaning, but their fixed physical values follow the canonical primitive ownership rules from the parent design-system task.

## In Scope

1. Define phone policy for expressive color, typography, shapes, spacing, motion, and touch feedback through centralized core ownership.
2. Make high-contrast and reduced-motion settings change observable theme behavior.
3. Migrate one shared component at a time after its owner/contracts are clear.
4. Verify light, dark, OLED, high-contrast, reduced-motion, keyboard, and screen-reader behavior for each migrated component.
5. Keep Wear interaction/semantic needs distinct where necessary without creating per-screen token catalogs.

## Out of Scope

- Adding an unverified third-party M3 Expressive package.
- Redesigning feature screens during token/theme migration.
- Rewriting feature screens before shared token/component foundations are ready.
- Replacing Flutter Wear OS with native Wear code.
- Changing App Mode persistence, backend contracts, or data behavior.
- Any visible UI change without separate explicit confirmation.

## Acceptance Criteria

- Shared components consume centralized `apps/core` governed contracts rather than feature-local visual values.
- No feature-owned parallel design-token catalog is introduced.
- Fixed visual values follow the canonical primitive/core ownership model.
- Touch feedback remains perceptible and accessible.
- High contrast and reduced motion are testable behaviors, not unused configuration fields.
- Existing visual output remains unchanged unless a separately approved visual change is linked.
- Each migration passes analysis, targeted tests, and required device/accessibility checks.

## Implementation Evidence

- [x] Restore framework Material touch feedback instead of disabling splash, hover, and highlight globally.
- [x] Add high-contrast light/dark semantic color behavior and expose it through the existing theme extension.
- [x] Add a reduced-motion theme extension, zero custom motion durations, disable route transitions, and expose `MediaQuery.disableAnimations`.
- [x] Migrate guided primary navigation from `BottomNavigationBar` to token-driven Material 3 `NavigationBar`.
- [x] Extract `TioAvatar` with semantic size/shape, optional image, safe fallback, and accessibility contracts; migrate the shell profile entry.
- [x] Harden `TioButton` primary, secondary, and ghost variants with governed states, loading lockout, live semantics, and reduced-motion behavior; migrate App Mode save actions.
- [x] Fix previously approved Welcome image-control/feature-panel contrast behavior and move entrance animation to the shared reduced-motion scheme.
- [x] Add focused automated tests for touch feedback, high contrast, reduced motion, navigation rendering/selection, avatar behavior, and button integration.
- [x] Verify Welcome and shared action rendering on a Pixel 9 emulator in light and dark mode, plus compact-width widget coverage.
- [x] Add OLED semantic-color, keyboard activation, guided-navigation semantics, and non-interactive-placeholder regression coverage.
- [x] Verify TalkBack service activation plus structural labels, roles, and the Home → Profile → Settings route on the updated Pixel 9 build.
- [ ] Reconcile earlier component/Welcome token work with the corrected canonical primitive ownership architecture under #6.
- [ ] Complete spoken-output TalkBack traversal on a physical Android device before this task moves to `Validated`.
- [ ] Migrate the next approved shared component only after canonical ownership is stable.

## Validation Evidence

- Existing recorded `apps/app` analyze/tests and focused theme/navigation/avatar/button/router/Welcome tests were green at their respective checkpoints.
- Pixel 9 Android emulator verification covered light/dark Welcome rendering and compact-width behavior at the recorded checkpoint.
- OLED and keyboard/focus contracts have automated coverage.
- Any future migration under this task must revalidate against the current branch head and the canonical design-system architecture.

## Canonical Links

- [Canonical token task](design-system-token-consolidation.md)
- [Hardcoded color audit](design-system-hardcoded-color-audit.md)
- [Architecture](../../docs/ARCHITECTURE.md)
- [Roadmap](../../docs/ROADMAP.md)
- [UI rules](../ui-rules.md)
