# Settings S0-B4 — Body & Weight Physical-Device QA Corrections

**Status:** Validated
**Primary owner:** `apps/features/settings` + shared `apps/core` weight wheel
**Affected platforms:** Flutter Android + iOS phone app

## Global UI / Design-System Guardrail

This correction slice follows `.ai/tasks/design-system-token-consolidation.md`,
`apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md`. The user has
explicitly approved the reported contrast, spacing, and haptic corrections; no
broader screen redesign or token-system change is authorized.

## 1. Discovery

### User Outcome

The Body & Weight editors remain readable and tactile on a physical device:
the selected wheel row is visible in light theme, manual entry is not crowded
against Save, and each changed Goal Pace slider step emits selection haptics.

### Success Criteria

- the shared weight-wheel selection pill contrasts with its raised sheet in
  light, dark, and OLED themes;
- the same shared fix reaches onboarding Current/Target Weight wheels;
- manual weight entry has governed additional space before Save without
  changing wheel-mode geometry;
- Goal Pace haptics fire once per changed snapped 0.1 kg/week value;
- the Settings row and editor use the approved product-facing `Weekly Goal`
  label while internal domain/API identifiers remain compatible;
- focused Core, Settings, and Onboarding validation passes.

### Scope

- `TioWeightWheel` selection-pill theme role;
- Body & Weight manual-entry spacing;
- Body & Weight Goal Pace slider haptics;
- Settings-only product-facing `Weekly Goal` label;
- focused regression tests and this task brief.

### Non-Goals

- changing DOB/height picker rendering;
- renaming internal Goal Pace domain/API identifiers or onboarding copy;
- changing persistence, Supabase, Body repository, routing, or goal math;
- marking PR #172 Ready or merging it.

## 2. Codebase Exploration

### Verified Evidence

- `TioColors.light.surface` and `surfaceRaised` are both white, so the previous
  `surface`-based translucent pill had no visible contrast on the sheet.
- `TioColors.surfaceVariant` is distinct from `surfaceRaised` in light, dark,
  OLED, and high-contrast schemes.
- onboarding Current/Target Weight already delegate to the shared
  `TioWeightWheel` introduced on PR #172.
- `DailyWellnessEditorSheet` already contributes `TioSpacing.md` before actions;
  the reported manual-entry gap needs a local additional `TioSpacing.lg` only
  in manual mode.
- onboarding `GoalPaceScreen` already uses `_lastVibratedPace` plus a `0.09`
  threshold to deduplicate `HapticFeedback.selectionClick()` at 0.1 steps.
- exact-head PR #172 baseline `5a860605` passed Flutter CI before these
  physical-device corrections; physical-device acceptance remains open.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Fix the three reported device defects | Approved | Explicit user-reported visual/tactile corrections | Product owner |
| Show `Weekly Goal` in Body & Weight Settings | Approved | Product owner confirmed the visible Settings rename after physical-device review; internal contracts remain unchanged | Product owner |

## 4. Architecture Design

### Chosen Approach

Use the existing runtime semantic color role and onboarding haptic pattern. Keep
spacing local to the manual editor branch because the reported defect does not
authorize wheel-mode geometry changes.

### Ownership and Data Flow

```text
Settings editor -> shared TioWeightWheel -> runtime TioColors
Settings Goal Pace Slider -> local snapped state -> platform selection haptic
```

### Alternative Rejected

- A new picker color token is unnecessary because `surfaceVariant` already
  expresses the contrasting surface role across every supported theme.
- Updating every drum picker would broaden this PR beyond its shared weight
  wheel and the reported Body & Weight/onboarding weight behavior.

### Failure and Accessibility States

- Haptics are supplemental; value text and slider state remain authoritative.
- Save/error behavior and keyboard inset handling remain unchanged.

## 5. Implementation Plan

- [x] Make the shared weight-wheel pill theme-safe and test light-theme role.
- [x] Add manual-only governed spacing and a geometry regression test.
- [x] Add deduplicated Goal Pace haptics and a platform-channel regression test.
- [x] Rename the visible Settings row/editor label to `Weekly Goal` and lock it with widget assertions.
- [x] Run focused format, analyze, tests, and `git diff --check`.

## 6. Quality Review

### Validation Run

```text
dart format (4 changed Dart files)                                      PASS
apps/core: flutter analyze                                               PASS
apps/core: flutter test test/ui/components/tio_weight_wheel_test.dart    1/1 PASS
apps/features/settings: flutter analyze                                  PASS
apps/features/settings:
  flutter test test/presentation/body_weight_settings_page_test.dart     38/38 PASS
apps/features/onboarding: flutter analyze                                PASS
apps/features/onboarding:
  flutter test test/presentation/body_goal_weight_wheel_regression_test.dart
                                                                          5/5 PASS
git diff --check                                                         PASS
```

### Review Findings and Resolution

- Diff review found no persistence, route, Supabase, or domain-contract change.
- The shared color-role correction is limited to `TioWeightWheel`; unrelated
  DOB and height drum pickers remain out of scope.
- Dependency resolution reported available newer packages and an existing
  root/core `uses-material-design` warning; neither changed this task's lockfiles
  or affected focused test/analyze outcomes.
- Product owner reported these defects from a physical-device review on
  2026-08-30. Re-verification of the corrected build on a physical device has
  NOT yet been performed. The confirmation-card/logout consistency follow-up is
  explicitly deferred to a separate scope and does not block this slice.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/settings-s0b4-body-weight-device-qa.md`
- `apps/core/lib/src/ui/components/sheets/tio_weight_wheel.dart`
- `apps/core/test/ui/components/tio_weight_wheel_test.dart`
- `apps/features/settings/lib/src/presentation/pages/body_weight_settings_page.dart`
- `apps/features/settings/test/presentation/body_weight_settings_page_test.dart`

### Actual Behavior

- Light theme now paints the shared weight-wheel selected row with the
  contrasting `surfaceVariant` semantic role.
- Manual weight entry receives `TioSpacing.lg` in addition to the sheet's
  existing action gap; wheel mode geometry is unchanged.
- Goal Pace emits one selection haptic per changed snapped slider value and
  suppresses duplicate callbacks for the same value.
- The Body & Weight row and editor now display `Weekly Goal`; internal
  `goal-pace` keys, `weeklyWeightChangeKg`, persistence, and onboarding remain
  unchanged.

### Known Limitations

Automated widget tests cannot prove motor intensity or OEM-specific haptic
behavior. Physical-device acceptance of the corrected build has NOT been
performed -- the product owner's 2026-08-30 device review is what produced
these four defect reports, and the resulting fixes have not been re-checked on
a device. Exact-head GitHub CI remains the publication check after the forward
commit.

### Final Status

`NEEDS PHYSICAL-DEVICE ACCEPTANCE` — focused automation and exact-head CI pass;
physical-device re-verification of these corrections is still required before
this slice can be considered accepted. Confirmation card/logout standardization
is a separate follow-up.
