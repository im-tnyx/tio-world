# Settings S0-A — Truthfulness, Units IA and Capability Gating

**Status:** In progress — IMPLEMENTED; bounded review and real-device acceptance passed; Draft PR publication authorized; merge pending.

**Primary owner:** `apps/features/settings`; `apps/app` owns route composition.

**Affected platforms:** Flutter phone, Android + iOS.

**Audit date:** 2026-08-28.

**Frozen current main SHA:** `7d4590780f48b9c236a80089d9132e2314f5554c`.

**Implementation starting HEAD:** `7d4590780f48b9c236a80089d9132e2314f5554c`.

**Implementation branch:** `codex/settings-s0a-truthfulness-units`.

**Pre-publication implementation/review HEAD:** `7d4590780f48b9c236a80089d9132e2314f5554c` (reviewed uncommitted changes).

Fresh preflight: local/live main still matches the audit; all relevant tracked
source is unchanged. Only this previously created untracked brief was present.
The user authorized the exact S0-A allowlist and subsequently authorized its
commit, push and Draft PR. Merge and tracker closure remain unauthorized.
The Flutter SDK configured by the repository's Android `local.properties` is
available (Flutter 3.44.6, Dart 3.12.2); no tooling installation is needed.
Baseline Settings/Units/Theme tests: 6 passed before production edits.

## Global UI / Design-System Guardrail

