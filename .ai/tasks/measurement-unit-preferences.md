# Measurement Unit Preferences

**Status:** Ready
**Primary owner:** `tio_core` measurement contract + Profile/account persistence
**Affected platforms:** Flutter phone app, Supabase
**Tracking issue:** #17 — `feat(core): persist measurement unit preferences across onboarding and settings`

## 1. Discovery

### User Outcome

Users choose preferred measurement units during onboarding and can change them later from Settings/Profile. The same preferences restore after login, reinstall, app-data reset, or use on another device.

Tio stores and calculates canonical metric values internally. Unit preferences only control input, presentation, parsing, and formatting.

Example:

```text
User preference: lb
User enters: 180 lb
→ core converts to ~81.6466 kg
→ profile persistence stores current_weight_kg = ~81.6466
→ account preference stores weight_unit = 'lb'
→ reinstall/login/new device
→ profile hydrates kg + weight_unit
→ UI displays ~180 lb
```

### Success Criteria

- Measurement-unit domain logic is reusable and owned by `tio_core`, not onboarding or Settings.
- A dedicated Measurement Units onboarding screen appears after Age/DOB and before Height.
- The same preference model can be edited later from Settings/Profile.
- Weight, height, distance, and volume preferences are durable account state in Supabase.
- Canonical physical values remain metric in storage and calculations.
- Metric/Imperial presets exist but mixed choices remain possible.
- Height, Weight, Nutrition, Workout and Settings surfaces consume the same core converters/formatters.
- Existing completed accounts are not sent back through onboarding.
- Existing accounts safely default to current metric behavior until they change preferences.
- Unit choices survive durable onboarding draft restore and authenticated profile hydration.

### Scope

Core preference model:

```text
weightUnit    = kg | lb
heightUnit    = cm | ftIn
distanceUnit  = km | mi
volumeUnit    = ml | flOz
```

Canonical values:

```text
height        → cm
weight        → kg
water/volume  → ml
distance      → canonical metric representation owned by feature/domain
```

Metric volume presentation may automatically use `L` for larger `ml` values. `L` does not require a separate persisted preference.

### Non-Goals

- Do not store duplicate metric + imperial physical-value columns.
- Do not move canonical calculations into display units.
- Do not use one generic `unit` string.
- Do not use one rigid `metric/imperial` flag as the only preference source.
- Do not infer locale as authoritative after an explicit user choice.
- Do not force legacy completed accounts through the new onboarding step.
- Do not make `tio_core` depend on Supabase or Profile feature packages.
- Do not duplicate conversion/parsing code in Onboarding, Profile Settings, Nutrition, or Workout.

## 2. Codebase Exploration

### Verified Evidence

- `ProfileOnboardingDraft` already contains `heightUnit = 'cm'` and `weightUnit = 'kg'` local state.
- `HeightScreen` already renders canonical centimeters as cm or ft/in depending on a unit input.
- `CurrentWeightScreen` already renders canonical kg as kg or lbs depending on a unit input.
- `ProfileSetupMapper` carries canonical measurement values but currently drops unit preferences.
- Current profile step order has Age/DOB before Height, making Measurement Units a natural insertion point between them.
- Production `public.users` currently stores canonical `height_cm`, `current_weight_kg`, and `target_weight_kg`, but no durable unit-preference columns.
- Nutrition storage includes canonical metric fields such as `water_target_ml`.
- `apps/core/lib/src` currently owns reusable app-wide routing/theme/UI primitives and has no measurement module yet.

### Existing Pattern to Follow

- Keep pure reusable behavior in `tio_core`.
- Keep authenticated remote persistence in the feature/data owner (`profile`/account repository), not core.
- Keep onboarding as a flow/collection surface rather than the owner of cross-feature measurement semantics.
- Preserve durable onboarding draft schema compatibility when adding fields/steps.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Unit model/conversion/formatting belongs in `tio_core` | Decided | Settings, onboarding, profile, nutrition and workout all need identical behavior | Core |
| Supabase persistence stays outside core | Decided | Core must remain pure and data-source independent | Profile/account data |
| Store canonical values in metric | Decided | Deterministic calculations and one numeric source of truth | Core/Profile |
| Persist four independent preferences | Decided | Supports mixed systems such as kg + ft/in + km + L | Product/Core |
| Measurement Units appears after Age/DOB and before Height | Decided | Height/weight screens immediately use chosen units | Onboarding |
| Metric/Imperial are presets, not hard mode locks | Decided | Mixed preferences are common and must be supported | Product |
| Existing completed users are not retroactively gated | Decided | Preserves returning-user completion contract | App session/Onboarding |
| Legacy/default preference = kg/cm/km/ml | Decided | Matches current canonical behavior safely | Core/Profile |
| Settings/Profile can change preference later | Decided | Unit choice is account preference, not onboarding-only data | Settings/Profile |
| `L` is display formatting over metric volume preference | Decided | Avoids unnecessary preference state while preserving natural UI | Core/Nutrition |
| Exact canonical distance base used by every domain | Needs audit | Workout/activity domains may use km, meters, pace, or other representations | Core/Workout |

