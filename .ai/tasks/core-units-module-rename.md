# Core Units Module Rename

**Status:** ACTIVE — core capability and primary runtime graph migrated; final `UnitPreferences` bridge cleanup + zero-reference/validation gates pending  
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
- No permanent compatibility aliases/wrappers after all consumers migrate.
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

## Audit rule

This is repository-wide, not a folder-only rename. Consumers exist in Core, App composition, Onboarding, Profile, Settings and tests. PR #50 unit consumers are included through the PR #131 stack base.

Default-branch GitHub code search is historical for this stacked branch, so current-branch files/directories are source truth before mutation. This already prevented acting on one retired historical Profile repository and caught real stale picker imports after the folder move.

## Completed checkpoints

### Physical capability rename

`7e8d7d994f721ade073c82d2a6f47c75b815dafb`

- `apps/core/lib/src/measurement/` moved to `apps/core/lib/src/units/`.
- Core file names use the approved `unit_*` map.
- `core.dart` exports `src/units/units.dart`.
- shared direct imports moved to the `units` capability.

### Canonical public APIs

Canonical public classes:

```text
UnitPreferences
UnitConverters
UnitFormatters
```

Unit enums and serialized storage values remain unchanged.

### Runtime consumer migration

Canonical helper APIs are now used by:

- shared Height/Weight pickers;
- Onboarding Height / Current Weight / Target Weight;
- Goal Pace;
- Profile display;
- Profile Settings.

Canonical `UnitPreferences` is now used by:

- shared Measurement Units editor;
- `ProfileSetupData`;
- canonical `UserProfileData`;
- Profile preference repository interface + in-memory/Supabase implementations;
- Supabase canonical `user_profiles.unit_preferences` decode/write path;
- `ProfileOnboardingDraft`;
- Onboarding Measurement Units screen;
- `OnboardingController.updateMeasurementUnitPreferences`;
- Profile/Targets renderers directly, with temporary adapters removed;
- draft DTO decode path;
- Settings Measurement Units page;
- focused Onboarding/Profile/Settings tests migrated so far.

The draft DTO serialized keys and values remain exactly the same.

### Compatibility bridge cleanup

Removed:

- `MeasurementConverters` compatibility class;
- `MeasurementFormatters` compatibility class;
- their temporary bridge-equivalence tests.

Still intentionally present:

- `MeasurementUnitPreferences` compatibility class only.

Current known runtime blocker for removing the last preference bridge:

```text
apps/app/lib/app/router.dart
profileData?.unitPreferences ?? MeasurementUnitPreferences.metric
```

This router is a large file, so the one-line migration must be performed from verified full current source rather than by blind overwrite.

Core `units_test.dart` still contains one temporary preference-bridge test while that final bridge remains.

## Current checkpoint

Latest source head before this tracker-only update:

`210ca8b876f7ebfc9f5da262505af5ae2d16fa4c`

At this checkpoint:

- `MeasurementConverters` bridge: removed
- `MeasurementFormatters` bridge: removed
- Onboarding controller adapter bridge: removed
- draft DTO preference adapter: removed
- `MeasurementUnitPreferences` bridge: still pending App router migration
- no Supabase/schema/data mutation
- no executable green state claimed yet

## Execution checklist

- [x] confirm #23 future-domain rationale
- [x] repository-wide consumer audit
- [x] verify PR #131 as safe stack base
- [x] create dedicated branch + durable tracker
- [x] rename physical module/folder/files
- [x] introduce canonical `UnitPreferences`, `UnitConverters`, `UnitFormatters`
- [x] repair stale deleted-path picker imports
- [x] migrate helper consumers to `UnitConverters` / `UnitFormatters`
- [x] migrate primary Profile model/repository graph to `UnitPreferences`
- [x] migrate primary Onboarding draft/screen/controller graph to `UnitPreferences`
- [x] remove temporary renderer adapters
- [x] migrate draft DTO decode constructor to `UnitPreferences`
- [x] migrate Settings Measurement Units page + focused tests
- [x] remove `MeasurementConverters` compatibility bridge
- [x] remove `MeasurementFormatters` compatibility bridge
- [ ] migrate App router fallback to `UnitPreferences.metric`
- [ ] migrate any remaining `MeasurementUnitPreferences` test/docs/source refs required by final zero-reference gate
- [ ] remove final `MeasurementUnitPreferences` compatibility bridge
- [ ] preserve serialized values exactly
- [ ] zero references to obsolete `src/measurement` path/imports
- [ ] zero symbol references to obsolete public class names
- [ ] Flutter/Dart analyze
- [ ] focused tests
- [ ] repository-wide serialized tests / CI
- [ ] Android debug build if required for final acceptance
- [ ] record final evidence in Issue #23 and Draft PR

## Validation gates

```text
obsolete src/measurement references    0
MeasurementUnitPreferences symbol refs 0
MeasurementConverters symbol refs      0
MeasurementFormatters symbol refs       0
temporary migration bridges/adapters    removed
serialized unit values changed          no
metric calculation behavior changed     no
Flutter analyze                          pass
Dart analyze                             pass
Flutter/Dart tests                       pass
```

Repository/product names such as `MeasurementUnitsSettingsPage` may remain because they describe the user-facing concept “Measurement Units”. The zero-reference gate targets the obsolete core capability path and the three explicitly renamed public core class symbols.

Exact-head evidence that cannot actually execute remains pending and must not be inferred from older SHAs.

## Scope boundary

Do not add the future `body_measurements` domain, Progress measurement history, calculation redesign, Auth #125 work, Account Setup work, or database changes in this task.

## Resume rule

If interrupted, resume from this tracker, Issue #23 and Draft PR #132. Re-read current branch source before relying on default-branch code search. Finish App router migration before removing the final preference bridge, then run repository-wide zero-reference and executable validation gates before declaring completion.