Follow root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/workflow.md`,
`.ai/tasks/design-system-token-consolidation.md` and
`apps/core/lib/src/theme/README.md`. Prefer existing components through
`package:tio_core/core.dart`. The root AGENTS visual-preservation rule governs
this slice; historical token-normalization allowances do not authorize visual
changes here.

Only the frozen row visibility, Units placement and truthful copy changes below
were implemented. Preserve existing colors, spacing,
typography, icons, card/tile geometry, assets and motion. No shared component or
token redesign. Matching pre-edit/post-edit widget layout checks cover light/dark,
390x844 at text scale 1 and 320x844 at text scale 1.6. No device screenshots or
goldens were captured; these checks do not claim pixel-level device acceptance.

## 1. Discovery

### Sources and snapshot

- Parent: [Linear TNYX-118](https://linear.app/tnyx/issue/TNYX-118/s0-app-settings-pre-implementation-audit-ia-and-ownership-readiness).
- Frozen child: [Linear TNYX-127](https://linear.app/tnyx/issue/TNYX-127/s0-a-settings-truthfulness-units-ia-and-capability-gating), Backlog; description, relations and comments read (no comments).
- Implementation tracker: [GitHub #167](https://github.com/im-tnyx/tio-world/issues/167), OPEN; description and comments read (no comments).
- Frozen dependency: [GitHub #112](https://github.com/im-tnyx/tio-world/issues/112), CLOSED / COMPLETE / FROZEN, and [Measurement Units brief](measurement-units-segmented-ui.md).
- Current documentation: `docs/screens/settings.md`; relevant architecture,
  ownership, development/setup, roadmap, Supabase strategy and AI workflow context.
- Local `main`, cached `origin/main` and live GitHub `refs/heads/main` matched the
  frozen SHA. Working tree was clean before this brief. One local worktree on
  `main`; no open GitHub PRs at audit time. No checkout, fetch, pull, commit,
  branch deletion or external tracker mutation was performed for this audit.
- #112 still describes PR #50 as draft/open/unmerged. The live PR is **MERGED**
  at `7adaadfdc5fe06986aba05abbff191a0d2f3ea22` (2026-08-28). Its old status text
  is stale; it is not an unmerged dependency. Do not rewrite #112 or its accepted
  UI checkpoint to reconcile this wording.

### Outcome and scope

Implement one slice that shows only real Settings capabilities and moves the
existing Units entry into App Preferences. The initial audit created this brief
only. Subsequent explicit user authorization permitted the frozen allowlist;
the implementation and local verification results are recorded below. Schema,
persistence-owner changes, merge, tracker closure and S0-B remain unauthorized.

### Non-goals

No new Units implementation/storage; no Home, Nutrition, Workout, Body/weight,
Wellness, Auth/password, Subscription, Watch, notifications, calendar, language,
accessibility or Font Style implementation. TNYX-118's broader Typography/Font
Style and global-preference audit is deferred, not declared complete by S0-A.
Nutrition remains TNYX-63; Workout TNYX-87; entitlement TNYX-124; notification
delivery TNYX-125; password semantics GitHub #34. Do not enable placeholder
destinations or move domain decisions into Settings.

## 2. Codebase Exploration

### Frozen pre-S0-A Settings IA and wiring

This section records source at the audited/starting SHA, not the implemented
working tree. The resulting runtime IA is in section 4.

`SettingsPage` is at `/settings`, reached from Profile. At baseline it rendered all
11 rows below, in this order across six sections. Evidence:
`apps/features/settings/lib/src/presentation/pages/settings_page.dart:104` and
`apps/app/lib/app/router.dart:662`. "Wired" means the app router supplies a real
callback; it does not certify every destination's production acceptance.

| Current section | Exact row label | Current router wiring | S0-A action |
|---|---|---|---|
| ACCOUNT & PROFILE | Profile Settings | `onProfileSettingsPressed` pushes `/settings/profile` -> `ProfileSettingsRoute` | Keep |
| ACCOUNT & PROFILE | Manage Subscription | `onManageSubscriptionPressed` omitted/null | Hide |
| ACCOUNT & PROFILE | Reset Password | `onResetPasswordPressed` omitted/null | Hide; do not wire login recovery as authenticated Change Password |
| ACCOUNT & PROFILE | Account Settings | `onAccountSettingsPressed` pushes `/settings/account` -> `AccountSettingsPage` | Keep existing owner callbacks |
| WORKOUT & WEARABLES | Workout Settings | `onWorkoutPressed` omitted/null | Hide |
| WORKOUT & WEARABLES | Wear OS / Watch Settings | `onWearOsPressed` omitted/null | Hide |
| NUTRITION | Nutrition & Diet | `onNutritionPressed` omitted/null | Hide |
| PREFERENCES | App Preferences | `onAppSettingsPressed` pushes `/settings/app` -> `AppSettingsPage` | Keep; correct subtitle |
| PREFERENCES | Measurement Units | `onMeasurementUnitsPressed` pushes `/settings/measurement-units` | Move entry into App Preferences |
| ABOUT | About Tio | `onAboutPressed` omitted/null | Hide |
| SESSION | Log Out | Confirmation dialog -> `authSessionRepositoryProvider.signOut()` -> `/auth` | Keep; preserve confirmation/cancel behavior |

There are **five wired rows and six unwired rows**. Null callbacks disable the
`InkWell`, but `_SettingsTile` still renders the normal colors and chevron. It
does not hide unsupported rows or their sections.

The root App Preferences subtitle is exactly
`Theme, sound & haptics, alerts & calendar`. Actual `/settings/app` has app-bar
title **App Settings** and only:

1. **App Mode** (`app-settings-app-mode-entry`): current Workout/Nutrition/Hybrid
   label, pushes `/settings/app-mode`.
2. **Theme** (`app-settings-theme-entry`): current System/Light/Dark/OLED label,
   opens `showThemeSelectionBottomSheet` with title **Appearance**.

`AppSettingsPage` currently has no Units callback/row. If the selected App Mode
is null, its router builder returns `SizedBox.shrink()`; this pre-existing state
is not changed by an IA move. All Settings routes use `rootNavigatorKey` and
`ChromePolicy.fullScreen`; Settings is not a bottom tab.

### Existing Units ownership, hydration and persistence

| Layer | Verified current owner / behavior |
|---|---|
| Product scope | App-global display/input preference, reused across features; moving its navigation does not move its storage owner |
| Value object | `apps/core/lib/src/units/unit_preferences.dart`: `UnitPreferences`, four independent enums, `toJson()` with `weight`, `height`, `distance`, `volume`; no stored preset |
| Shared editor | `apps/core/lib/src/ui/components/preferences/tio_measurement_unit_preferences_editor.dart`: `TioMeasurementUnitPreferencesEditor` |
| Settings UI | `apps/features/settings/lib/src/presentation/pages/measurement_units_settings_page.dart`: draft state, Save, retryable failure; current title `Measurement Units` |
| Route/hydration | `apps/app/lib/app/router.dart:680`: `profileDataProvider`, loading indicator when unresolved without data, then `profileData?.unitPreferences ?? UnitPreferences.metric` |
| Composition | `apps/app/lib/app/settings_persistence_providers.dart`: `measurementUnitPreferencesRepositoryProvider`; Supabase adapter when client exists; otherwise compatible `profileSetupRepositoryProvider` fallback or null |
| Narrow interface | `apps/features/profile/lib/src/domain/repositories/measurement_unit_preferences_repository.dart`: `MeasurementUnitPreferencesRepository.updateMeasurementUnitPreferences` |
| Adapter | `apps/features/profile/lib/src/data/repositories/supabase_measurement_unit_preferences_repository.dart`: reads canonical Profile, fails if missing, copies other fields and updates units through `UserProfileRepository.upsert` |
| Canonical storage | `apps/features/profile/lib/src/data/repositories/supabase_user_profile_repository.dart`: `public.user_profiles.unit_preferences`, current authenticated `user_id`; JSONB schema in `supabase/migrations/20260821180908_split_account_profile_app_preferences.sql:107` |
| Refresh | Successful save invalidates `profileDataProvider`; the page pops only after awaited success |

`profileDataProvider` in `apps/app/lib/app/network_providers.dart:369` composes
canonical Profile + Body + Account through
`apps/app/lib/app/profile/canonical_profile_data_reader.dart`. Units are sourced
from the common Profile record, not a new app-preferences field or the removed
legacy `users.unit_preferences` column.

Preserve existing save semantics: no-change Save disabled; duplicate saves
guarded; failure retains editable choices and shows `measurement-units-save-error`;
successful save pops to the caller. Existing route fallback to Metric when no
profile data is available is a pre-existing limitation, not proof of successful
hydration; do not silently redesign that error flow in this slice. No live DB
read/write or RLS verification was performed; storage conclusions are source and
checked-in migration evidence only.

### #112 frozen dependency reconciliation

- Accepted visual source checkpoint: `45311ef48cef18bf1f973d158048442a9b1e8bbd`.
  Its listed Flutter CI #1781 / run 32716723775 and Android CI #193 / run
  32716723751 are historical tracker evidence, not checks run in this audit.
- Current shared-editor Git blob: `c8bbfe0caa154fb0d7a70d310bc0abfeb9b492ae`.
- Direct comparison of the editor, Settings Units page and Onboarding
  `MeasurementUnitsScreen` against the accepted checkpoint found only
  `MeasurementUnitPreferences` -> `UnitPreferences` and the core import move
  from `measurement/measurement.dart` to `units/units.dart`. A normalized exact
  source comparison passed for all three files. The editor change is recorded
  in commit `31dd923a` (`refactor(flutter): absorb canonical units into consolidation`).
- Preserve current source, not obsolete type names. Metric = kg/cm/km/ml;
  Imperial = lb/ft_in/mi/fl_oz; Custom is derived and disappears on exact preset
  restoration. Preserve centered two/three-segment controls, all independent
  choices, selected semantics and responsive large-text layout.
- In S0-A only the Settings wrapper title may become **Units**. The shared
  editor, Onboarding consumer, unit model, conversions and persistence stay
  unchanged. Do not reopen #112, fork its editor or add `measurement_system`.

### Theme duplicate-reference audit and compatibility policy

Repository-wide Dart reference search found:

| File | Reference |
|---|---|
| `apps/app/lib/app/router.dart:858` | Normal App Preferences action opens `showThemeSelectionBottomSheet` |
| `apps/features/settings/lib/src/presentation/widgets/theme_selection_bottom_sheet.dart` | Existing `Appearance` sheet and four theme options |
| `apps/features/settings/test/presentation/theme_selection_bottom_sheet_test.dart` | Sheet callback/options/dismissal regression |
| `apps/app/lib/app/router.dart:83` and `:883` | Shell chrome registry and a registered `ThemeSettingsPage` route |
| `apps/core/lib/src/routing/routes/app_routes.dart:105` | Public `AppRoutes.themeSettings`, `/settings/theme` |
| `apps/app/lib/app/app_mode/app_mode_route_policy.dart:34` | Existing onboarding/mode route policy entry |
| `apps/app/test/app/app_mode_route_policy_test.dart:89` | Theme route redirect contract test |
| `apps/features/settings/lib/src/presentation/pages/theme_settings_page.dart` | Existing full-screen alternative with Save Theme/error handling |
| `apps/features/settings/lib/src/presentation/presentation.dart:9` | Public page export through `settings.dart` |

No in-repo button/link caller pushing `/settings/theme` was found. That is **not**
a zero-reference result: the route, public export and policy test still exist.
External deep-link usage was not established by this audit.

**Frozen S0-A policy:** the existing Appearance bottom sheet remains the canonical
user-discoverable interaction. Retain the registered `/settings/theme` page,
path, export and policy as compatibility surface; do not add navigation to it.
This preserves the existing addressable route contract without assuming that
absence of an in-repo button proves safe removal. Retirement requires a separate
compatibility decision. Both paths already use the same `AppThemeController` and
`SharedPreferencesAppThemePreference` (`app_theme_mode`), not duplicate storage.

The sheet currently dismisses in `finally` even if selection throws, while the
page has explicit error feedback. This pre-existing difference is recorded,
not fixed or described as equivalent error UX in S0-A.

### Baseline documentation drift and test gaps addressed by S0-A

- `docs/screens/settings.md` incorrectly describes only App Mode as implemented,
  account controls as unimplemented and App Mode as device-local with deferred
  account sync. S0-A corrects the actual wired rows, Units and Theme ownership.
- Authenticated App Mode saves use `AppModeController.select` -> canonical
  `AppPreferencesRepository` -> `SupabaseAppPreferencesRepository` ->
  `user_app_preferences.app_mode/active_tabs`. Session bootstrap requires the
  canonical writer; failures do not publish a new mode. SharedPreferences is
  staging/cache, not the authenticated source of truth. The routed success
  path returns Home. Preserve this existing behavior.
- `settings_page_test.dart` currently expects all six sections and root
  Measurement Units; these assertions must change with the approved IA.
- `app_mode_router_test.dart` covers Profile -> Settings -> App Settings and
  App Mode/Theme entry presence. It lacks the new Units navigation/save/return
  path. There is no standalone `AppSettingsPage` test; extend the existing
  Settings widget suite instead of automatically adding a new test file.
- Units widget tests already cover mixed save, selected semantics, 320x760 at
  text scale 1.6 and retryable failure. Onboarding's Units test locks centered
  presets and reversible Custom. Profile repository tests cover non-unit field
  preservation and missing canonical Profile failure.
- Profile-route and Account widget tests cover their owner behavior. The
  onboarding logout router test is not a Settings logout regression; add
  Settings-specific confirmation/cancel and route assertions in existing suites.

## 3. Clarification — Frozen Decisions

| Decision | Status / rationale |
|---|---|
| Target IA, hidden capabilities and Units label | Frozen by TNYX-127 / #167 |
| Units ownership and persistence | Reuse current Profile-backed adapter; no model/schema/new repository |
| Units navigation | Move callback from root into AppSettingsPage; retain `/settings/measurement-units` and all technical route identifiers |
| Root capability exposure | Hide null/unwired entries; remove empty sections and orphan dividers; do not invent destinations or a new capability service |
| App Preferences copy | Use `App Mode, theme & units`; align its page heading with `App Preferences`; keep the existing Theme row label |
| Theme | Preserve canonical sheet plus existing route compatibility as documented above; no deletion/redesign |
| Source changes now | Explicitly authorized for S0-A only; implemented within the allowlist below |

No unresolved product/storage decision is needed for this bounded approach.
The fresh main/status check matched the frozen assumptions before editing.
If a new requirement needs any frozen file below, stop and revise scope before
editing it.

## 4. Architecture Design

### Implemented IA (matches the frozen target)

```text
Settings (/settings)
├─ ACCOUNT & PROFILE
│  ├─ Profile Settings -> /settings/profile
│  └─ Account Settings -> /settings/account
├─ PREFERENCES
│  └─ App Preferences -> /settings/app
│     ├─ App Mode -> /settings/app-mode
│     ├─ Theme -> existing Appearance bottom sheet
│     └─ Units -> /settings/measurement-units
└─ SESSION
   └─ Log Out -> existing confirmation -> existing signOut -> /auth
