# Measurement Units Segmented UI

**Status:** Validated  
**Primary owner:** `tio_core` shared measurement preference editor  
**Affected platforms:** Flutter phone — Product Onboarding + Settings/Profile  
**Tracking issue:** #112  
**Explicit visual approval:** 2026-08-24 user-supplied reference + approved Metric/Imperial/Custom contract

## Global UI / Design-System Guardrail

This slice intentionally changes the approved Measurement Units visual contract. It follows `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md`: existing governed Tio theme/tokens are reused, the UI remains one shared core editor, and no feature-local token bag was added.

## 1. Discovery

### User Outcome

Measurement Units now uses a compact selector: Metric/Imperial presets at the top, then label-left segmented unit rows. A mixed per-category selection automatically exposes a derived `Custom` preset state.

### Success Criteria

- Exact Metric/Imperial state shows two preset segments only.
- Mixed state shows selected `Custom` as a third derived segment.
- Custom disappears automatically when choices return exactly to a preset.
- Weight, Height, Distance, and Liquid volume use compact row selectors.
- Onboarding and Settings render the same shared editor.
- Accessibility selected semantics and compact/large-text safety remain covered.

### Scope

- `apps/core/lib/src/ui/components/preferences/tio_measurement_unit_preferences_editor.dart`
- `apps/features/onboarding/test/presentation/measurement_units_screen_test.dart`
- `apps/features/settings/test/presentation/measurement_units_settings_page_test.dart`

### Non-Goals

- no domain/model changes;
- no Supabase/schema migration;
- no canonical value conversion/storage change;
- no persisted `custom`/`measurement_system` flag;
- no unrelated screen redesign.

## 2. Codebase Exploration

### Verified Evidence

- The previous shared editor used large `TioButton.primary/secondary` pairs for presets and each category.
- `MeasurementUnitPreferences` already owns four independent typed preferences and exposes `isMetricPreset` / `isImperialPreset`.
- `MeasurementUnitsScreen` and `MeasurementUnitsSettingsPage` already consume the same shared editor.
- Existing widget tests already covered preset changes, mixed persistence, selected semantics, and Settings save failure.
- Tio theme provides governed `TioSpacing`, `TioRadius`, `TioStroke`, `TioSize`, typography roles, and runtime `context.tioColors`.

### Existing Pattern Followed

The shared editor now uses Material `SegmentedButton` within core, styled only through governed Tio theme/tokens. No new design token family was required.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Top preset starts Metric / Imperial only | Approved + implemented | matches requested compact UX | Product |
| Mixed choices reveal Custom | Approved + implemented | preserves independent preferences without coercion | Product/Core |
| Custom is derived, never persisted | Approved + implemented | four fields remain durable truth | Core |
| Rows use label-left + segmented pill-right | Approved + implemented | matches supplied reference direction | Product |
| Volume uses `fl oz`, not reference-image `Lb` | Approved + implemented | correct unit semantics | Core |
| Small/large-text layout may stack | Approved + implemented | Wrap prevents narrow-layout overflow | UI |

## 4. Architecture Design

### Chosen Approach

`TioMeasurementUnitPreferencesEditor` stays stateless. `Custom` is derived as `!preferences.isMetricPreset && !preferences.isImperialPreset` every build. A private generic segmented-control composition renders both the preset selector and typed unit selectors. Responsive rows use `Wrap`, preserving label-left/control-right when space permits and stacking safely when it does not.

### Ownership and Data Flow

```text
Onboarding / Settings
  → TioMeasurementUnitPreferencesEditor
  → MeasurementUnitPreferences
  → existing persistence owners
```

### Alternative Rejected

Persisting `Custom` or a rigid measurement-system flag remains rejected because mixed independent choices are first-class durable state.

### Failure and Accessibility States

- Material segmented controls retain selected semantics;
- existing stable selector keys remain available;
- compact 320dp + 1.6x text scaling is widget-tested for overflow;
- Settings save failure/retry behavior remains unchanged because persistence is untouched.

## 5. Implementation Plan

- [x] Replace large preset buttons with compact segmented preset selector.
- [x] Add derived Custom segment only for mixed state.
- [x] Replace four large button pairs with responsive label-left segmented rows.
- [x] Use Tio theme/tokens only for visual values.
- [x] Update focused Onboarding + Settings tests for Custom and semantics.
- [x] Add compact-width / large-text overflow regression test.
- [x] Run exact implementation-head Flutter/Dart + Android CI.

## 6. Quality Review

### Validation Run

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

### Review Findings and Resolution

- No analyzer/compiler regression.
- Custom state remains derived and reversible.
- Existing Settings save path remains unchanged.
- Compact/large-text test passes with no overflow exception.
- No schema/domain/persistence changes were introduced.

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/measurement-units-segmented-ui.md
apps/core/lib/src/ui/components/preferences/tio_measurement_unit_preferences_editor.dart
apps/features/onboarding/test/presentation/measurement_units_screen_test.dart
apps/features/settings/test/presentation/measurement_units_settings_page_test.dart
```

### Actual Behavior

```text
Exact Metric   → [ Metric selected | Imperial ]
Exact Imperial → [ Metric | Imperial selected ]
Mixed units    → [ Metric | Imperial | Custom selected ]

Weight        [ kg | lb ]
Height        [ cm | ft / in ]
Distance      [ km | miles ]
Liquid volume [ mL / L | fl oz ]
```

Returning all four choices exactly to Metric or Imperial automatically hides Custom and selects the matching preset.

### Known Limitations

This slice does not add new unit types or change measurement conversion semantics; it only changes the approved selector UI/interaction.

### Final Status

`PASS`
