# Welcome Sign-in Footer Theme Contrast

**Status:** Recovered (Phase 3C)
**Primary owner:** Flutter mobile / Welcome
**Affected platforms:** Flutter Android and iOS

## Global UI / Design-System Guardrail

Core theme guidance and feature-package rules were read before this visual correction. This slice uses existing runtime semantic colors only; it introduces no token, geometry, typography, or component contract.

## 1. Discovery

### User Outcome

The Welcome footer's `Already have an account? Log In` text must remain
readable in the active light, dark, and OLED themes.

### Success Criteria

- The footer does not use white media-foreground tokens on the light footer surface.
- Supporting copy uses `textSecondary`; the sign-in action uses `primary`.
- Focused widget coverage locks both semantic style assignments.

### Scope

- Welcome sign-in footer colors (`welcome_screen.dart`) and its accessibility test.

### Non-Goals

- Do not alter hero media text, footer layout, typography, button geometry, navigation, authentication, or theme-token definitions.

## 2. Codebase Exploration

### Verified Evidence

- `WelcomeScreen` used `onMediaSecondary` and `onMediaPrimary` for its footer.
- Core defines those media roles as white/light white in all base themes — appropriate for the hero image but not the surface footer.
- Historical provenance: `99314ec05208b375c99254f103f35763c769ddd3`.
- Phase 3C recovery branch: `codex/github-stack-consolidation`.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Use normal surface text/link semantics in the footer | Approved | Corrects theme-aware contrast defect |

## 4. Architecture Design

Use `context.tioColors.textSecondary` for explanatory footer text and `context.tioColors.primary` for the `Log In` action. Hero content retains its media-specific colors.

## 5. Implementation Plan

- [x] Replace footer `onMediaSecondary` with `textSecondary`.
- [x] Replace footer `onMediaPrimary` with `primary` for Log In link.
- [x] Add focused light/dark theme semantic color assertions to `welcome_accessibility_test.dart`.
- [ ] Validation pending Phase 3C commit gate.

## 6. Quality Review

Pending Phase 3C full validation run.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/welcome-signin-footer-theme-contrast.md` (this file)
- `apps/features/welcome/lib/src/presentation/screen/welcome_screen.dart`
- `apps/app/test/app/welcome_accessibility_test.dart`

### Actual Behavior

The footer uses surface-aware text/link roles in place of image-media roles; hero media text remains unchanged.

**Current status:** RECOVERED — implementation complete; validation pending Phase 3C gate.
