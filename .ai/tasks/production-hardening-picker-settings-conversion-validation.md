# Production Hardening — Picker / Settings Conversion & Validation Edges

**Status:** In progress
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

Core is already correct and must be reused:

```text
MeasurementConverters.cmToFeetInches()
MeasurementConverters.feetInchesToCm()
MeasurementConverters.kgToLb()
MeasurementConverters.lbToKg()
MeasurementFormatters.formatHeight()
MeasurementFormatters.formatWeight()
```

Existing core regression already proves:

```text
MeasurementFormatters.formatHeight(182.88, HeightUnit.ftIn)
→ 6 ft 0 in
```

### Reproducible Findings

1. `ProfileSettingsPage._formattedHeight()` independently calculates feet with `floor()` and inches with remainder `round()`. Near a foot boundary (for example ~71.6 total inches), it can render `5' 12"` instead of normalized `6' 0"`.
2. `TioHeightPickerBottomSheet.initState()` repeats the same floor/remainder rounding and can initialize its controls with `12 in`.
3. The ft/in picker parses both components as arbitrary doubles and does not require inches to be within the canonical `0..11` component range before conversion.
4. `ProfileSettingsPage` and `TioWeightPickerBottomSheet` use a local `2.20462` pounds-per-kilogram factor instead of the shared core converter constant.
5. Current picker tests verify basic render/save only; they do not lock the rollover boundary or invalid imperial inch component.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Reuse `tio_core` conversion/formatting everywhere in this slice | Made | one canonical conversion owner already exists |
| Keep kg/cm as saved canonical values | Made | accepted measurement architecture |
| Imperial ft/in components are integer display/input components | Made | shared converter returns integer feet/inches and prevents rollover ambiguity |
| Reject invalid inch component by retaining the current canonical value | Made | preserves existing no-new-error-UI behavior while preventing malformed component save |
| Do not revisit unit preference persistence | Made | separate accepted #112 / measurement architecture |

## 4. Architecture Design

```text
ProfileSettingsPage / shared picker UI
        ↓
MeasurementFormatters / MeasurementConverters (tio_core)
        ↓
canonical cm / kg values
```

Settings presentation should not own conversion constants or arithmetic.

## 5. Implementation Plan

- [ ] replace Profile Settings manual height/weight formatting with core formatters;
- [ ] initialize ft/in picker through `cmToFeetInches`;
- [ ] save ft/in picker through `feetInchesToCm` using integer components;
- [ ] constrain/reject non-canonical inch component (`< 0` or `> 11`) without adding new visual UI;
- [ ] replace weight picker hardcoded factor with core converters;
- [ ] add rollover regression for Profile Settings and Height picker;
- [ ] add invalid-inch save regression;
- [ ] keep existing cm/kg/lb picker tests green;
- [ ] run full exact-SHA Flutter/Dart + Android CI.

## 6. Quality Review

Pending.

## 7. Final Handoff

Pending.
