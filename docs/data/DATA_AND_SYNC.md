# Data And Sync

This document defines Tio-world data ownership, repository boundaries, local persistence, sync, Supabase, and the future protected-backend direction.

## Data Principles

- The app should be offline-first for core fitness flows.
- UI does not know database table shape and does not call Supabase/remote APIs directly.
- Feature controllers call use cases/repositories; repositories hide local and remote data sources.
- Supabase is the current durable Auth/Postgres source for signed-in user data.
- A future protected backend is an orchestration/access layer over the same canonical data model, not a second owner schema.
- One durable concept has one canonical owner.
- App Mode/UI visibility never deletes hidden owner data.

## Repository Pattern

```text
Page / Widget
  ↓
Riverpod controller / notifier
  ↓
Use case / domain service
  ↓
Repository contract
  ↓
Local data source + Supabase / future backend adapter
```

Repository contracts live with the owning feature or in `apps/shared` when genuinely cross-feature. Remote DTO/table shapes never leak into presentation.

## Canonical User/Data Root

`public.users` is the application/domain user root.

New durable domain tables reference:

```sql
REFERENCES public.users(id) ON DELETE CASCADE
```

rather than referencing `auth.users` directly. `public.users.id` remains linked to Supabase Auth today, while Body/Wellness/Nutrition/Workout ownership stays authentication-provider-neutral for a future backend.

## Onboarding Persistence Lifecycles

Tio-world has three different persistence lifecycles:

1. **Unfinished Onboarding Draft — `public.onboarding_drafts`**
   - temporary, mutable, versioned JSONB snapshot;
   - owned by onboarding orchestration;
   - used for autosave/resume/reconciliation;
   - cleared after successful durable completion;
   - dormant/skipped values are not automatically canonical user intent.

2. **Canonical Owner Data**

```text
public.users
public.user_devices
public.body_weight_logs
public.user_body_goals
public.user_wellness_targets
public.user_nutrition_profiles
public.user_nutrition_targets
public.user_workout_profiles
public.user_workout_targets
```

3. **Local Non-Sensitive Metadata**
   - `OnboardingStatus`, confirmed `AppMode`, and similar lightweight routing/bootstrap state may use local preferences where explicitly approved.

Onboarding and Settings are entry points into canonical owners; neither creates a parallel durable schema.

## Canonical Ownership

| Durable concept | Canonical owner |
| :--- | :--- |
| Account + common user profile | `public.users` |
| Device identity/runtime device state | `public.user_devices` |
| Body weight history/current weight | `public.body_weight_logs` |
| Body goal, Target Weight, weekly Goal Pace | `public.user_body_goals` |
| Steps/water/sleep targets | `public.user_wellness_targets` |
| Diet/allergy/food-preference context | `public.user_nutrition_profiles` |
| Calories/macros/fiber + recommendation/custom target state | `public.user_nutrition_targets` |
| Workout capability/context | `public.user_workout_profiles` |
| Workout goal + days/duration/split/special-event constraints | `public.user_workout_targets` |
| Onboarding draft/resume | `public.onboarding_drafts` |
| Workout sessions/events | Workout domain |
| Nutrition diary/foods/meals | Nutrition domain |
| Progress photos/other approved measurement media | Progress domain + approved private Storage |
| Workout runtime preferences | separate Workout Runtime Settings owner |

### `public.users`

Common profile/account fields such as name, gender, date of birth, height, activity level, general health conditions, unit preferences, timezone/profile/account metadata remain here.

`current_weight_kg`, `target_weight_kg`, `goals`, and `primary_goal` may remain physically present during compatibility, but are not long-term canonical Body/Goal owners after repository cutover.

### Body ownership

`body_weight_logs` owns time-varying weight. Latest applicable log is the current-weight source.

`user_body_goals` owns active/historical Body Goal plans:

```text
lose_weight
gain_weight
maintain_weight
recomposition
```

Target Weight and weekly Goal Pace are Body Goal data. Maintain/Recomposition are structurally prevented from carrying Target Weight/Goal Pace in the canonical table.

### Wellness ownership

