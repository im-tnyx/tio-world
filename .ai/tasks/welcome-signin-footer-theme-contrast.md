# Welcome Sign-in Footer Theme Contrast

**Status:** In progress  
**Primary owner:** Flutter mobile / Welcome  
**Affected platforms:** Flutter Android and iOS

## Global UI / Design-System Guardrail

The core theme guidance, design-system consolidation task, and feature-package
rules were read before this visual correction. This slice uses existing runtime
semantic colors only; it introduces no token, geometry, typography, or
component contract.

## 1. Discovery

### User Outcome

The Welcome footer's `Already have an account? Log In` text must remain
readable in the active light, dark, and OLED themes.

### Success Criteria

- The footer does not use white media-foreground tokens on the light footer
  surface.
- Supporting copy uses `textSecondary`; the sign-in action uses `primary`.
- Focused widget coverage locks both semantic style assignments.

### Scope

- Welcome sign-in footer colors and its existing accessibility test.

### Non-Goals

- Do not alter hero media text, footer layout, typography, button geometry,
  navigation, authentication, or theme-token definitions.

## 2. Codebase Exploration

### Verified Evidence

- Emulator screenshot shows white footer text on a light surface with
  insufficient contrast.
- `WelcomeScreen` uses `onMediaSecondary` and `onMediaPrimary` for its footer.
- Core defines those media roles as white/light white in all base themes; they
  are appropriate for the hero image but not its surface footer.
- Existing `apps/app/test/app/welcome_accessibility_test.dart` covers Welcome
  rendering and is the focused regression location.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Use normal surface text/link semantics in the footer | Approved | The user explicitly approved correcting the theme-aware contrast defect | Product owner |

## 4. Architecture Design

### Chosen Approach

Use `context.tioColors.textSecondary` for explanatory footer text and
`context.tioColors.primary` for the `Log In` action. Hero content retains its
media-specific colors.

### Ownership and Data Flow

```text
TioTheme active scheme -> TioColors semantic roles -> Welcome footer Text styles
```

### Alternative Rejected

Changing `onMedia*` globally would regress hero text that is intentionally
rendered over image media.

### Failure and Accessibility States

The existing tappable sign-in action and text labels remain unchanged; only
their runtime-resolved foreground colors change.

## 5. Implementation Plan

- [x] Replace incorrect footer media roles with surface semantic roles.
- [x] Add focused light/dark theme style assertions.
- [ ] Run formatting, focused test, and static diff check.

## 6. Quality Review

### Validation Run

```text
git diff --check
PASS (no whitespace errors; Git reported only local LF-to-CRLF conversion warnings)

G:\dev\flutter-sdk\bin\dart.bat format ...welcome_screen.dart ...welcome_accessibility_test.dart
PASS (the resulting diff is formatter-normalized)

G:\dev\flutter-sdk\bin\flutter.bat test test\app\welcome_accessibility_test.dart --no-pub
PENDING: the local Flutter test process is still compiling and has not returned
an exit result in the available terminal window.
```

### Review Findings and Resolution

The source change was reviewed against the captured light-theme emulator
screenshot. A fresh emulator rebuild remains pending the local Flutter build
runner completion.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/welcome-signin-footer-theme-contrast.md`
- `apps/features/welcome/lib/src/presentation/screen/welcome_screen.dart`
- `apps/app/test/app/welcome_accessibility_test.dart`

### Actual Behavior

The footer uses surface-aware text/link roles in place of image-media roles;
hero media text remains unchanged.

### Known Limitations

Full emulator visual rerun depends on a fresh Flutter build runner becoming
available; source/widget validation remains independent of that limitation.

### Final Status

`PARTIAL` — focused Flutter test and fresh emulator visual recheck are pending.
