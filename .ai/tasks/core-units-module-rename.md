# Core Units Module Rename

**Status:** ACTIVE — physical rename complete; canonical public unit APIs live; primary runtime preference graph is migrating behind temporary compatibility bridges  
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

## Audit findings

This is repository-wide, not a folder-only rename. Consumers exist in Core, App composition, Onboarding, Profile, Settings and tests. PR #50 also contains unit-related consumers, so this branch starts from PR #131, whose ancestry contains the current PR #50 head plus the Auth stack, instead of starting from `main`.

Default-branch GitHub code search is historical for this stacked branch, so current-branch files/directories are treated as source truth before mutation. That audit already caught one stale historical path (`supabase_profile_setup_repository.dart`) that no longer exists on the active branch and two real stale picker imports that did exist and were fixed.

## Checkpoints

### Physical capability rename

Completed in:

`7e8d7d994f721ade073c82d2a6f47c75b815dafb`

- `apps/core/lib/src/measurement/` moved to `apps/core/lib/src/units/`.
- Core file names now match the approved `unit_*` map.
- `core.dart` exports `src/units/units.dart`.
- shared editor direct import moved to `../../../units/units.dart`.
- storage values and behavior remained unchanged.

### Canonical public names

Canonical classes are now defined as:

```text
UnitPreferences
UnitConverters
UnitFormatters
```

Old `Measurement*` names remain only as explicitly deprecated temporary migration bridges so repository-wide consumers can be moved in bounded passes without leaving the branch uncompilable. These bridges are not an accepted final state and must be deleted after consumer migration and zero-reference audit.

Core canonical tests moved from `test/measurement/measurement_test.dart` to `test/units/units_test.dart` and exercise the new names plus temporary bridge equivalence.

Canonical API checkpoint:

`40bd4753f78c87d9aee5db7d8af73ce2396e6316`

### Helper consumer migration

Migrated:

- Onboarding Height display → `UnitFormatters`.
- Onboarding Current Weight display → `UnitFormatters`.
- Onboarding Target Weight display/difference → `UnitFormatters` + `UnitConverters`.
- shared Height picker → `units/units.dart` + `UnitConverters`.
- shared Weight picker → `units/units.dart` + `UnitConverters`.

The picker audit caught stale direct imports left behind by the first physical-folder move; those imports now point to the canonical `units` capability rather than the removed `measurement` path.

Known remaining helper consumers: Goal Pace, Profile display and Profile Settings.

### UnitPreferences runtime graph

Migrated to `UnitPreferences`:

- shared `TioMeasurementUnitPreferencesEditor` contract;
- `ProfileSetupData`;
- canonical `UserProfileData`;
- `MeasurementUnitPreferencesRepository` method parameter;
- `InMemoryProfileSetupRepository` implementation/copy helper;
- `SupabaseMeasurementUnitPreferencesRepository` implementation;
- `SupabaseUserProfileRepository` decode/persistence type while preserving exact JSON keys/values;
- `ProfileOnboardingDraft` constructor/field/copy/resolver;
- Product Onboarding `MeasurementUnitsScreen`;
- Settings `MeasurementUnitsSettingsPage`.

The large `OnboardingController` still has one `MeasurementUnitPreferences` method signature. Until that giant file is migrated safely, Profile and Targets renderers use explicit temporary adapters that round-trip the already canonical `UnitPreferences.toJson()` into the deprecated bridge. These adapters preserve exact values and are explicitly temporary; both must be removed together with the controller old signature before final acceptance.

The draft DTO mapper still constructs the deprecated preference bridge on decode; its serialized keys/values remain unchanged and it is pending a safe mapper pass.

Current source checkpoint before this tracker update:

`8cc6e8769f828bffc3388f060cd00709682bcc03`

PR-triggered workflow runs on that SHA: none. No analyzer/test/build green state is inferred.

## Execution checklist

- [x] confirm #23 future-domain rationale
- [x] repository-wide consumer audit
- [x] verify PR #131 as safe stack base
- [x] create dedicated branch
- [x] create durable tracker before source mutation
- [x] rename physical module/folder/files
- [x] introduce canonical `UnitPreferences`, `UnitConverters`, `UnitFormatters`
- [x] migrate first bounded helper consumers and repair stale picker imports
- [x] migrate primary Profile models/repositories to `UnitPreferences`
- [x] migrate primary Onboarding draft/screen contract to `UnitPreferences`
- [x] migrate Settings Measurement Units page to `UnitPreferences`
- [ ] migrate remaining helper consumers to `UnitConverters` / `UnitFormatters`
- [ ] migrate `OnboardingController` unit preference signature and remove renderer adapters
- [ ] migrate draft DTO decode constructor to `UnitPreferences`
- [ ] migrate App router fallback and remaining app/feature consumers
- [ ] migrate remaining tests and historical task/docs references where required for final zero-reference acceptance
- [ ] remove temporary deprecated `Measurement*` migration bridges
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

Repository/domain names such as `MeasurementUnitsSettingsPage` may remain where they describe the user-facing product concept “Measurement Units”; the zero-reference gate targets the obsolete core capability path and the three explicitly renamed public core class symbols.

Exact-head evidence that cannot actually execute remains pending and must not be inferred from older SHAs.

## Scope boundary

Do not add the future `body_measurements` domain, Progress measurement history, calculation redesign, Auth #125 work, Account Setup work, or database changes in this task.

## Resume rule

If interrupted, resume from this tracker, Issue #23 and Draft PR #132. Re-read current branch source before relying on default-branch code search. Re-run repository-wide zero-reference audit before removing old names or declaring completion.
