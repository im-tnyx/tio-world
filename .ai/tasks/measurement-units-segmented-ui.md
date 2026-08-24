# Measurement Units Segmented UI

**Status:** ACTIVE — implementation validated, visual polish follow-up pending  
**Primary owner:** `tio_core` shared measurement preference editor  
**Affected platforms:** Flutter phone — Product Onboarding + Settings/Profile  
**Tracking issue:** #112  
**Explicit visual approval:** 2026-08-24 user-supplied references + approved Metric/Imperial/Custom contract

## Global UI / Design-System Guardrail

This slice intentionally changes the approved Measurement Units visual contract. Existing governed Tio theme/tokens remain the only visual source. The UI stays one shared core editor and no feature-local token bag or persistence field is authorized.

## 1. User Outcome

Measurement Units uses Metric/Imperial convenience presets at the top, then four independent compact unit rows. Mixed per-category choices expose a derived `Custom` preset state.

Approved visual refinement after device review:

```text
            [ Metric | Imperial ]

Weight          [ kg     | lb    ]
Height          [ cm     | ft/in ]
Distance        [ km     | miles ]
Liquid volume   [ mL/L   | fl oz ]
```

When mixed:

```text
       [ Metric | Imperial | Custom ]
                              selected
```

The top preset control must be horizontally centered in the available content area. It must not be right-aligned. Metric/Imperial should read as a balanced pair; when Custom appears, all three segments remain visually balanced and centered.

## 2. Interaction Contract

- Exact Metric shows Metric + Imperial only, Metric selected.
- Exact Imperial shows Metric + Imperial only, Imperial selected.
- Selecting a preset applies all four independent preferences.
- Any mixed combination reveals selected Custom.
- Custom is derived only; it is never persisted.
- Returning exactly to Metric or Imperial hides Custom automatically.
- Rows remain label-left + compact segmented selector-right when width permits.
- Narrow width / large text may stack safely without overflow.
- Correct liquid volume option is `fl oz`.

## 3. Verified Current Implementation

Shared owner:

```text
apps/core/lib/src/ui/components/preferences/tio_measurement_unit_preferences_editor.dart
```

Consumers:

- Product Onboarding `MeasurementUnitsScreen`;
- Settings `MeasurementUnitsSettingsPage`.

Current implementation already has correct derived Custom behavior and shared persistence boundaries. Device review found one visual mismatch: the preset selector is wrapped in `Align(alignment: Alignment.centerRight)`, which produces the observed right-biased layout instead of the approved centered composition.

## 4. Scope

- center the top Metric/Imperial/Custom preset control;
- preserve equal/balanced segment treatment;
- retain the existing row interaction and responsive behavior;
- add/update widget coverage so the preset selector cannot regress back to right alignment;
- preserve selected semantics, save/failure behavior and all existing unit values.

## 5. Non-Goals / Guardrails

- no domain/model changes;
- no Supabase/schema migration;
- no canonical value conversion/storage change;
- no persisted `custom` or `measurement_system` field;
- no unrelated onboarding redesign;
- no feature-specific duplicate editor.

## 6. Previously Validated Implementation Checkpoint

```text
Implementation SHA: b8b99478e9dc9fcb1c2f762c99d12e8e7eaa9467
Flutter CI #1775 / run 32707113818 ✅
Android Native CI #187 / run 32707113803 ✅

Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
Android debug APK/native compile ✅
```

A later docs-only checkpoint also reached green CI, but #112 is intentionally reopened for the approved visual centering polish and must receive a new exact-green checkpoint after that source change.

## 7. Acceptance

- [x] Metric/Imperial segmented implementation exists.
- [x] mixed state derives Custom without persistence.
- [x] four independent unit rows use the shared editor.
- [x] Onboarding + Settings share one implementation.
- [x] compact-width / large-text behavior is overflow-safe.
- [x] selected semantics and Settings persistence behavior remain covered.
- [ ] top preset selector is centered, not `Alignment.centerRight`.
- [ ] Metric/Imperial are visually balanced as a two-segment control.
- [ ] Metric/Imperial/Custom remain centered and balanced in mixed state.
- [ ] focused layout regression test covers centered preset placement.
- [ ] full Flutter/Dart + Android CI green on the exact polish SHA.

## 8. Final Status Rule

Do not close #112 until the centered preset polish is implemented and validated on one exact source SHA. No schema or persistence work is required.