```

Use `context.push` from App Preferences so Units Save/back returns to App
Preferences. A route-string hierarchy change is unnecessary. Keep state and
business rules in their existing owners. Rejected alternatives: a new Units
repository, persisted Custom, feature-local editor, routing dead rows to
placeholders, converting Theme to a new UI, or removing its non-zero-reference
public route during this IA change.

### Exact approved allowlist and actual changed files

All ten files below changed; no other tracked/untracked source or documentation
file changed. Publication includes this new brief and the nine reviewed modified
files. No screenshots or other artifacts are added.

| File | Permitted change |
|---|---|
| `.ai/tasks/settings-s0a-truthfulness-units.md` | Audit, implementation evidence and handoff only |
| `apps/features/settings/lib/src/presentation/pages/settings_page.dart` | Remove root Units entry/callback, gate unavailable rows/empty sections, truthful subtitle; preserve surviving tile/dialog styling and actions |
| `apps/features/settings/lib/src/presentation/pages/app_settings_page.dart` | Add Units callback/row using the current list pattern; align page title; preserve current App Mode/Theme behavior |
| `apps/features/settings/lib/src/presentation/pages/measurement_units_settings_page.dart` | User-facing title `Units` only; no editor/state/save behavior changes |
| `apps/app/lib/app/router.dart` | Move Units launch callback into AppSettingsPage only; keep route builders, repositories, Auth/Profile/Account/App Mode/Theme wiring intact |
| `apps/core/lib/src/routing/routes/app_routes.dart` | Copy metadata only: truthful Settings description, App Preferences title/description, Units title; no path/identifier/chrome-policy changes |
| `apps/features/settings/test/presentation/settings_page_test.dart` | Update visibility/callback assertions; add App Preferences/Units and Settings logout cases with existing suite patterns |
| `apps/features/settings/test/presentation/measurement_units_settings_page_test.dart` | Update title expectations; retain existing persistence/semantics/compact/failure coverage |
| `apps/app/test/app/app_mode_router_test.dart` | Extend existing route fixtures for Units round-trip, retained Profile/Account/logout and canonical Theme/compatibility behavior |
| `docs/screens/settings.md` | Reconcile implemented IA, Theme compatibility and canonical App Mode/Units persistence |

### Exact files that must not change

Everything outside the allowlist is frozen. In particular:

- `apps/core/lib/src/ui/components/preferences/tio_measurement_unit_preferences_editor.dart`
- `apps/core/lib/src/units/unit_preferences.dart`
- `apps/core/lib/src/units/unit_types.dart`
- `apps/core/lib/src/units/units.dart`
- `apps/features/onboarding/lib/src/presentation/screens/profile/measurement_units_screen.dart`
- `apps/features/onboarding/test/presentation/measurement_units_screen_test.dart`
- `.ai/tasks/measurement-units-segmented-ui.md`
- `apps/app/lib/app/settings_persistence_providers.dart`
- `apps/app/lib/app/network_providers.dart`
- `apps/app/lib/app/profile/canonical_profile_data_reader.dart`
- `apps/app/lib/app/profile/profile_settings_route.dart`
- `apps/features/profile/lib/src/domain/repositories/measurement_unit_preferences_repository.dart`
- `apps/features/profile/lib/src/data/repositories/supabase_measurement_unit_preferences_repository.dart`
- `apps/features/profile/lib/src/data/repositories/supabase_user_profile_repository.dart`
- `apps/features/settings/lib/src/presentation/pages/profile_settings_page.dart`
- `apps/features/settings/lib/src/presentation/pages/account_settings_page.dart`
- `apps/features/settings/lib/src/presentation/pages/app_mode_settings_page.dart`
- `apps/features/settings/lib/src/presentation/pages/theme_settings_page.dart`
- `apps/features/settings/lib/src/presentation/widgets/theme_selection_bottom_sheet.dart`
- `apps/features/settings/lib/src/presentation/presentation.dart`
- `apps/features/settings/lib/settings.dart`
- `apps/app/lib/app/app_mode/app_mode_controller.dart`
- `apps/app/lib/app/app_mode/app_mode_route_policy.dart`
- `apps/app/lib/app/app_mode/supabase_app_preferences_repository.dart`
- `apps/app/lib/app/app_theme_controller.dart`
- `apps/app/lib/app/shared_preferences_app_theme_preference.dart`
- `supabase/migrations/20260821180908_split_account_profile_app_preferences.sql`

Also freeze all other `supabase/`, unit converters, theme/token/component files,
Auth/session owners, Nutrition/Workout/Progress, Watch/native platforms,
manifests/lockfiles and CI. No executable SQL, migration, Supabase apply/push,
live schema/RLS/grants/Storage changes or API implementation.

## 5. Implementation And Decisions

- [x] Recheck main, branches/worktrees, existing changes and the frozen source.
- [x] Run baseline focused tests and matching widget layout measurements.
- [x] Apply only the approved IA/copy/callback changes.
- [x] Extend existing widget/router suites without weakening #112 coverage.
- [x] Reconcile `docs/screens/settings.md` with runtime/owner truth.
- [x] Run the required focused validation and check the exact allowlist.
- [x] Record implementation/review evidence and stop before publication until
  separately authorized; publication authorization is now recorded below.

Implementation decisions:

- Hide the six unavailable root entries statically, remove their unused optional
  callback fields and empty sections, and move the existing Units callback out
  of root. Repository-wide Dart search found no callers for the removed unused
  callbacks. No capability service or fake destination was introduced.
- Keep surviving root row/dialog styling, callbacks and section spacing. Add
  Units with the same Card/ListTile/divider pattern as App Mode and Theme.
- App Preferences uses `context.push(AppRoutes.measurementUnitsSettings.path)`;
  the Units route builder, profile hydration, repository/save/refresh code are
  unchanged. `MeasurementUnitsSettingsPage` differs only by its visible title.
- `AppRoutes` changes only title/description metadata. All path/identifier/chrome
  values are identical to starting HEAD. Theme remains the Appearance sheet;
  the direct Theme route/page/export/policy are retained with the same storage.
- Reuse existing test suites and synthetic in-memory/provider fixtures. Cover
  mixed hydration, unsaved Back, failed Save retaining draft, retry success,
  return to App Preferences, reopening saved preferences, direct Units/Theme
  paths, Profile/Account routes and logout cancel/confirm. No real user data or
  live Supabase calls are used.

## 6. Quality Review

### Initial audit evidence (before implementation authorization)

- `git rev-parse --show-toplevel`, `git status --short --branch`,
  `git rev-parse HEAD origin/main`, `git worktree list --porcelain` and
  `git ls-remote --heads origin`: clean matching main snapshot as recorded above.
- `gh issue view 167/112 --repo im-tnyx/tio-world --comments --json ...`,
  `gh pr view 50 ...`, `gh pr list --state open ...`; Linear issue/comment reads.
- Source/reference/test inspection with `rg` and `Get-Content`; exact comparison
  against #112 accepted checkpoint after the known type/import rename passed
  for the shared editor and both consumers.
- Flutter/Dart/Melos tests and analyzers **not run**. The change is documentation
  only; `Get-Command flutter,dart,melos` found no executable on this shell PATH.
  This is not a claim that no SDK exists elsewhere. No SDK install, cache scan,
  dependency bootstrap, live Supabase validation or device test was attempted.
- `git diff --check`: no diagnostics. `git diff --no-index --check -- /dev/null
  .ai/tasks/settings-s0a-truthfulness-units.md`: no whitespace diagnostics after
  removing initial Markdown hard-break trailing spaces; exit 1 denotes the new
  file diff. All explicit repository file references were checked and exist.
- Final status inventory contains only this untracked brief; `git diff
  --name-only HEAD` is empty. Final live main recheck still matched the frozen
  SHA, with no open PRs. No production file was changed.

### Implementation verification — executed 2026-08-28

`flutter` and `dart` below denote the existing SDK selected by repository
Android `local.properties`, invoked explicitly because they are not on PATH.
`flutter --version` confirmed Flutter 3.44.6 / Dart 3.12.2. Existing package
resolution was usable; no `pub get`, bootstrap, SDK install or machine config
change was needed. The first sandboxed version probe hung and was cancelled;
approved execution using the same configured SDK succeeded.

| Working directory | Command | Result |
|---|---|---|
| Repository root | `git status --short --branch`; `git rev-parse HEAD main origin/main`; `git worktree list --porcelain` | PASS: starting SHA matched; one worktree; isolated implementation branch |
| Repository root | `git diff --check` | PASS |
| Repository root | `git diff --name-only HEAD`; `git ls-files --others --exclude-standard` | PASS: exact ten-file allowlist, no forbidden paths |
| `apps/features/settings` | `flutter test --no-pub test/presentation/settings_page_test.dart test/presentation/measurement_units_settings_page_test.dart test/presentation/theme_selection_bottom_sheet_test.dart` | Baseline: 6 passed before production edits |
| `apps/features/settings` | `flutter test --no-pub test/presentation/settings_page_test.dart --plain-name 'surviving rows preserve layout'` | Pre-edit layout baseline: 4 passed |
| `apps/features/settings` | `flutter analyze --no-pub` | PASS: no issues |
| `apps/features/settings` | `flutter test --no-pub` | PASS: 31 tests |
| `apps/app` | `flutter analyze --no-pub` | PASS: no issues |
| `apps/app` | `flutter test --no-pub test/app/app_mode_router_test.dart test/app/app_mode_route_policy_test.dart test/app/app_mode_settings_write_parity_test.dart test/app/router_provider_stability_test.dart test/profile/profile_settings_route_test.dart test/app/onboarding_root_logout_router_test.dart test/app/app_theme_controller_test.dart test/app/shared_preferences_app_theme_preference_test.dart` | PASS: 36 tests |
| `apps/core` | `flutter analyze --no-pub` | PASS: no issues |
| `apps/core` | `flutter test --no-pub test/units/units_test.dart` | PASS: 12 tests |
| `apps/features/profile` | `flutter test --no-pub test/data/supabase_measurement_unit_preferences_repository_test.dart test/data/supabase_user_profile_repository_test.dart` | PASS: 8 tests |
| `apps/features/onboarding` | `flutter test --no-pub test/presentation/measurement_units_screen_test.dart` | PASS: 1 test |

Final focused result: **88 tests passed; three analyzers clean**. Counts exclude
baseline runs and repeat verification runs. Settings and App checks were rerun
after the final assertion/formatting cleanup and passed again.

Formatting executed at repository root:

```text
dart format apps/app/lib/app/router.dart apps/app/test/app/app_mode_router_test.dart apps/core/lib/src/routing/routes/app_routes.dart apps/features/settings/lib/src/presentation/pages/settings_page.dart apps/features/settings/lib/src/presentation/pages/app_settings_page.dart apps/features/settings/lib/src/presentation/pages/measurement_units_settings_page.dart apps/features/settings/test/presentation/settings_page_test.dart apps/features/settings/test/presentation/measurement_units_settings_page_test.dart
dart format apps/features/settings/test/presentation/settings_page_test.dart
dart format --output=none --set-exit-if-changed apps/app/test/app/app_mode_router_test.dart apps/core/lib/src/routing/routes/app_routes.dart apps/features/settings/lib/src/presentation/pages/settings_page.dart apps/features/settings/lib/src/presentation/pages/app_settings_page.dart apps/features/settings/lib/src/presentation/pages/measurement_units_settings_page.dart apps/features/settings/test/presentation/settings_page_test.dart apps/features/settings/test/presentation/measurement_units_settings_page_test.dart
```

All formatting commands succeeded. The final seven-file check reports zero
changes. The first format pass also reflowed unrelated pre-existing router code;
those formatter-only edits were removed to preserve the exact callback-only
allowlist boundary. No claim is made that the entire legacy router is format-clean.

Additional review evidence:

- Exact shared-editor blob comparison (`git hash-object` vs `git rev-parse
  HEAD:<path>`) matches `c8bbfe0caa154fb0d7a70d310bc0abfeb9b492ae`.
- Exact normalized Units page comparison differs only in title. Route
  declarations retain every identifier/path/chrome value. Router diff consists
  only of removing and adding the same Units push callback.
- All source/persistence/editor files outside the ten-file allowlist are
  unchanged, including the frozen Units brief. Original #112 regression coverage
  is retained; only Settings title expectations changed in its existing suite.
- Matching layout baselines: Profile row size 358x106 at 390px and 288x298 at
  320px/1.6; App Mode/Theme row rectangles remain identical in both light/dark.
  Existing Units 320x760/1.6 overflow and selected-semantics coverage still passes.
- Settings tests report the existing `uses-material-design` package/primary
  pubspec warning. It is not a test/analyzer failure; frozen manifests were not
  modified to suppress it.
- Not run by the agent: device/emulator screenshot review, golden-image
  comparison, full workspace tests, native/release build, live database/RLS
  verification or CI. User-confirmed device acceptance is recorded separately
  below. This is not a claim of production readiness.

### Bounded review and real-device acceptance

- Bounded implementation review: **PASS WITH NOTES**; no blocking defect.
  The review reran all 88 focused tests and the three analyzers successfully.
  Remaining notes are the pre-existing nullable root callback API (all actual
  production callbacks are wired) and limited harmless formatter reflows.
- **REAL-DEVICE PASS — user-confirmed evidence.** In the publication request,
  the user explicitly reported that real-device visual/runtime acceptance passed
  and confirmed that logout works. This is the user's acceptance report, not an
  agent-operated device test or independent screenshot verification.
- Device model, OS version, build identifier and detailed test matrix were not
  supplied; none is inferred. No screenshots were requested or added.
- Publication preflight refreshed origin and confirmed main remains
  `7d4590780f48b9c236a80089d9132e2314f5554c`, an ancestor of the branch.
  Before this evidence-only brief update, all ten file hashes matched the
  reviewed snapshot. The 88-test/analyzer result therefore still applies to the
  unchanged production/test source.
- The approved ten-file boundary, `git diff --check` and frozen shared-editor
  hash were rechecked successfully. No forbidden file, schema, backend,
  repository, editor or persistence owner changed.
- User authorization permits committing these files on
  `codex/settings-s0a-truthfulness-units`, pushing that branch and opening a
  **Draft** PR against `main`. Do not use an issue-closing keyword: reference
  GitHub #167, Linear TNYX-127, parent TNYX-118 and frozen dependency #112.

## 7. Final Handoff

**Outcome:** IMPLEMENTED. Actual changed files are the exact ten entries in
section 4. The implementation/review handoff had nine modified tracked files
plus this new brief at the recorded pre-publication HEAD. Bounded review, local
checks and user-confirmed real-device acceptance have passed. Only this brief's
evidence/status is updated for the authorized publication.

**Runtime:** root has Profile Settings, Account Settings, App Preferences and
Log Out. App Preferences has App Mode, Theme and Units. Units Save/back returns
to App Preferences when entered there. Existing direct Units/Theme paths remain.

**Remaining limits:** existing missing-profile Metric fallback, empty App
Preferences when selected mode is null, Theme sheet/page failure-UX difference,
and sign-out failure handling were deliberately not redesigned. No new Units
storage/model, persisted Custom or `measurement_system` was introduced.

**Publication boundary:** commit/push this reviewed branch and open a Draft PR;
record the resulting commit, remote SHA, PR and current CI status in the handoff.
After publication, await CI/review and separate merge authorization. Keep the
brief active pending merge; TNYX-118 remains the parent readiness gate, TNYX-127
is not marked Done, #167 remains open, #112 remains COMPLETE/FROZEN, and S0-B has
not started. No merge or tracker-status mutation is authorized. Re-audit affected
files if main changes.
