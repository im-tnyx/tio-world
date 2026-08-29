# Settings Screen

**Surface:** Phone full-screen preferences and account controls
**Current route:** `/settings`
**Primary owner:** `apps/features/settings`
**Status:** S0-A and accepted S0-B1 provide the Settings hub and Daily Wellness editing. S0-B2 adds the Glass Size client implementation and a local CLI-generated migration; local database verification and physical-device acceptance remain pending. This does not complete the broader Settings readiness gate.

## Purpose

Manage app-level preferences and route the user to module-owned configuration. Settings owns preferences and navigation, not Nutrition, Workout, Profile, Recovery, or Coach business logic.

## Current Implemented Boundary

- Profile exposes the Settings action; Home's app bar keeps only the Profile avatar account entry.
- Root Settings exposes Profile Settings, Account Settings, Health & Goals, App Preferences and Log Out. Profile and Account continue routing to their existing owner-backed screens; this slice does not expand their business behavior.
- App Preferences contains App Mode, Theme and Units. Its root subtitle is `App Mode, theme & units` and its page heading is `App Preferences`.
- App Mode editing previews guided tabs, persists through the same controller used by Onboarding, and returns to Home after success.
- Theme uses the existing Appearance bottom sheet. Units uses the existing shared editor and persistence.
- Manage Subscription, Reset Password, Workout Settings, Wear OS / Watch Settings, Nutrition & Diet and About Tio are not exposed. Their empty sections are absent; no placeholder destinations are wired.
- Navigation & Tabs personalization and additional global preferences remain deferred. Existing account entry wiring is not evidence that all account/security acceptance gates are complete.

## Current Information Architecture

```text
Settings (/settings)
├─ ACCOUNT & PROFILE
│  ├─ Profile Settings -> /settings/profile
│  └─ Account Settings -> /settings/account
├─ HEALTH & GOALS
│  └─ Health & Goals -> /settings/health-goals
│     └─ Daily Wellness -> /settings/health-goals/daily-wellness
├─ PREFERENCES
│  └─ App Preferences -> /settings/app
│     ├─ App Mode -> /settings/app-mode
│     ├─ Theme -> Appearance bottom sheet
│     └─ Units -> /settings/measurement-units
└─ SESSION
   └─ Log Out -> confirmation -> existing signOut -> /auth
```

Settings routes are full-screen and are not bottom tabs. Log Out cancellation
leaves the session/navigation unchanged. Confirmation uses the existing Auth
repository; this IA slice does not change sign-out failure handling.

## Health & Goals And Daily Wellness Ownership

Health & Goals delivers the post-onboarding entry point for Daily Wellness targets.
Settings' user-facing controls are Step Goal, Water Goal, Glass Size and Sleep Schedule.
Settings does not own Wellness persistence or business logic; it consumes the
canonical `WellnessTargetsRepository` (`apps/features/progress`) via `wellnessTargetsRepositoryProvider`
and `wellnessTargetsDataProvider`.

- Water Goal respects the user's `UnitPreferences.volumeUnit` for display (`ml` or `fl oz`) while storing canonical `ml`.
- Sleep Schedule edits Bedtime and Wake Time together in one bottom sheet (local 0..1439 minute-of-day integer values, persisted as SQL TIME). There is no independently editable Sleep Goal in Settings: `sleepTargetMinutes` is always derived from the current Bedtime/Wake Time pair (cross-midnight safe) and recomputed on every save, never fabricated when either side of the schedule is unset.
- Partial edits preserve all untouched values (including unset `null`s) without fabricating defaults.
- Default Glass Size has its own Settings-owned preference/repository, separate from Wellness targets (see below).
- Body Goal / Weight edit remains deferred post-S0-C; no placeholder Body rows are exposed in Settings.

### Daily Wellness grouping

```text
MOVEMENT
  Step Goal
HYDRATION
  Water Goal
  Glass Size
SLEEP
  Sleep Schedule
```

Water Goal and Glass Size share one visual card, not a persistence DTO.
The accepted Step/Water editors, Sleep card/timeline, 15-minute snapping and
haptic behavior are preserved. Page Save Changes still writes only Wellness.

### Default Glass Size — S0-B2