## 4. Architecture Design

### Chosen Approach

Create a new pure measurement module in `tio_core`, conceptually:

```text
apps/core/lib/src/measurement/
  measurement.dart
  measurement_unit_preferences.dart
  measurement_units.dart
  measurement_converters.dart
  measurement_formatters.dart
```

Exact filenames can follow the existing core export conventions during implementation.

Core types should be typed enums/value objects rather than free-form strings:

```text
WeightUnit.kg | WeightUnit.lb
HeightUnit.cm | HeightUnit.ftIn
DistanceUnit.km | DistanceUnit.mi
VolumeUnit.ml | VolumeUnit.flOz

MeasurementUnitPreferences(
  weightUnit,
  heightUnit,
  distanceUnit,
  volumeUnit,
)
```

Provide preset constructors/mapping:

```text
MeasurementUnitPreferences.metric
→ kg / cm / km / ml

MeasurementUnitPreferences.imperial
→ lb / ftIn / mi / flOz
```

Individual preference fields remain independently replaceable so a preset can be customized.

### Core Conversion Contract

Centralize at least:

```text
kg ↔ lb
cm ↔ total inches / ft + in
km ↔ mi
ml ↔ US fl oz
ml → mL/L display formatting
```

Rules:

- Conversion helpers operate on raw doubles/canonical values.
- Rounding happens at presentation/input boundaries, not canonical persistence.
- Feet/inches conversion rounds total inches before division/modulo to avoid rollover bugs.
- Formatters expose stable, testable strings but must not own widget styling.
- Parsing helpers, if introduced, validate finite positive ranges and return controlled errors rather than silently retaining stale values.

### Ownership and Data Flow

```text
                    ┌──────────────────────────┐
                    │        tio_core          │
                    │ unit model + conversions │
                    │ parsing + formatting     │
                    └────────────┬─────────────┘
                                 │
             ┌───────────────────┼────────────────────┐
             │                   │                    │
             ▼                   ▼                    ▼
       Onboarding UI       Settings/Profile      Feature UIs
       first-time pick      later preference      Nutrition/
             │                  editing            Workout/etc
             └───────────────────┼────────────────────┘
                                 ▼
                     Profile/account repository
                                 │
                                 ▼
                         Supabase public.users
```

`Tio_core` owns semantics, not remote state.

Persistence path:

```text
Onboarding Measurement Units screen
→ core MeasurementUnitPreferences
→ durable onboarding draft
→ ProfileSetupMapper
→ profile/account model
→ Profile repository
→ public.users preference columns
```

Returning/new-device path:

```text
Authenticated profile hydration
→ public.users canonical values + unit preferences
→ profile/account model using core preference types
→ app/profile preference state
→ every feature formats canonical values through core
```

Settings path:

```text
Settings/Profile Units entry
→ current hydrated core preferences
→ user edits preset or individual units
→ Profile/account repository field-specific update
→ Supabase
→ profile stream/state refresh
→ all dependent UI updates
```

### Supabase Contract

Add durable account-level preference columns to `public.users` with safe defaults and CHECK constraints (or equivalent validated enum contract):

```text
weight_unit    text not null default 'kg'
height_unit    text not null default 'cm'
distance_unit  text not null default 'km'
volume_unit    text not null default 'ml'
```

Allowed stored values:

```text
weight_unit    IN ('kg', 'lb')
height_unit    IN ('cm', 'ft_in')
distance_unit  IN ('km', 'mi')
volume_unit    IN ('ml', 'fl_oz')
```

Do not add:

```text
height_in
current_weight_lb
target_weight_lb
water_target_fl_oz
```

Canonical numeric columns remain authoritative.

### Onboarding Order

Profile sub-flow becomes:

```text
Name
→ Gender
→ Goal
→ Age / DOB
→ Measurement Units
→ Height
→ Current Weight
→ Target Weight
→ Activity
→ Health Conditions
```

The new step must participate in current profile-step reconciliation/progress without forcing already-completed accounts through onboarding.

### Measurement Units Screen

Suggested first-time UI:

