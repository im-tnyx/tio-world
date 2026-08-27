# Core Units Module Rename

**Status:** SOURCE MIGRATION PASS / AFFECTED VALIDATION PASS / REPO-WIDE INHERITED AUTH BLOCKER  
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
MeasurementFormatters       → UnitFormatters
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

Validated application source head:

`2fd7222127150b63b21be804514bd4c043b18fd9`

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

## Executable validation evidence

Validation-only Draft PR #133 targeted `main` to trigger existing CI without retargeting stacked PR #132. Its validation commit `34b89337c83fd3f0a619c706b2d2669664b3ae6b` contains the same application source as #132 source head `2fd7222127150b63b21be804514bd4c043b18fd9`; the only extra change is validation workflow YAML.

Confirmed:

- repository-wide Flutter analyze: PASS
- repository-wide Dart analyze: PASS
- focused Issue #23 affected-package validation: PASS
  - App
  - Core
  - Onboarding
  - Profile
  - Settings
- App tests observed in serialized CI: 226 PASS
- Core tests observed in serialized CI: 112 PASS
- Account Setup tests observed before inherited blocker: 37 PASS
- Android Native CI: PASS
  - phone Android debug APK build PASS
  - Wear Android debug APK build PASS

Repository-wide serialized Flutter tests do not currently complete green because the inherited Auth stack has two unrelated failing tests:

```text
apps/features/auth/test/presentation/auth_field_visual_parity_test.dart
apps/features/auth/test/presentation/login_page_test.dart
```

Those two files are byte-identical between PR #131 base and PR #132, and neither file is changed by PR #132. Therefore they are recorded as an inherited repository-wide blocker, not as an Issue #23 regression. Do not mix unrelated Auth fixes into this units refactor.

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
- [x] Flutter/Dart analyze on source-identical validation tree
- [x] focused affected-package tests on source-identical validation tree
- [ ] repository-wide serialized Flutter tests green, blocked only by inherited Auth failures outside #23
- [x] Android phone debug build
- [x] Android Wear debug build
- [x] record executable evidence in Issue #23 / Draft PR #132 / tracker

## Final validation gates

```text
active obsolete src/measurement imports     0
obsolete public core class usages           0
temporary migration bridges/adapters        removed
serialized unit values changed              no
metric calculation behavior intentionally changed  no
Flutter/Dart analyze                        PASS
focused affected-package tests              PASS
Android phone debug build                   PASS
Android Wear debug build                    PASS
repository-wide Flutter tests               BLOCKED by 2 inherited Auth tests outside #23
```

## Scope boundary

Do not add the future `body_measurements` domain, Progress measurement history, calculation redesign, Auth #125 work, Account Setup work, or database changes in this task.

## Resume rule

If interrupted, resume from this tracker, Issue #23 and Draft PR #132. Issue #23 implementation and affected-package validation are complete. Only the repository-wide inherited Auth test blocker remains before claiming a completely green repository gate. Keep PR #132 Draft/open/unmerged until explicit owner authorization.

## Evidence sync note

This tracker update is documentation-only. It moves the PR head after application validation without changing application source, tests, dependencies, native code, or runtime behavior.
