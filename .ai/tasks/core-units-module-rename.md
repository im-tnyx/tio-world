# Core Units Module Rename

**Status:** SOURCE MIGRATION PASS / AFFECTED VALIDATION PASS / REPO-WIDE INHERITED AUTH BLOCKER  
**Issue:** #23  
**Working branch:** `agent/core-units-module-rename`  
**Stack base:** PR #131 @ `d4e323ce7ef22cd2958756236f34f411bc87473d`  
**Owner:** `apps/core` unit semantics plus repository-wide consumers

## Outcome

Rename the current core `measurement` capability to `units` before a future real body-measurements domain is introduced. The current capability owns unit types, preferences, conversions and formatting, not body-measurement records.

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

## Source migration

Completed:

- physical capability moved to `apps/core/lib/src/units/`
- canonical `UnitPreferences`, `UnitConverters`, `UnitFormatters` active
- App/Core/Onboarding/Profile/Settings consumers migrated
- temporary compatibility classes/adapters removed
- serialized storage values unchanged
- obsolete `src/measurement` additions: 0
- obsolete public core class additions: 0

Validated application source head:

`2fd7222127150b63b21be804514bd4c043b18fd9`

## Executable validation evidence

Validation-only Draft PR #133 targeted `main` to trigger CI without changing PR #132's stacked base. Validation commit `34b89337c83fd3f0a619c706b2d2669664b3ae6b` has source-identical application code to the validated #132 source head; its only extra change is CI workflow YAML.

Confirmed:

- repository-wide Flutter analyze: PASS
- repository-wide Dart analyze: PASS
- focused affected-package validation: PASS for App, Core, Onboarding, Profile, Settings
- App serialized tests observed: 226 PASS
- Core serialized tests observed: 112 PASS
- Account Setup serialized tests observed before blocker: 37 PASS
- Android phone debug APK build: PASS
- Android Wear debug APK build: PASS

Repository-wide serialized Flutter tests do not complete green because two inherited Auth tests fail:

```text
apps/features/auth/test/presentation/auth_field_visual_parity_test.dart
apps/features/auth/test/presentation/login_page_test.dart
```

Both failing files are byte-identical between PR #131 base and PR #132 and are not changed by #132. They are an inherited repository-wide blocker, not a units-refactor regression. Do not mix unrelated Auth fixes into #23.

## Checklist

- [x] future-domain rationale
- [x] repository-wide consumer audit
- [x] dedicated branch + tracker
- [x] physical module/file rename
- [x] public API rename
- [x] App/Core/Onboarding/Profile/Settings consumer migration
- [x] compatibility cleanup
- [x] zero-reference static audit
- [x] serialized unit values preserved
- [x] Flutter analyze PASS
- [x] Dart analyze PASS
- [x] affected-package focused tests PASS
- [x] Android phone debug build PASS
- [x] Android Wear debug build PASS
- [ ] repository-wide serialized Flutter tests fully green, blocked only by inherited Auth failures outside #23

## Resume rule

Issue #23 implementation and affected-package validation are complete. Only the inherited repository-wide Auth test blocker remains before claiming a fully green repository gate. Keep PR #132 Draft/open/unmerged until explicit owner authorization.

Tracker updates made after validation are documentation-only and do not change application source, tests, dependencies, native code, or runtime behavior.
