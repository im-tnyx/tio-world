# Core Units Module Rename

**Status:** SOURCE MIGRATION PASS / EXECUTABLE PENDING  
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
- No permanent compatibility aliases/wrappers after consumer migration.
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

Default-branch GitHub code search is historical for this stacked branch, so current-branch files and the PR diff are source truth. The final static audit distinguishes obsolete core class symbols from valid product/domain names such as `MeasurementUnitsSettingsPage`, `MeasurementUnitPreferencesRepository`, and `updateMeasurementUnitPreferences`.

## Completed source checkpoints

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

Unit enums remain unchanged.

### Runtime consumer migration

Canonical helper APIs are used by:

- shared Height/Weight pickers;
- Onboarding Height / Current Weight / Target Weight;
- Goal Pace;
- Profile display;
- Profile Settings.

Canonical `UnitPreferences` is used by:

- shared Measurement Units editor;
- `ProfileSetupData`;
- canonical `UserProfileData`;
- Profile preference repository interface + in-memory/Supabase implementations;
- Supabase canonical `user_profiles.unit_preferences` decode/write path;
- `ProfileOnboardingDraft`;
- Onboarding Measurement Units screen;
- `OnboardingController.updateMeasurementUnitPreferences`;
- Profile/Targets renderers directly;
- draft DTO decode path;
- Settings Measurement Units page;
- App router metric fallback;
- focused Core/Onboarding/Profile/Settings tests migrated in this task.

The draft DTO and Profile `unit_preferences` serialized keys/values remain exactly the same.

### Compatibility cleanup

Removed from active code:

- `MeasurementUnitPreferences` compatibility class;
- `MeasurementConverters` compatibility class;
- `MeasurementFormatters` compatibility class;
- temporary renderer adapters;
- temporary bridge-equivalence test coverage.

No compatibility bridge remains in `apps/core/lib/src/units/`.

## Static zero-reference audit

Source checkpoint:

`de539e57a4bac135bd472d3cd93a949593e5d150`

The PR diff and known default-branch candidate paths were audited against the current branch after migration.

Result for active Dart source/tests:

```text
obsolete src/measurement imports/exports       0 current additions
exact MeasurementUnitPreferences class usage   0 current additions
exact MeasurementConverters class usage        0 current additions
exact MeasurementFormatters class usage        0 current additions
temporary compatibility classes                removed
temporary renderer adapters                    removed
```

Historical task/tracker text may intentionally mention the obsolete names when documenting the rename. Product/domain identifiers containing “Measurement Units” are not part of the public-core-class rename target.

Static diff review also preserves these storage values unchanged:

```text
kg
lb
cm
ft_in
km
mi
ml
fl_oz
```

No Supabase schema/data/config mutation was performed for #23.

## Executable validation status

For exact source head `de539e57a4bac135bd472d3cd93a949593e5d150`:

- GitHub combined status checks: none available.
- PR-triggered workflow runs: none available.
- Flutter/Dart analyze: not yet evidenced on this head.
- focused tests: not yet evidenced on this head.
- repository-wide serialized tests / CI: not yet evidenced.
- Android debug build: not yet evidenced on this head.

Do not infer executable success from the static migration audit or from older PR #131 validation.

## Execution checklist

- [x] confirm #23 future-domain rationale
- [x] repository-wide consumer audit
- [x] verify PR #131 as safe stack base
- [x] create dedicated branch + durable tracker
- [x] rename physical module/folder/files
- [x] introduce canonical `UnitPreferences`, `UnitConverters`, `UnitFormatters`
- [x] repair stale deleted-path picker imports
- [x] migrate helper consumers to `UnitConverters` / `UnitFormatters`
- [x] migrate Profile model/repository graph to `UnitPreferences`
- [x] migrate Onboarding draft/screen/controller graph to `UnitPreferences`
- [x] remove temporary renderer adapters
- [x] migrate draft DTO decode constructor to `UnitPreferences`
- [x] migrate Settings Measurement Units page + focused tests
- [x] migrate App router fallback to `UnitPreferences.metric`
- [x] remove `MeasurementConverters` compatibility bridge
- [x] remove `MeasurementFormatters` compatibility bridge
- [x] remove final `MeasurementUnitPreferences` compatibility bridge
- [x] remove bridge-specific test coverage
- [x] preserve serialized unit values in source/storage contracts
- [x] static active-source audit shows no obsolete `src/measurement` additions
- [x] static active-source audit shows no obsolete public core class additions
- [ ] Flutter/Dart analyze on accepted source head
- [ ] focused tests on accepted source head
- [ ] repository-wide serialized tests / CI
- [ ] Android debug build if required for final acceptance
- [ ] record executable evidence in Issue #23 and Draft PR

## Final validation gates

```text
active obsolete src/measurement imports     0
obsolete public core class usages           0
temporary migration bridges/adapters        removed
serialized unit values changed              no
metric calculation behavior intentionally changed  no
Flutter/Dart analyze                        pending
focused tests                               pending
repository-wide tests / CI                  pending
Android debug build                         pending if required
```

## Scope boundary

Do not add the future `body_measurements` domain, Progress measurement history, calculation redesign, Auth #125 work, Account Setup work, or database changes in this task.

## Resume rule

If interrupted, resume from this tracker, Issue #23 and Draft PR #132. Source migration is complete. Next work is executable validation only unless a real analyzer/test failure demonstrates a required source fix. Keep PR #132 Draft/open/unmerged until explicit owner authorization.