```text
Choose your units

Preset
[ Metric ] [ Imperial ]

Weight
[ kg ] [ lb ]

Height
[ cm ] [ ft / in ]

Distance
[ km ] [ mi ]

Water & volume
[ mL / L ] [ fl oz ]

Continue
```

Behavior:

- Selecting Metric updates all rows to metric defaults.
- Selecting Imperial updates all rows to imperial defaults.
- Editing any row after preset selection is allowed.
- If rows become mixed, UI may show `Custom`/no-preset-selected state rather than coercing choices back to a preset.
- Screen always has a valid preference object; it is not optional/skippable state.

### Settings/Profile Editing

The same preference editor logic must be reusable after onboarding.

Preferred settings behavior:

```text
Settings
→ Units & Measurements
→ Weight
→ Height
→ Distance
→ Water & volume
```

It may reuse a common unit selector component, but business state/conversion remains core-owned.

Settings changes must persist immediately/explicitly through the profile/account repository and update all consuming surfaces without rewriting canonical numeric values.

### Alternative Rejected

#### Onboarding-owned unit strings

Rejected because Settings and feature surfaces would duplicate conversions and risk divergent behavior.

#### A single `measurement_system` field only

Rejected because it cannot represent common mixed preferences.

#### Local `SharedPreferences` only

Rejected because preferences would disappear after reinstall/app-data clear and would not follow the authenticated account to another device.

#### Persist display values instead of canonical values

Rejected because calculations would become preference-sensitive and rounding drift could corrupt source values.

### Failure and Accessibility States

- Unknown/corrupt remote unit values map to safe metric defaults and should be observable/loggable; they must not crash the app.
- Unit selector controls expose clear selected state to semantics.
- Do not rely on abbreviations alone where meaning can be unclear; visible labels should include `ft / in` and `fl oz`.
- Large text/compact screen layouts must wrap or scroll safely.
- Changing units must never numerically mutate the user's canonical body measurements; only presentation changes.
- Remote preference update failure must show controlled failure and retain the last confirmed preference state.

## 5. Implementation Plan

### A. Core measurement foundation

- [ ] Add `tio_core` measurement module/export.
- [ ] Add typed `WeightUnit`, `HeightUnit`, `DistanceUnit`, `VolumeUnit`.
- [ ] Add immutable `MeasurementUnitPreferences` with metric defaults.
- [ ] Add Metric and Imperial preset mapping.
- [ ] Add `copyWith`/equality support for mixed preferences.
- [ ] Add centralized kg↔lb conversions.
- [ ] Add centralized cm↔ft/in conversions with rollover-safe rounding.
- [ ] Add centralized km↔mi conversions.
- [ ] Add centralized ml↔fl oz conversions.
- [ ] Add mL/L formatter and unit labels.
- [ ] Add corruption-safe stored-string parsers/mappers.
- [ ] Add core unit tests for conversions, presets, labels and roundtrips.

### B. Durable profile/account model

- [ ] Extend canonical Profile/account model to carry `MeasurementUnitPreferences`.
- [ ] Ensure existing call sites receive safe defaults where preferences are absent.
- [ ] Extend Supabase profile mapper/read path to hydrate stored preferences.
- [ ] Add field-specific preference update method or safe merge semantics; do not reconstruct unrelated profile fields from Settings.
- [ ] Keep canonical body values unchanged when preference changes.

### C. Supabase migration

- [ ] Re-audit live `public.users` schema immediately before DDL.
- [ ] Apply a forward migration adding the four preference columns.
- [ ] Add CHECK constraints for supported stored values.
- [ ] Use non-breaking metric defaults for existing rows.
- [ ] Verify RLS allows current authenticated profile owner to read/write preferences through the intended repository path.
- [ ] Run Supabase advisor/security checks after migration where available.
- [ ] Do not backfill/rewrite canonical numeric values.

### D. Onboarding integration

- [ ] Add `ProfileStepId.measurementUnits` after Age/DOB and before Height.
- [ ] Add Measurement Units screen using core unit types.
- [ ] Add preset + individual choice behavior.
- [ ] Extend `ProfileOnboardingDraft` from free-form unit strings to core preference semantics where dependency layering permits; otherwise use a strict serialization adapter at the boundary.
- [ ] Add distance and volume preference state to the draft.
- [ ] Bump durable onboarding draft schema version as required.
- [ ] Make older draft snapshots load with metric defaults for missing fields.
- [ ] Update profile step validation/progress/reconciliation.
- [ ] Update Height screen to use core height formatter/converter.
- [ ] Update Current Weight screen to use core weight formatter/converter.
- [ ] Update Target Weight screen to use the same weight preference.
- [ ] Update `ProfileSetupMapper` to carry preferences into canonical profile persistence.
- [ ] Preserve the rule that completed legacy accounts do not enter the new onboarding step.

