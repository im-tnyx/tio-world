# S0-B2 — Default Glass Size (local-only correction)

**Status:** In progress — S0-B2 editor-sheet consistency polish underway on Draft PR #170
**Primary owner:** `apps/features/settings`
**Affected platforms:** Flutter phone (Android/iOS), device-local preference
**Trackers:** TNYX-130 (In Progress); parent TNYX-128 (unchanged, In Progress); TNYX-118 (unchanged)
**Correction starting HEAD:** `19b885d88344bf9fe497776a5b721ba74afe7681`
**Branch:** `codex/settings-s0b2-glass-size`
**Draft PR:** [#170](https://github.com/im-tnyx/tio-world/pull/170)

## 1. Corrected outcome

Default Glass Size is a **local-device convenience preference**, not account
health data. It remains Settings-owned and is independent of Water Goal and
Volume Unit. No hydration logging is delivered.

### Classification

| State | Evidence |
|---|---|
| CURRENT | Settings UI/editor, `SharedPreferencesAsync` persistence, real 250 ml default, Reset to Default, explicit account-boundary reset, UnitPreferences display conversion, Daily Wellness composition, and Draft PR #170 exist. The Supabase table is absent. |
| PLANNED | No persistence or UI work in this slice; only CI and physical-device acceptance remain. |
| DUPLICATE | Supabase Hydration adapter and its client/data path. |
| STALE | Account sync, nullable/Not set/Clear semantics, dedicated table, and migration claims. |
| FUTURE | Hydration logging, +1 glass, cloud sync, wearable support, server/backend work. |

## 2. Frozen contract

- Owner: `apps/features/settings`.
- Storage: `SharedPreferencesAsync`, integer key `default_glass_size_ml`;
  never user-scoped.
- Effective missing/corrupt/cleared value: **250 ml**.
- Presets: 200 / 250 / 300 / 350 / 500 ml.
- Custom: 50–2000 ml inclusive, 10 ml increments; invalid input is rejected
  without clamping or rounding.
- UI: row **Glass Size**, editor **Default Glass Size**, help
  **Amount logged when you add one glass of water.**, and
  **Reset to Default**.
- Restart/restored session retains a saved override. Explicit successful logout,
  account-setup/onboarding exit, account deletion, and new explicit login reset
  the local value to 250 ml. Failed sign-out does not clear it.
- Water Goal stays in its existing Wellness repository; Volume Unit is
  display-only. #112 Units editor remains frozen.

## 3. Ownership and boundaries

```text
Daily Wellness UI
  -> HydrationPreferencesEditorController
  -> HydrationPreferencesRepository
  -> SharedPreferencesHydrationPreferencesRepository
  -> SharedPreferencesAsync(default_glass_size_ml)

apps/app
  -> repository/provider composition
  -> explicit login/logout/account-end boundary only
```

Out of scope: Progress, Nutrition, Profile, shared ownership, a new hydration
package, `WellnessTargetsData`, `user_wellness_targets`,
`user_app_preferences`, any Supabase table/migration/RLS, hydration logging,
watch and backend work.

The earlier account-synced table decision is superseded during Draft PR review
before merge. The unmerged local migration
`20260829043204_create_user_hydration_preferences.sql` is removed. The remote
draft migration history is stale and the manually removed zero-row table remains
absent; **remote repair is a separate explicitly authorized operation**.

## 4. Corrected implementation

- [x] Replace nullable domain/repository contract with non-null 250 ml default.
- [x] Replace Settings Supabase adapter with a Settings-local
  `SharedPreferencesAsync` adapter.
- [x] Replace Clear/Not set UI with Reset to Default/250 ml behavior.
- [x] Remove the unmerged local Supabase migration and old adapter.
- [x] Limit app composition to local provider and explicit account boundaries.
- [x] Update focused local/domain/editor/route/session coverage.
- [x] Update ownership, ADR, Settings and decision/status documentation.
- [x] Run fresh configured Flutter validation and scope audit.
- [ ] Update Linear/PR, commit forward correction, push and wait for exact-head CI.

## 5. Source boundary

Allowed changes:

- `.ai/DECISIONS.md`, `.ai/IMPLEMENTATION_STATUS.md`, this brief
- `apps/features/settings/lib/settings.dart`
- `apps/features/settings/pubspec.yaml` and tracked lockfile only if pub resolution changes it
- Settings Hydration domain, local data adapter, editor, Glass Size sheet, Daily
  Wellness page and their focused tests
- `apps/app/lib/app/network_providers.dart`, `router.dart`, the narrow
  `hydration_preferences_session_boundary.dart`, and focused app tests
- `docs/screens/settings.md`, `docs/MODULE_OWNERSHIP.md`, ADR-0008/0009 and ADR index
- deletion only of `supabase/migrations/20260829043204_create_user_hydration_preferences.sql`

Must not change: Units editor/domain/repository, Progress Wellness repository,
Profile, Nutrition, Workout, Onboarding behavior, Auth feature implementation,
shared/core UI, router paths, schema/migrations other than the specified
deletion, or remote Supabase state.

## 6. Validation

Local validation on the correction worktree passed:

```text
apps/features/settings: flutter pub get PASS; analyze PASS; full test PASS (123)
apps/app: analyze PASS; full test PASS (246)
apps/core: analyze PASS; full test PASS (114)
apps/features/progress: wellness_targets_repository_test PASS (11)
apps/features/profile: supabase_measurement_unit_preferences_repository_test PASS (2)
apps/features/onboarding: measurement_units_screen_test PASS (1);
water_unit_converter_test PASS (5)
git diff --check: PASS
```

`G:\dev\flutter-sdk\bin\dart.bat format` was run for the touched Dart files.
Existing line wrapping was then preserved where the SDK formatter would have
created unrelated churn. Scope audit confirms the frozen core Units editor and
Progress/Profile/Nutrition/Workout source are unchanged. Physical-device
acceptance remains pending after exact-head CI; no remote migration repair
occurs in this checkpoint.

### Actual changed files (29)

```text
.ai/DECISIONS.md
.ai/IMPLEMENTATION_STATUS.md
.ai/tasks/settings-s0b2-default-glass-size.md
apps/app/lib/app/hydration_preferences_session_boundary.dart
apps/app/lib/app/network_providers.dart
apps/app/lib/app/router.dart
apps/app/test/app/app_mode_router_test.dart
apps/app/test/app/daily_wellness_route_test.dart
apps/app/test/app/hydration_preferences_session_boundary_test.dart
apps/app/test/app/onboarding_root_logout_router_test.dart
apps/features/settings/lib/settings.dart
apps/features/settings/lib/src/data/shared_preferences_hydration_preferences_repository.dart
apps/features/settings/lib/src/data/supabase_hydration_preferences_repository.dart (deleted)
apps/features/settings/lib/src/domain/hydration_preferences.dart
apps/features/settings/lib/src/presentation/hydration_preferences_editor_controller.dart
apps/features/settings/lib/src/presentation/pages/daily_wellness_settings_page.dart
apps/features/settings/lib/src/presentation/widgets/glass_size_bottom_sheet.dart
apps/features/settings/pubspec.lock
apps/features/settings/pubspec.yaml
apps/features/settings/test/data/hydration_preferences_repository_test.dart
apps/features/settings/test/domain/hydration_preferences_test.dart
apps/features/settings/test/presentation/daily_wellness_settings_page_test.dart
apps/features/settings/test/presentation/hydration_preferences_editor_controller_test.dart
docs/MODULE_OWNERSHIP.md
docs/adr/0008-settings-hydration-preferences-owner.md
docs/adr/0009-settings-local-default-glass-size.md
docs/adr/README.md
docs/screens/settings.md
supabase/migrations/20260829043204_create_user_hydration_preferences.sql (deleted)
```

## 7. Publication boundary

Create one forward correction commit; do not amend the published history. Keep
PR #170 Draft. Do not merge, close #170, mark TNYX-130 Done, change TNYX-128 or
TNYX-118, start the next slice, or repair remote Supabase migration history.

## 8. Editor-sheet consistency polish — 2026-08-29

### Discovery and verified evidence

- Starting branch/HEAD: `codex/settings-s0b2-glass-size` /
  `a1c4df249ef5d019e53211701cf48bfbb66b22bc`; working tree clean.
- Draft PR #170 is open against `main` at that same head. The prior exact-head
  Flutter CI run `33242485506` passed; a new commit requires a new CI result.
- Step Goal and Water Goal currently draw separate `surfaceRaised` modal
  compositions with a manually duplicated handle. Glass Size draws a
  `surface` modal containing Core `TioSheet`, whose inner Material also uses
  `surface`; this is the visible flat/merged mismatch.
- Flutter's route-level drag dismissal can bypass a child `PopScope`. The
  existing Glass `PopScope(canPop: !_editor.isSaving)` continues to guard
  back/barrier dismissal while an awaited Save is in flight, but cannot make
  route-level drag safe by itself.

### Frozen decision

Create one Settings-local `DailyWellnessEditorSheet` and use it for Step Goal,
Water Goal and Glass Size. Every one uses a transparent `showModalBottomSheet`
with a single visible `surfaceRaised` Material, `TioRadius.lg`, `SafeArea`, a
visible drag handle, shared header/help/action spacing and keyboard inset
handling. The route-level drag stays disabled because Flutter can bypass a
child `PopScope`; the Settings-local handle dismisses idle drafts itself and is
disabled while Glass Save is awaited.

The addendum supersedes the earlier suggestion to consume/nest `TioSheet`.
`apps/core/lib/src/ui/components/sheets/tio_sheet.dart` stays unchanged: its
global `surface` contract is correct for its existing consumers, while this
Settings-only visual composition has no cross-feature reuse evidence.

Step and Water sliders retain their current canonical ranges, snapping,
Clear/Set semantics and formatting, while emitting exactly one
`HapticFeedback.selectionClick()` only for a changed snapped value. Glass
keeps its presets, Custom validation, 250 ml default, Reset, awaited save,
duplicate-submit guard and retry behavior.

### Current / stale / planned classification

| Classification | Evidence |
|---|---|
| CURRENT | MOVEMENT/HYDRATION/SLEEP grouping; Step/Water sliders; Glass presets/Custom; Sleep snapped haptics; local-only Glass persistence. |
| STALE | Duplicated Step/Water sheet chrome and Glass's nested `TioSheet`/`surface` composition; missing Step/Water snapped-value haptics. |
| PLANNED | Settings-local shared editor shell and focused widget coverage. |
| FUTURE-NOT YET APPROVED | Glass slider, generic Core goal-slider/sheet, hydration logging, cloud sync and wearable sync. |

### Allowlist and non-goals

Allowed for this polish only:

```text
.ai/tasks/settings-s0b2-default-glass-size.md
apps/features/settings/lib/src/presentation/pages/daily_wellness_settings_page.dart
apps/features/settings/lib/src/presentation/widgets/daily_wellness_editor_sheet.dart (new)
apps/features/settings/lib/src/presentation/widgets/glass_size_bottom_sheet.dart
apps/features/settings/test/presentation/daily_wellness_settings_page_test.dart
```

Must not change: Core source including `tio_sheet.dart`, HydrationPreferences
domain/repository/session behavior, Wellness targets model/repository,
Supabase/schema/migration history, #112 Units editor, Sleep implementation,
routes/navigation, App Mode, Profile, Nutrition, Workout or Home.

### Validation plan

```text
G:\dev\flutter-sdk\bin\flutter.bat analyze   (apps/features/settings)
G:\dev\flutter-sdk\bin\flutter.bat test      (apps/features/settings)
G:\dev\flutter-sdk\bin\flutter.bat analyze   (apps/app)
G:\dev\flutter-sdk\bin\flutter.bat test      (apps/app)
git diff --check
```

Add coverage for the common shell, transparent modal and `surfaceRaised`
surface, idle handle drag dismissal, in-flight Glass dismissal guard, and one
haptic per changed snapped Step/Water value.

### Implementation and validation evidence

Implemented only the listed allowlist:

- `DailyWellnessEditorSheet` is Settings-owned and is used by Step Goal,
  Water Goal and Glass Size. Its outer modal is `TioPalette.transparent`; it
  exposes one `surfaceRaised` Material with `TioRadius.lg`, SafeArea, shared
  header/help/action spacing and a functional local handle.
- Route-level drag is disabled deliberately. The local handle dismisses only
  an idle sheet; it does nothing while Glass awaits Save, avoiding the Flutter
  route drag/`PopScope` race.
- Step and Water retain their ranges/divisions and emit one selection haptic
  only after a changed snapped draft value. Glass no longer consumes/nests
  `TioSheet`; its persistence, 250 ml default and editor controller are
  unchanged.

Completed before the SDK lock was discovered:

```text
G:\dev\flutter-sdk\bin\flutter.bat test \
  test/presentation/daily_wellness_settings_page_test.dart
  (apps/features/settings) — PASS, 58 tests
G:\dev\flutter-sdk\bin\flutter.bat analyze
  (apps/features/settings) — PASS, No issues found
G:\dev\flutter-sdk\bin\flutter.bat analyze
  (apps/app) — PASS, No issues found
```

Fresh full Settings/App test attempts cannot acquire the configured Flutter
SDK lock: an existing Android Studio `flutter.bat daemon` process owns the
shared cache lock. It is user-owned and was not terminated. Direct cached-tool
invocation fails on `bin/cache/lockfile`; direct `dart test` attempted a
package fetch and then failed on restricted telemetry-file access. These are
tooling limitations, not passing validation. New exact-head Flutter CI remains
the required full-suite gate after publication.