The approved bounded owner is `apps/features/settings`: `HydrationPreferences`
and `HydrationPreferencesRepository` live in `lib/src/domain`, and
`SupabaseHydrationPreferencesRepository` lives in `lib/src/data`. App constructs
and injects these through `hydrationPreferencesRepositoryProvider` and
`hydrationPreferencesDataProvider`. This is the explicit exception to the generic
Settings-consumer rule; it does not transfer other feature data to Settings.
See [ADR-0008](../adr/0008-settings-hydration-preferences-owner.md).

- Glass Size is the amount represented by a future +1 glass action, not Water Goal
  and not Volume Unit. No hydration logging is implemented.
- Canonical storage is nullable integer ml in the dedicated
  `public.user_hydration_preferences` table. The repository never reads/writes
  Wellness, Profile, App Preferences, Nutrition or SharedPreferences.
- No row/null means **Not set**. There is no implicit 250 ml default or backfill.
- Row: **Glass Size**. Sheet: **Default Glass Size**. Help:
  **Amount logged when you add one glass of water.**
- Presets are exactly 200/250/300/350/500 ml. Custom is numeric, 50–2000 ml
  inclusive, in increments of 10. Invalid values are rejected, not rounded.
- Metric summary is e.g. `250 ml`; Imperial summary/presets use existing volume
  formatting, e.g. `~8.5 fl oz`. Preset identities remain canonical ml.
- Custom input stays explicitly labelled **Custom amount (ml)** in both units;
  Imperial adds a converted preview. Rounded fl oz is never converted back into
  persistence. Changing Volume Unit does not write a Glass Size value.
- Preset/Custom/Clear edit only the sheet draft. Save independently awaits the
  Hydration repository; unchanged/invalid and duplicate submits are blocked.
  Clear followed by Save persists null. Cancel/back/barrier discard drafts.
  Dismissal is blocked while a save is in flight; failures keep the sheet retryable.
- Pristine refresh adopts canonical data; a dirty draft survives refresh and
  becomes pristine if canonical data converges. Loading/read failure has its own
  Glass Size state/retry and does not fabricate Not set or block Water Goal.
- Future +1 glass must consume this preference as `amountMl`; changing it must
  never rewrite historical events or create a second Glass Size owner.

**Database deployment boundary:** The reviewed migration
`supabase/migrations/20260829043204_create_user_hydration_preferences.sql` exists
locally but has not been applied remotely. Remote migration application has not
been authorized/performed. Local DB/RLS execution is pending because the local
Postgres service is unavailable. Account-synced runtime acceptance requires the
migration to be separately applied; until storage is available, reads/saves fail
truthfully rather than falling back to local-only success.

## Units Ownership And Navigation

Units is app-global display/input preference, not a new feature-specific setting.
The App Preferences row uses `context.push` to the unchanged
`AppRoutes.measurementUnitsSettings` (`/settings/measurement-units`). Back and a
successful Save return to App Preferences. Direct access to the existing path
remains registered; its screen title is `Units`.

The screen consumes `profileDataProvider` and the existing
`measurementUnitPreferencesRepositoryProvider`. The Profile-owned
`SupabaseMeasurementUnitPreferencesRepository` updates canonical
`user_profiles.unit_preferences` through `UserProfileRepository`, preserving
other Profile fields. The navigation move does not transfer storage to
`user_app_preferences` or introduce a new repository.

GitHub #112 remains COMPLETE/FROZEN: Onboarding and Settings share
`TioMeasurementUnitPreferencesEditor`; Metric/Imperial presets, derived Custom,
four independent preferences, centered controls, accessibility and responsive
behavior are unchanged. No persisted preset/Custom field or canonical metric
value change is introduced. Save remains disabled without edits; failure keeps
the draft retryable; successful save invalidates Profile data before returning.
The existing route's Metric fallback when Profile data is unavailable remains a
known limitation, not a newly verified hydration guarantee.

## Theme Interaction And Compatibility

The canonical discoverable Theme interaction is the existing **Appearance**
bottom sheet with System, Light, Dark and OLED choices. It uses
`AppThemeController` and device-local `SharedPreferencesAppThemePreference`
(`app_theme_mode`).

The registered `/settings/theme` route, `ThemeSettingsPage`, public export and
route-policy references remain for compatibility. There is no App Preferences
button navigating to that page. Both paths use the same controller/storage;
retaining an existing addressable route does not add a second preference owner.
Its removal requires a separate compatibility decision. This slice does not
redesign either interaction or change their existing failure behavior.

