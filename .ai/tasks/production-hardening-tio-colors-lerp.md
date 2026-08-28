# Production Hardening — TioColors.lerp

Status: **COMPLETE / FROZEN**
Owner: #5 P2 item 16
Implementation PR: #50 (Draft/open/unmerged)
Audit date: 2026-08-25

Fresh audit head:

```text
5eb163730eb51a5834aeea74d51b311d55d82076
```

Accepted source/test checkpoint:

```text
2c2b619815750ffaabdea97b6e38da0988fa88dd
Flutter CI #1950 / run 32838046538 ✅
Android Native CI #362 / run 32838046610 ✅
```

## Goal

Make the canonical `TioColors` ThemeExtension interpolate correctly during Material theme transitions without changing any approved palette/token values or theme ownership.

## Fresh finding

The audited implementation was:

```dart
@override
TioColors lerp(ThemeExtension<TioColors>? other, double t) => this;
```

Every animated theme transition therefore kept the source semantic color extension instead of blending toward the destination extension. No focused `TioColors.lerp` regression existed.

## Final owner decision

- `TioColors` remains the canonical semantic color ThemeExtension.
- Every semantic `Color` field interpolates with Flutter `Color.lerp`.
- `isDark` is a discrete semantic flag and switches at the midpoint (`t < 0.5` keeps source, otherwise destination).
- Missing/incompatible destination extensions fail safely by returning the current extension.
- No palette/token physical values changed.
- No screen/widget-specific color logic was introduced.

## Implementation

- [x] implemented real interpolation for every `TioColors` Color field;
- [x] added deterministic midpoint policy for `isDark`;
- [x] preserved fail-safe behavior for a missing/incompatible extension;
- [x] added focused endpoint/midpoint/all-field regression tests;
- [x] preserved existing light/dark/OLED/high-contrast token mappings;
- [x] exact-head Flutter/Dart + Android CI green.

## Regression evidence

`apps/core/test/theme/tio_colors_lerp_test.dart` proves:
- `t=0` preserves every source semantic color;
- `t=1` resolves every destination semantic color;
- intermediate values match `Color.lerp` for all 21 semantic Color fields;
- `isDark` switches exactly at the documented midpoint;
- a missing destination returns the current extension.

Existing canonical theme/token contract tests remained green in the same full workspace run.

## Acceptance

1. [x] `t=0` resolves source semantic colors.
2. [x] `t=1` resolves destination semantic colors.
3. [x] Intermediate `t` values match `Color.lerp` for every semantic color field.
4. [x] `isDark` switches only at the documented midpoint.
5. [x] Existing canonical palette/token contract tests remain green.
6. [x] No Supabase/schema/auth/routing change.
7. [x] PR #50 remains Draft/open/unmerged unless separately authorized.
