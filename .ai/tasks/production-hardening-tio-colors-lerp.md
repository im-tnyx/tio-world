# Production Hardening — TioColors.lerp

Status: **AUDIT COMPLETE / IMPLEMENTATION REQUIRED**
Owner: #5 P2 item 16
Implementation PR: #50 (Draft/open/unmerged)
Audit date: 2026-08-25

Fresh audit head:

```text
5eb163730eb51a5834aeea74d51b311d55d82076
```

## Goal

Make the canonical `TioColors` ThemeExtension interpolate correctly during Material theme transitions without changing any approved palette/token values or theme ownership.

## Fresh finding

Current implementation in `apps/core/lib/src/theme/tokens/semantic/tio_colors.dart` is:

```dart
@override
TioColors lerp(ThemeExtension<TioColors>? other, double t) => this;
```

This is a reproducible defect: every animated theme transition keeps the source semantic color extension for the whole interpolation instead of blending toward the destination extension.

No focused `TioColors.lerp` regression exists on the current head.

## Owner decision

- `TioColors` remains the canonical semantic color ThemeExtension.
- Every `Color` field is interpolated with Flutter `Color.lerp`.
- `isDark` is a discrete semantic flag and switches at the midpoint (`t < 0.5` keeps source, otherwise destination).
- If `other` is not a `TioColors`, return the current extension as the standard fail-safe ThemeExtension behavior.
- No palette/token physical values change.
- No screen/widget-specific color logic is introduced.

## Implementation

- [ ] implement real interpolation for every `TioColors` Color field;
- [ ] use deterministic midpoint policy for `isDark`;
- [ ] preserve fail-safe behavior for a missing/incompatible extension;
- [ ] add focused endpoint/midpoint/all-field regression tests;
- [ ] keep existing light/dark/OLED/high-contrast token mappings unchanged;
- [ ] exact-head Flutter/Dart + Android CI green.

## Acceptance

1. `t=0` resolves source semantic colors.
2. `t=1` resolves destination semantic colors.
3. Intermediate `t` values match `Color.lerp` for every semantic color field.
4. `isDark` switches only at the documented midpoint.
5. Existing canonical palette/token contract tests remain green.
6. No Supabase/schema/auth/routing change.
7. PR #50 remains Draft/open/unmerged unless separately authorized.
