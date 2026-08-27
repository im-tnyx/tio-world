# Core Units Module Rename

**Status:** SOURCE MIGRATION PASS / FULL REPOSITORY VALIDATION PASS WITH AUTH TEST ALIGNMENT  
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

Validated Issue #23 application source checkpoint:

`2fd7222127150b63b21be804514bd4c043b18fd9`

Later #132 commits are tracker/documentation-only unless otherwise recorded.

## Executable validation evidence

### Issue #23 focused validation

Validation-only Draft PR #133 proved the units refactor itself and was closed without merge.

Confirmed:

- repository-wide Flutter analyze: PASS
- repository-wide Dart analyze: PASS
- focused affected-package validation: PASS for App, Core, Onboarding, Profile, Settings
- App serialized tests observed: 226 PASS
- Core serialized tests observed: 112 PASS
- Account Setup serialized tests observed before inherited blocker: 37 PASS
- Android phone debug APK build: PASS
- Android Wear debug APK build: PASS

That first full serialized gate stopped only on inherited Auth presentation tests that were byte-identical between PR #131 and PR #132.

### Full repository gate after isolated Auth test alignment

The inherited Auth test assumptions were fixed separately in Draft PR #134, with no production Auth behavior change.

Validation-only Draft PR #136 then composed:

- PR #132 current tree `a3d87b645bc36946dd9c37fa9188eba237c0359a`
- the two validated Auth test-only source changes from PR #134

Combined validation head:

`d48e3ee403b7283189022c7479a333165ad7e813`

Confirmed on that composition:

- [x] repository-wide Flutter analyze PASS
- [x] repository-wide Dart analyze PASS
- [x] repository-wide serialized Flutter tests PASS
- [x] repository-wide Dart tests PASS
- [x] Android phone debug APK PASS
- [x] Android Wear debug APK PASS

This establishes that Issue #23 has no remaining repository-wide regression once the independently tracked Auth test alignment is present. PR #134 remains a separate Draft dependency/test-alignment change and is not mixed into PR #132.

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
- [x] repository-wide serialized Flutter tests PASS on #132 + isolated #134 test alignment
- [x] repository-wide Dart tests PASS on #132 + isolated #134 test alignment
- [x] Android phone debug build PASS
- [x] Android Wear debug build PASS

## Resume rule

Issue #23 implementation and executable validation are complete. No additional units-refactor code work is pending. Keep PR #132 Draft/open/unmerged until explicit owner authorization. Keep the separate Auth test alignment tracked in PR #134; do not copy those Auth changes into #132.

Tracker updates made after validation are documentation-only and do not change application source, tests, dependencies, native code, or runtime behavior.
