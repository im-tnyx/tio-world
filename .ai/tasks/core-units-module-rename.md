# Core Units Module Rename

**Status:** ACTIVE — audit complete, source rename pending  
**Issue:** #23  
**Working branch:** `agent/core-units-module-rename`  
**Stack base:** PR #131 @ `d4e323ce7ef22cd2958756236f34f411bc87473d`  
**Owner:** `apps/core` unit semantics plus repository-wide consumers

## Outcome

Rename the current core `measurement` capability to `units` before a future real body-measurements domain is introduced. The current capability owns unit types, preferences, conversions and formatting, not body-measurement records.

```text
apps/core/lib/src/
├── units/                 # current unit semantics
├── body_measurements/     # future actual body-measurement domain
├── nutrition/
├── workout/
├── progress/
├── achievements/
├── streaks/
├── routing/
├── theme/
├── ui/
└── utils/                 # genuinely domain-independent helpers only
```

## Frozen invariants

- Preserve canonical metric storage/calculation behavior exactly.
- Preserve storage values exactly: `kg`, `lb`, `cm`, `ft_in`, `km`, `mi`, `ml`, `fl_oz`.
- Keep `WeightUnit`, `HeightUnit`, `DistanceUnit`, `VolumeUnit` enum names.
- No Supabase schema/data/config mutation.
- No UI behavior redesign.
- No permanent compatibility aliases after all consumers migrate.
- Do not move this capability into generic `utils` or `helpers`.
- PR stays Draft/open/unmerged until explicit owner authorization.

## Approved rename map

```text
src/measurement/measurement.dart       → src/units/units.dart
measurement_units.dart                 → unit_types.dart
measurement_unit_preferences.dart      → unit_preferences.dart
measurement_converters.dart            → unit_converters.dart
measurement_formatters.dart            → unit_formatters.dart

MeasurementUnitPreferences → UnitPreferences
MeasurementConverters      → UnitConverters
MeasurementFormatters      → UnitFormatters
```

## Audit findings

This is repository-wide, not a folder-only rename. Consumers exist in Core, App composition, Onboarding, Profile, Settings and tests. PR #50 also contains unit-related consumers, so this branch starts from PR #131, whose ancestry contains the current PR #50 head plus the Auth stack, instead of starting from `main`.

Known impact areas include `apps/core/lib/core.dart`, the shared Measurement Units editor, Onboarding draft/screens/mappers/controllers, Profile models/repositories, App-level unit persistence composition, Settings, and their tests.

## Execution checklist

- [x] confirm #23 future-domain rationale
- [x] repository-wide consumer audit
- [x] verify PR #131 as safe stack base
- [x] create dedicated branch
- [x] create durable tracker before source mutation
- [ ] rename physical module/folder/files
- [ ] rename public classes to `UnitPreferences`, `UnitConverters`, `UnitFormatters`
- [ ] update `core.dart` and internal imports
- [ ] migrate all app/feature consumers
- [ ] migrate tests and test paths where appropriate
- [ ] preserve serialized values exactly
- [ ] zero references to obsolete `src/measurement` path
- [ ] zero references to obsolete public class names
- [ ] Flutter/Dart analyze
- [ ] focused tests
- [ ] repository-wide serialized tests / CI
- [ ] Android debug build if required for final acceptance
- [ ] record final evidence in Issue #23 and Draft PR

## Validation gates

```text
obsolete src/measurement references    0
MeasurementUnitPreferences references  0
MeasurementConverters references       0
MeasurementFormatters references       0
serialized unit values changed         no
metric calculation behavior changed    no
Flutter analyze                         pass
Dart analyze                            pass
Flutter/Dart tests                      pass
```

Exact-head evidence that cannot actually execute remains pending and must not be inferred from older SHAs.

## Scope boundary

Do not add the future `body_measurements` domain, Progress measurement history, calculation redesign, Auth #125 work, Account Setup work, or database changes in this task.

## Resume rule

If interrupted, resume from this tracker and Issue #23. Re-run repository-wide zero-reference audit before removing old names or declaring completion.
