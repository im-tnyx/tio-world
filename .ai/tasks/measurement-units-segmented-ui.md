# Measurement Units Segmented UI

**Status:** COMPLETE / FROZEN  
**Primary owner:** `tio_core` shared measurement preference editor  
**Affected platforms:** Flutter phone — Product Onboarding + Settings/Profile  
**Tracking issue:** #112  
**Explicit visual approval:** 2026-08-24 user-supplied references + approved Metric/Imperial/Custom contract

## Global UI / Design-System Guardrail

This slice intentionally changes the approved Measurement Units visual contract. Existing governed Tio theme/tokens remain the only visual source. The UI stays one shared core editor and no feature-local token bag or persistence field is authorized.

## 1. User Outcome

Measurement Units uses Metric/Imperial convenience presets at the top, then four independent compact unit rows. Mixed per-category choices expose a derived `Custom` preset state.

Final approved layout:

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

The top preset control is horizontally centered in the available content area. Metric/Imperial remain a balanced pair; when Custom appears, all three segments remain centered and balanced.

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

## 3. Final Implementation

Shared owner:

```text
apps/core/lib/src/ui/components/preferences/tio_measurement_unit_preferences_editor.dart
```

Consumers:

- Product Onboarding `MeasurementUnitsScreen`;
- Settings `MeasurementUnitsSettingsPage`.

The final polish replaces the previous right-biased `Alignment.centerRight` preset wrapper with centered alignment and adds a stable keyed preset-control boundary so focused widget coverage verifies the rendered segmented control remains centered in exact Metric/Imperial and mixed Custom states.

## 4. Scope Completed

- centered the top Metric/Imperial/Custom preset control;
- preserved balanced segment treatment;
- retained existing row interaction and responsive behavior;
- added focused widget coverage preventing regression back to right alignment;
- preserved selected semantics, save/failure behavior and all existing unit values.

## 5. Non-Goals / Guardrails

- no domain/model changes;
- no Supabase/schema migration;
- no canonical value conversion/storage change;
- no persisted `custom` or `measurement_system` field;
- no unrelated onboarding redesign;
- no feature-specific duplicate editor.

## 6. Final Validated Polish Checkpoint

```text
Accepted source SHA: 45311ef48cef18bf1f973d158048442a9b1e8bbd
Flutter CI #1781 / run 32716723775 ✅
Android Native CI #193 / run 32716723751 ✅

Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
Android debug APK/native compile ✅
```

The source checkpoint includes the centered preset implementation and its stable focused regression test. A transient prior test-only checkpoint failed because the test searched for the generic `SegmentedButton` type instead of the keyed rendered preset boundary; production source analysis was green. The test finder was corrected without changing the approved interaction or persistence contract.

## 7. Acceptance

- [x] Metric/Imperial segmented implementation exists.
- [x] mixed state derives Custom without persistence.
- [x] four independent unit rows use the shared editor.
- [x] Onboarding + Settings share one implementation.
- [x] compact-width / large-text behavior is overflow-safe.
- [x] selected semantics and Settings persistence behavior remain covered.
- [x] top preset selector is centered, not `Alignment.centerRight`.
- [x] Metric/Imperial are visually balanced as a two-segment control.
- [x] Metric/Imperial/Custom remain centered and balanced in mixed state.
- [x] focused layout regression test covers centered preset placement.
- [x] full Flutter/Dart + Android CI green on the exact polish SHA.

## 8. Final Status

`COMPLETE / FROZEN`

No schema or persistence work was required.