### E. Settings/Profile integration

- [ ] Add or wire `Units & Measurements` entry in Settings/Profile.
- [ ] Hydrate current preferences from canonical profile state.
- [ ] Reuse core preset/selector contract.
- [ ] Persist edits through Profile/account repository.
- [ ] Confirm changing preferences updates rendered units without modifying canonical numeric values.
- [ ] Ensure Settings partial updates preserve mobile/avatar/verification and all unrelated profile fields.

### F. Cross-feature consumption

- [ ] Audit all hard-coded `kg`, `cm`, `km`, `ml`, `lbs`, `mi`, `fl oz` presentation strings.
- [ ] Profile screens consume core formatters.
- [ ] Nutrition water targets/logging consume volume preference for display/input while persisting ml.
- [ ] Workout/cardio distance/pace surfaces consume distance preference where relevant.
- [ ] Goal/target summaries use weight preference.
- [ ] Keep BMI/BMR/calorie/training calculations on canonical metric inputs.

### G. Session/reinstall behavior

- [ ] Hydrate unit preferences as part of authenticated profile/account state.
- [ ] Confirm profile state becomes authoritative after reinstall/new device.
- [ ] Local caching may be added for startup UX, but remote account preference remains durable source of truth.
- [ ] Confirm sign-out/new identity cannot leak previous user's cached unit preference.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Required Tests

Core:

- [ ] Metric preset = kg/cm/km/ml.
- [ ] Imperial preset = lb/ftIn/mi/flOz.
- [ ] Mixed unit `copyWith` remains stable.
- [ ] kg↔lb roundtrip within tolerance.
- [ ] cm↔ft/in roundtrip within tolerance.
- [ ] feet/inches rollover behavior is correct around boundaries.
- [ ] km↔mi roundtrip within tolerance.
- [ ] ml↔fl oz roundtrip within tolerance.
- [ ] metric volume formatter switches mL/L as designed.
- [ ] invalid stored unit strings fall back safely.

Onboarding:

- [ ] Measurement Units is between Age/DOB and Height.
- [ ] Metric preset updates all four categories.
- [ ] Imperial preset updates all four categories.
- [ ] Individual overrides produce mixed preferences without coercion.
- [ ] Height immediately renders selected preference.
- [ ] Current/Target Weight immediately render selected preference.
- [ ] Durable draft roundtrip preserves all preferences.
- [ ] Older draft schemas hydrate missing preferences with metric defaults.
- [ ] Final mapper persists preferences without changing canonical values.
- [ ] Completed legacy account is not retroactively gated.

Profile/Settings:

- [ ] Profile read maps Supabase preferences to core model.
- [ ] Unit preference update writes only owned preference fields.
- [ ] Settings change roundtrip persists to Supabase.
- [ ] Preference change does not mutate canonical height/weight values.
- [ ] Profile update preserves unrelated account fields.

Integration:

- [ ] Reinstall/new authenticated session restores chosen units.
- [ ] New device restores chosen units.
- [ ] Sign-out/user switch does not leak previous preferences.
- [ ] Nutrition volume display/input still persists canonical ml.
- [ ] Workout distance display/input still persists canonical metric values.
- [ ] Existing BMI/calorie/goal calculations are invariant across display-unit preference changes.

### Review Findings and Resolution

- User explicitly clarified that units are editable from Settings, therefore reusable unit semantics/conversions belong in `tio_core` rather than onboarding.
- `tio_core` must stay Supabase-independent; persistence remains Profile/account data ownership.
- Existing onboarding unit fields are partial transitional state and should converge on the core contract.

## 7. Final Handoff

### Changed Files

Not implemented yet. This task file and GitHub issue #17 define the implementation contract.

### Actual Behavior

Current behavior before implementation:

- Canonical height/weight values persist in metric units.
- Onboarding draft has local height/weight unit strings.
- Some onboarding screens can display cm/ft-in and kg/lbs.
- Durable account preference is missing, so selected presentation units are not guaranteed after reinstall/new device.
- Distance/volume preferences are not represented as one shared account contract.

### Known Limitations

- Exact distance storage conventions across Workout/related features require implementation-time audit before choosing conversion entry points.
- No Supabase DDL has been applied for this task yet.
- Settings/Profile units editor has not been implemented yet.

### Final Status

`REVIEW`
