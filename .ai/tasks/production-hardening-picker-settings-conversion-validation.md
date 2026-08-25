# Production Hardening — Picker / Settings Conversion & Validation Edges

**Status:** Complete / Frozen
**Primary owner:** `tio_core` measurement contract + Settings presentation
**Tracking:** production hardening #5 item 19

## Global UI / Design-System Guardrail

No redesign is authorized. Preserve current picker/settings geometry, copy, controls, colors, spacing, and navigation. This slice may correct value formatting/input validation without restyling screens.

## 1. Discovery

### User Outcome

Profile Settings and measurement pickers must display and convert the same canonical metric values as the shared `tio_core` measurement contract, including feet/inches rollover boundaries.

### Success Criteria

- no duplicate kg↔lb or cm↔ft/in arithmetic remains in the audited Profile Settings / shared picker paths;
- feet/inches initialization/formatting never emits `12 in`;
- imperial height save accepts a canonical feet + inches pair and does not treat out-of-range inches as an independent valid component;
- canonical stored values remain kg/cm;
- existing picker ranges and visual baseline remain unchanged;
- focused regressions plus full Flutter/Dart + Android exact-SHA CI are green.

### Scope

- `apps/features/settings/lib/src/presentation/pages/profile_settings_page.dart`
- `apps/core/lib/src/ui/components/sheets/tio_height_picker_bottom_sheet.dart`
- `apps/core/lib/src/ui/components/sheets/tio_weight_picker_bottom_sheet.dart`
- focused existing tests for those surfaces

### Non-Goals

- no measurement-preference persistence/schema change;
- no change to canonical range policy (height 50–260 cm, weight 25–350 kg);
- no new validation/error visual treatment;
- no Settings redesign or unit-preference IA change;
- no nutrition/workout conversion work;
- no modification to already-correct core conversion constants/formulas unless a focused test proves a defect.

## 2. Codebase Exploration

### Verified Evidence

Audit head after item 18 closeout:

```text
f3ffc4139d87fa303b117bfb897688b93d641c88
```

Core was already correct and was reused without formula changes:

```text
MeasurementConverters.cmToFeetInches()
MeasurementConverters.feetInchesToCm()
MeasurementConverters.kgToLb()
MeasurementConverters.lbToKg()
```

Existing core regression already proved:

```text
MeasurementFormatters.formatHeight(182.88, HeightUnit.ftIn)
→ 6 ft 0 in
```

### Reproducible Findings

1. `ProfileSettingsPage._formattedHeight()` independently calculated feet with `floor()` and inches with remainder `round()`. Near a foot boundary it could render `5' 12"` instead of normalized `6' 0"`.
2. `TioHeightPickerBottomSheet.initState()` repeated the same floor/remainder rounding and could initialize its controls with `12 in`.
3. The ft/in picker parsed both components as arbitrary doubles and did not require inches to be within the canonical `0..11` component range before conversion.
4. `ProfileSettingsPage` and `TioWeightPickerBottomSheet` used a local `2.20462` pounds-per-kilogram factor instead of the shared core converter constant.
5. Picker tests verified basic render/save only and did not lock rollover or invalid imperial inch behavior.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Reuse `tio_core` conversion everywhere in this slice | Made | one canonical conversion owner already exists |
| Keep kg/cm as saved canonical values | Made | accepted measurement architecture |
| Imperial ft/in components are integer display/input components | Made | shared converter returns integer feet/inches and prevents rollover ambiguity |
| Reject invalid inch component by retaining the current canonical value | Made | preserves existing no-new-error-UI behavior while preventing malformed component save |
| Do not revisit unit preference persistence | Made | separate accepted #112 / measurement architecture |

## 4. Architecture Design

```text
ProfileSettingsPage / shared picker UI
        ↓
MeasurementConverters (tio_core)
        ↓
canonical cm / kg values
```

Settings presentation no longer owns conversion constants or ft/in normalization arithmetic in the audited paths.

## 5. Implementation Plan

- [x] replace Profile Settings manual height/weight conversion arithmetic with core converters;
- [x] initialize ft/in picker through `cmToFeetInches`;
- [x] save ft/in picker through `feetInchesToCm` using integer components;
- [x] reject non-canonical inch component (`< 0` or `> 11`) without adding new visual UI;
- [x] replace weight picker hardcoded factor with core converters;
- [x] add rollover regression for Profile Settings and Height picker;
- [x] add invalid-inch save regression;
- [x] add imperial weight-picker converter regression;
- [x] keep existing cm/kg/lb picker tests green;
- [x] run full exact-SHA Flutter/Dart + Android CI.

## 6. Quality Review

### Accepted runtime source/test checkpoint

```text
e0f3ebbcd618721a3768e989ce4521d978d4067a
Flutter CI #1973 / run 32843553269 ✅
Android Native CI #385 / run 32843553359 ✅

Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
Android debug APK/native compile ✅
```

### Review Findings and Resolution

- Scoped delta is exactly three production files and three focused test files.
- Profile Settings keeps the existing apostrophe/quote and `lbs` display vocabulary while using core conversion math.
- Height picker initializes rollover-safe integer components and refuses `12 in` as an independent inches component.
- Weight picker uses the same pounds-per-kilogram constant as the rest of `tio_core`.
- No visual structure, Supabase schema, persistence owner, auth, routing, or canonical kg/cm storage behavior changed.

## 7. Final Handoff

### Changed Files

```text
apps/core/lib/src/ui/components/sheets/tio_height_picker_bottom_sheet.dart
apps/core/lib/src/ui/components/sheets/tio_weight_picker_bottom_sheet.dart
apps/core/test/ui/components/tio_height_picker_bottom_sheet_test.dart
apps/core/test/ui/components/tio_weight_picker_bottom_sheet_test.dart
apps/features/settings/lib/src/presentation/pages/profile_settings_page.dart
apps/features/settings/test/presentation/profile_settings_page_test.dart
```

### Actual Behavior

- Profile Settings no longer produces `5' 12"` around foot rollover boundaries.
- Height picker opens with normalized feet/inches and retains the previous canonical height when an invalid `12 in` component is submitted.
- Height and weight conversion math is shared with `tio_core` rather than duplicated in Settings/pickers.
- Canonical values remain centimeters and kilograms.

### Known Limitations

This slice does not change account unit-preference persistence, cross-feature Nutrition/Workout unit presentation, or existing height/weight range policy.

### Final Status

`COMPLETE / FROZEN`
