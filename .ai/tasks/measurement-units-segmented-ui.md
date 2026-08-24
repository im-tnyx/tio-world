# Measurement Units Segmented UI

**Status:** In progress  
**Primary owner:** `tio_core` shared measurement preference editor  
**Affected platforms:** Flutter phone — Product Onboarding + Settings/Profile  
**Tracking issue:** #112  
**Explicit visual approval:** 2026-08-24 user-supplied reference + approved Metric/Imperial/Custom contract

## Global UI / Design-System Guardrail

This slice intentionally changes the approved Measurement Units visual contract. It follows `.ai/tasks/design-system-token-consolidation.md` and `apps/core/lib/src/theme/README.md`: use existing Tio theme/tokens, keep one shared core editor, and do not create a feature-local token bag.

## 1. Discovery

### User Outcome

Measurement Units should feel like a compact settings selector: Metric/Imperial presets at the top, then label-left segmented unit rows. A mixed per-category selection automatically exposes a derived `Custom` preset state.

### Success Criteria

- Exact Metric/Imperial state shows two preset segments only.
- Mixed state shows selected `Custom` as a third derived segment.
- Custom disappears automatically when choices return exactly to a preset.
- Weight, Height, Distance, and Liquid volume use compact row selectors.
- Onboarding and Settings render the same shared editor.
- Accessibility selected semantics and compact/large-text safety remain covered.

### Scope

- `apps/core/lib/src/ui/components/preferences/tio_measurement_unit_preferences_editor.dart`
- focused Onboarding/Settings widget tests only as required

### Non-Goals

- no domain/model changes;
- no Supabase/schema migration;
- no canonical value conversion/storage change;
- no persisted `custom`/`measurement_system` flag;
- no unrelated screen redesign.

## 2. Codebase Exploration

### Verified Evidence

- Current shared editor uses large `TioButton.primary/secondary` pairs for presets and each category.
- `MeasurementUnitPreferences` already owns four independent typed preferences and exposes `isMetricPreset` / `isImperialPreset`.
- `MeasurementUnitsScreen` and `MeasurementUnitsSettingsPage` already consume the same shared editor.
- Existing widget tests cover preset changes, mixed persistence, selected semantics, and Settings save failure.
- Existing Tio theme contract provides governed `TioSpacing`, `TioRadius`, `TioStroke`, `TioSize`, typography roles, and runtime `context.tioColors`.

### Existing Pattern to Follow

Use a reusable core widget composition with Material semantics/interaction and governed Tio theme values. Do not add a new token family unless an existing governed primitive/semantic role is genuinely insufficient.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Top preset starts Metric / Imperial only | Approved | matches requested compact UX | Product |
| Mixed choices reveal Custom | Approved | preserves independent preferences without coercion | Product/Core |
| Custom is derived, never persisted | Approved | four fields remain durable truth | Core |
| Rows use label-left + segmented pill-right | Approved | matches supplied reference direction | Product |
| Volume uses `fl oz`, not reference-image `Lb` | Approved | correct unit semantics | Core |
| Small/large-text layout may stack | Approved | avoids overflow while preserving hierarchy | UI |

## 4. Architecture Design

### Chosen Approach

Keep `TioMeasurementUnitPreferencesEditor` stateless. Derive `isCustom = !preferences.isMetricPreset && !preferences.isImperialPreset` every build. Build one private segmented-control primitive inside the shared editor and one responsive label/selector row composition.

### Ownership and Data Flow

```text
Onboarding / Settings
  → TioMeasurementUnitPreferencesEditor
  → MeasurementUnitPreferences
  → existing persistence owners
```

### Alternative Rejected

Persisting `Custom` or a rigid measurement-system flag is rejected because mixed independent choices are already first-class durable state.

### Failure and Accessibility States

- each segment exposes selected semantics;
- tap targets remain accessible;
- large text/compact width must not overflow;
- Settings save error/retry behavior remains unchanged because persistence surface is untouched.

## 5. Implementation Plan

- [ ] Replace large preset buttons with compact segmented preset selector.
- [ ] Add derived Custom segment only for mixed state.
- [ ] Replace four large button pairs with responsive label-left segmented rows.
- [ ] Use Tio theme/tokens only for visual values.
- [ ] Update focused Onboarding + Settings tests for Custom and semantics.
- [ ] Add compact-width / large-text overflow regression test.
- [ ] Run exact-head Flutter/Dart + Android CI.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

Pending implementation.

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Pending.

### Known Limitations

None expected beyond existing measurement preference feature scope.

### Final Status

`PARTIAL`
