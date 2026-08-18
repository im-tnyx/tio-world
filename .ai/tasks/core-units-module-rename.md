# Core Units Module Rename

**Status:** Planned  
**Issue:** #23  
**Scope:** `apps/core/lib/src/measurement/**`, public core exports, direct consumers/tests  
**Blocked by:** current bounded design-system Slice A work reaching a safe validation boundary

## Outcome

Rename the current `measurement` capability to a future-safe `units` capability because the existing module owns unit types/preferences/conversion/formatting, not body-measurement records.

Reserve `body_measurements` for the future actual body-measurement domain and keep future nutrition/workout/progress/achievement/streak business logic inside their owning capabilities rather than a generic helper bucket.

## Target Architecture

```text
apps/core/lib/src/
├── units/
│   ├── units.dart
│   ├── unit_types.dart
│   ├── unit_preferences.dart
│   ├── unit_converters.dart
│   └── unit_formatters.dart
├── body_measurements/   # future actual body-measurement capability
├── nutrition/           # future shared domain logic where justified
├── workout/
├── progress/
├── achievements/
├── streaks/
├── routing/
├── theme/
├── ui/
└── utils/               # only genuinely domain-independent helpers
```

## Architecture Rules

- Do **not** move the current module wholesale into `utils/` or `helpers/`.
- `utils/` is reserved for domain-independent helpers such as date/string/parsing/validation/extensions.
- Business/domain helpers remain with their capability: nutrition calculators in nutrition, streak rules in streaks, body-measurement logic in body_measurements, etc.
- Unit conversion, unit display formatting and account unit preferences stay cohesive under `units`.
- Canonical metric storage/calculation behavior must remain unchanged.
- Storage values (`kg`, `lb`, `cm`, `ft_in`, `km`, `mi`, `ml`, `fl_oz`) must remain byte-for-byte compatible unless separately migrated.
- Public behavior must remain equivalent throughout the rename.
- Transitional aliases/exports may exist only while consumers migrate; final state requires zero references and deletion of obsolete measurement names/paths.

## Proposed Rename Map

```text
src/measurement/measurement.dart          → src/units/units.dart
measurement_units.dart                    → unit_types.dart
measurement_unit_preferences.dart         → unit_preferences.dart
measurement_converters.dart               → unit_converters.dart
measurement_formatters.dart               → unit_formatters.dart

MeasurementUnitPreferences                → UnitPreferences
MeasurementConverters                     → UnitConverters
MeasurementFormatters                     → UnitFormatters
```

Keep unit enum names unless a separate audit finds a stronger reason to change them:

```text
WeightUnit
HeightUnit
DistanceUnit
VolumeUnit
```

## Implementation Checklist

### U1 — Audit

- [ ] Inventory all imports/exports/usages of `src/measurement`, `measurement.dart`, `MeasurementUnitPreferences`, `MeasurementConverters`, and `MeasurementFormatters`.
- [ ] Inventory tests and task/docs references.
- [ ] Confirm no persistence/schema semantics depend on Dart class/file names.

### U2 — Create canonical units capability

- [ ] Add `src/units/units.dart` barrel.
- [ ] Add/move typed unit definitions to `unit_types.dart`.
- [ ] Add/move preferences to `unit_preferences.dart`.
- [ ] Add/move conversion logic to `unit_converters.dart`.
- [ ] Add/move display formatting to `unit_formatters.dart`.
- [ ] Update `apps/core/lib/core.dart` to export `src/units/units.dart`.

### U3 — Consumer migration

- [ ] Migrate Onboarding consumers.
- [ ] Migrate Profile consumers/repositories.
- [ ] Migrate Settings consumers.
- [ ] Migrate reusable core UI consumers.
- [ ] Migrate tests.
- [ ] Update relevant architecture/task documentation.

### U4 — Cleanup

- [ ] Repository-wide zero-reference audit for obsolete `src/measurement` path.
- [ ] Zero-reference audit for `MeasurementUnitPreferences` after rename.
- [ ] Zero-reference audit for `MeasurementConverters` after rename.
- [ ] Zero-reference audit for `MeasurementFormatters` after rename.
- [ ] Delete obsolete measurement files/barrels/compatibility exports once zero-ref.
- [ ] Do not leave permanent compatibility facades.

### U5 — Validation

- [ ] Unit conversion round-trip tests remain unchanged and green.
- [ ] Preference JSON/storage compatibility tests remain green.
- [ ] Onboarding/Profile/Settings measurement-unit tests remain green.
- [ ] Flutter analyze/tests pass.
- [ ] Dart analyze/tests pass.
- [ ] Required GitHub CI passes on the final cleanup head.

## Non-Goals

- Do not implement body-measurement history/models in this refactor.
- Do not redesign Settings measurement-unit UI.
- Do not change Supabase measurement-unit storage values or canonical metric numeric fields.
- Do not add generic `nutrition_helper.dart`, `workout_helper.dart`, `streak_helper.dart`, etc. under `utils/`.
- Do not bundle unrelated feature-domain architecture migrations into this rename.