## Deferred Content And Existing Owners

- **App Mode** is already implemented; its state and canonical persistence stay with the existing app/shared boundary.
- **Navigation & Tabs** — final-stage preference for choosing and reordering three to six eligible destinations with Home fixed first. Hide this setting until the adaptive-navigation slice is implemented.
- Additional language, Font Style, calendar, notifications and accessibility preferences require their own approved capability/ownership contracts. Existing Theme and Units are described above.
- **Nutrition Targets** launch entry; target calculations remain in Nutrition.
- **Workout Settings** launch entry; training defaults remain in Workout.
- Existing Profile/Account entries retain their owners. Future data/export controls stay hidden until their contracts and implementation are ready.

## App Mode Change Flow

1. Show the current selection and its guided default tabs plus any future compatible custom-layout impact.
2. Let the user choose another mode with a confirmation that explains navigation changes.
3. For authenticated sessions, await the canonical `user_app_preferences` write through `AppModeController` and `AppPreferencesRepository` before publishing the new `app_mode`/`active_tabs`. A missing canonical writer or failed write must not publish a local-only success.
4. Reconcile the visible navigation model and select a valid destination, normally Home when the current destination disappears.
5. Preserve feature data; mode changes navigation and setup expectations, not stored user history.

## Future Navigation And Tabs Flow

1. Start from the current mode's guided default or the saved valid layout.
2. Keep Home selected, first, and included in the three-to-six count.
3. Show only destinations allowed by App Mode, implemented feature availability, and release-stage policy.
4. Let the user select/reorder eligible root destinations and promoted shortcuts, preview the result, and reset to mode defaults.
5. Explain when adding a cross-domain destination requires switching to Hybrid.
6. Reconcile invalid/unreleased destinations and the active route without deleting feature data or active-session state.
7. Apply an approved accessible compact treatment when six saved selections cannot fit directly.

Navigation preference changes where sections/actions appear. It does not change Workout/Nutrition calculations, stored history, or feature ownership.

## Data And State Boundaries

- `apps/shared` owns the `AppMode`, `AppPreferencesState` and repository contracts. Authenticated App Mode/navigation is canonical in `user_app_preferences`; the app composes `SupabaseAppPreferencesRepository`. Local SharedPreferences is pre-auth staging/cache and is refreshed after canonical success; it is not authenticated canonical ownership.
- Theme remains device-local. Units remains canonical Profile-backed app-global preference. These distinct existing persistence owners are not consolidated merely because their rows share App Preferences.
- Settings must not recalculate nutrition targets or workout plans.
- Each enabled preference must have a real state effect, loading/error behavior, and accessible confirmation where needed.
- Avoid presenting unavailable integrations, export, deletion, or notifications as completed functionality.

## Acceptance Criteria

- Settings is not a bottom tab and is reachable from Profile or approved in-feature entry points.
- Root has the implemented Profile Settings, Account Settings, Health & Goals, App Preferences and Log Out entries, with no empty unavailable sections.
- App Preferences exposes App Mode, Theme and Units with truthful copy.
- Units Save/back returns to its caller, and existing direct Units/Theme routes remain compatible.
- The #112 shared editor, independent unit values and save/failure behavior remain unchanged.
- Changing App Mode uses exactly the same state contract as Onboarding.
- The user understands which tabs will be added or removed before confirmation.
- Future custom layout acceptance (not delivered by S0-A): three to six eligible selections, Home first, preview/reset, and preservation of active workout state with a valid fallback route.
- Module-owned settings links do not duplicate domain forms in Settings.

## Related

- [S0-A execution brief](../../.ai/tasks/settings-s0a-truthfulness-units.md)
- [S0-B2 execution brief](../../.ai/tasks/settings-s0b2-default-glass-size.md)
- [Frozen Measurement Units UI](../../.ai/tasks/measurement-units-segmented-ui.md)
- [Onboarding](onboarding.md)
- [Nutrition](nutrition.md)
- [Workout](workout.md)
- [App Mode foundation](../../.ai/tasks/app-mode-foundation.md)
- [Adaptive navigation and action entry](../../.ai/tasks/adaptive-navigation-and-actions.md)