Steps, water, sleep duration and approved bed/wake targets are common Wellness values, not Nutrition values.

### Nutrition ownership

`user_nutrition_profiles` owns diet/food context only. Calculations read true common Profile/Body owners rather than mirroring height/current weight/Target Weight/activity into Nutrition.

`user_nutrition_targets` owns typed editable numeric Nutrition targets. BMR/TDEE are calculated context, not canonical editable goals.

### Workout ownership

`user_workout_profiles` owns training environment, equipment, experience, focus, injuries/limitations.

`user_workout_targets` owns Workout-specific goal priority and plan constraints such as training days, duration, split and special event. Body Goal values are not mirrored into Workout targets.

Workout runtime behavior such as rest timers, RPE/RIR display/runtime behavior, keep-awake, music, graph rules, inline timers, Wear runtime options, etc. belongs to separate runtime-settings ownership.

## Applied Canonical Owner Migrations

The canonical schema is live in the `tio-world` Supabase project:

```text
20260821161923_create_canonical_owner_tables
20260821162207_backfill_canonical_owner_data
```

These migrations are forward-only and must never be edited in place. Legacy columns are intentionally retained until repository cutover is verified.

## Future-Safe Persisted User Data Rule

Never delete or discard persisted user fields merely because a newer app version does not currently render them. Unknown/inactive/future-facing data is not automatically obsolete.

Destructive cleanup requires:

1. schema/data audit;
2. compatibility impact analysis;
3. verified canonical repository cutover;
4. explicit retention/deletion decision;
5. a new forward migration.

Do not build permanent bidirectional synchronization between legacy and canonical owner columns.

## Local Persistence Direction

Core fitness flows should become offline-capable behind repositories. Candidate local persistence technologies include Drift/Isar or another store that supports the required slice.

Minimum future local/sync surfaces may include:

```text
workout_sessions
workout_events
nutrition_entries
progress_entries
sync_queue
sync_metadata
```

Workout logging should be offline-capable early. Nutrition diary/progress entries should be cacheable. Watch apps retain only minimal local state needed for fast workflows.

## Conflict Handling

Prefer explicit/idempotent sync rules:

- accepted server event wins once synced;
- duplicate event IDs are ignored;
- pending events retry safely;
- user-visible edits remain explicit;
- semantic conflicts are surfaced rather than guessed.

Canonical owner migration follows the same rule: duplicate legacy fields that disagree block automatic backfill instead of silently choosing a winner.

## Code Generation

Use explicit immutable domain models and DTO mapping. `freezed` / `json_serializable` may be used inside the owning package. Generated remote/database shapes do not become domain entities by default.

## Supabase RLS / Access Direction

Current signed-in user access uses Supabase RLS. New canonical owner tables use optimized owner checks:

```sql
(select auth.uid()) = user_id
```

RLS is an access layer, not domain ownership. Future backend server credentials may read/write the same canonical tables while client ownership semantics stay unchanged.

## Supabase Storage Direction

Use Storage only for approved user-owned files. Structured Profile/Body/Nutrition/Workout/Progress records remain relational data behind repositories/RLS.

Create private module buckets only with the first concrete approved file slice, for example `profile`, `nutrition`, `workout`, or `progress`.

## Future Protected Backend Direction

A protected backend may later own server-only orchestration such as:

- AI/provider orchestration and response safety;
- protected third-party integrations;
- long-running/scheduled jobs;
- privileged aggregation or processing.

It should use the same canonical Postgres owners rooted at `public.users`; it must not recreate legacy mixed Profile/Targets schemas.

## Current Migration/Cutover Order

```text
canonical owner contract              ✅
additive Supabase owner schema         ✅
conflict-safe backfill                 ✅
RLS/grants/schema verification         ✅
repository/domain cutover              NEXT
Onboarding + Settings owner parity     NEXT
stop legacy mirrored writes            AFTER CUTOVER
compatibility verification             AFTER CUTOVER
legacy-column cleanup migration        LAST
```

## Public Repo Safety

Never commit real user exports, health records, production logs, secrets, local database dumps, or screenshots containing personal data.
