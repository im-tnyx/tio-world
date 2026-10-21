# Supabase Public Schema Inventory

Document Status: Canonical Live Doc
Last Verified: 2026-10-21 (hosted ledger/RPC delta; structural inventory reuses 2026-10-20 measured counts)
Owner: Supabase data ownership
Truth Boundary: Authoritative as a readable inventory of the verified current `public` schema; executable truth remains checked-in migrations plus verified live schema, and no user data belongs here.

## Status

**Canonical readable inventory of the current Tio-world Supabase `public` schema.**

Structural counts below were measured on **2026-10-20**; the migration ledger and three affected RPCs were **reverified live on 2026-10-21** against:

- all **68** currently checked-in `supabase/migrations/` SQL files through `20261021130000_harden_move_routine_permanent_owner.sql` (the structural catalog baseline was originally measured at 66 files);
- the linked Tio-world project's read-only applied migration ledger (**68/68** exact versions + names; no repository-only or hosted-only migration);
- existing read-only structural `pg_catalog` inventory of `public` tables, columns, keys/constraints, indexes, RLS, plus the 2026-10-21 independently verified owner, search-path, body and ACL delta of the three #568/#569 RPCs.

**2026-10-21 hosted deployment update:** Owner Windows `supabase db push --linked --skip-vault` reported both reviewed migrations applied: `20261021120000_grant_my_program_first_routine_execute.sql` and `20261021130000_harden_move_routine_permanent_owner.sql`. An independent hosted audit confirmed **68/68 exact version/name parity** with protected GitHub `main@8da55bdfe29ed5ec1eee3e5e2f7fed972260b42c`. All three affected live SECURITY DEFINER bodies match committed reviewed SQL bodies after newline normalization. The #568 four-argument first-Routine RPC is `authenticated` executable, while `anon`, `service_role` and `PUBLIC` are denied. Both #569 Move RPCs remain denied to those client roles; all three reject `auth.users.is_anonymous=true` under their trusted server-owned guard. Both Flutter release flags remain false; real-write Android/iOS QA and user-visible release are **NOT verified**. The two migrations add **no table/column/index changes**; structural counts below remain the previously verified inventory.

The **2026-10-17, 62/62** snapshot through `20261016220000_prevent_deleted_routine_resurrection` and older **2026-10-11, 55/55** snapshot through `20261010061809_create_user_workout_routine_composition` remain historical. Newer deployed migrations add staged Move functions, retire a legacy grant and introduce a server-owned My Program identity. The 2026-10-20 update only records verified metadata; it **did not** deploy or rerun any migration, execute mutating RPCs or change user data. The private Routine tombstone table remains intentionally excluded from this `public`-only inventory.

## Truth Boundary

This document is a human-readable structural inventory. It is **not executable database truth**.

Current database truth is:

1. checked-in `supabase/migrations/` for repository-owned schema history; and
2. verified live Supabase schema metadata for the deployed state.

If this document disagrees with migrations or verified live metadata, treat the document as stale and reconcile it before dependent work continues.

Refresh this inventory whenever an applied schema migration changes the documented `public` structure.

This inventory intentionally excludes:

- row counts;
- production/user data;
- secrets or credentials;
- sample personal records;
- policy-by-policy RLS bodies.

## Verified Snapshot

| Measure | Verified value |
| :--- | ---: |
| Active ordinary `public` tables | 19 |
| Columns | 191 |
| Primary-key constraints | 19 |
| Foreign-key constraints | 21 |
| Unique constraints | 10 |
| Check constraints | 77 |
| Constraint-trigger records | 2 |
| Total catalog constraint records | 129 |
| Indexes | 55 |
| Tables with RLS enabled | 19 / 19 |
| Partitioned tables | 0 |
| Views | 0 |
| Materialized views | 0 |
| Applied live migrations matched to repository | 68 / 68 |
| Repository-only pending migrations | 0 |

The verified live migration ledger ends at `20261021130000_harden_move_routine_permanent_owner`; all **68** checked-in and **68** applied migration versions and names matched in the 2026-10-21 read-only audit, with no repository-only/live-only versions. The pre-existing catalog/constraint measurements above were taken on 2026-10-20 and were not recomputed by this documentation slice. This verification is not an authenticated end-user write or device QA test.

## Table Overview

| Table | Columns | RLS |
| :--- | ---: | :--- |
| `public.body_weight_logs` | 8 | Enabled |
| `public.meal_log_entries` | 16 | Enabled |
| `public.meal_log_item_snapshots` | 8 | Enabled |
| `public.onboarding_drafts` | 5 | Enabled |
| `public.user_app_preferences` | 5 | Enabled |
| `public.user_body_goals` | 12 | Enabled |
| `public.user_devices` | 12 | Enabled |
| `public.user_nutrition_profiles` | 9 | Enabled |
| `public.user_nutrition_targets` | 12 | Enabled |
| `public.user_profiles` | 12 | Enabled |
| `public.user_wellness_targets` | 8 | Enabled |
| `public.user_workout_exercises` | 12 | Enabled |
| `public.user_workout_programs` | 6 | Enabled |
| `public.user_workout_routines` | 9 | Enabled |
| `public.user_workout_routine_exercises` | 6 | Enabled |
| `public.user_workout_routine_sets` | 11 | Enabled |
| `public.user_workout_profiles` | 7 | Enabled |
| `public.user_workout_targets` | 12 | Enabled |
| `public.users` | 21 | Enabled |

## Tables

### `public.body_weight_logs`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` |
| `user_id` | `uuid` | No | — |
| `weight_kg` | `numeric` | No | — |
| `measured_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `source` | `text` | Yes | — |
| `metadata` | `jsonb` | No | `'{}'::jsonb` |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `body_weight_logs_pkey` | `PRIMARY KEY` | `PRIMARY KEY (id)` |
| `body_weight_logs_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` |
| `body_weight_logs_metadata_object` | `CHECK` | `CHECK (jsonb_typeof(metadata) = 'object'::text)` |
| `body_weight_logs_weight_positive` | `CHECK` | `CHECK (weight_kg > 0::numeric)` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `body_weight_logs_pkey` | `CREATE UNIQUE INDEX body_weight_logs_pkey ON public.body_weight_logs USING btree (id)` |
| `idx_body_weight_logs_user_measured_at` | `CREATE INDEX idx_body_weight_logs_user_measured_at ON public.body_weight_logs USING btree (user_id, measured_at DESC)` |

### `public.meal_log_entries`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` |
| `user_id` | `uuid` | No | — |
| `mode` | `text` | No | — |
| `meal_category_id` | `text` | No | — |
| `meal_name` | `text` | Yes | — |
| `note` | `text` | Yes | — |
| `consumed_at` | `timestamp with time zone` | No | — |
| `consumed_local_date` | `date` | No | — |
| `consumed_timezone_id` | `text` | Yes | — |
| `consumed_utc_offset_minutes` | `integer` | Yes | — |
| `capture_source` | `text` | Yes | — |
| `manual_nutrition_snapshot` | `jsonb` | Yes | — |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `client_mutation_id` | `uuid` | Yes | — |
| `revision` | `bigint` | No | `1` |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `meal_log_entries_pkey` | `PRIMARY KEY` | `PRIMARY KEY (id)` |
| `meal_log_entries_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` |
| `meal_log_entries_user_client_mutation_id_key` | `UNIQUE` | `UNIQUE (user_id, client_mutation_id)` |
| `meal_log_entries_capture_source_check` | `CHECK` | `CHECK (capture_source IS NULL OR (capture_source = ANY (ARRAY['quick_add'::text, 'food_search'::text, 'barcode'::text, 'text'::text, 'voice'::text, 'photo'::text, 'recent'::text, 'saved_meal'::text, 'planned_meal'::text])))` |
| `meal_log_entries_manual_nutrition_snapshot_valid` | `CHECK` | `CHECK (private.is_valid_nutrition_snapshot_v1(manual_nutrition_snapshot))` |
| `meal_log_entries_mode_check` | `CHECK` | `CHECK (mode = ANY (ARRAY['manual'::text, 'detailed'::text]))` |
| `meal_log_entries_mode_nutrition_shape` | `CHECK` | `CHECK (mode = 'manual'::text AND manual_nutrition_snapshot IS NOT NULL OR mode = 'detailed'::text AND manual_nutrition_snapshot IS NULL)` |
| `meal_log_entries_revision_positive` | `CHECK` | `CHECK (revision >= 1)` |
| `meal_log_entries_time_context_required` | `CHECK` | `CHECK (consumed_timezone_id IS NOT NULL OR consumed_utc_offset_minutes IS NOT NULL)` |
| `meal_log_entries_timezone_id_nonblank` | `CHECK` | `CHECK (consumed_timezone_id IS NULL OR btrim(consumed_timezone_id) <> ''::text)` |
| `trg_meal_log_entries_item_cardinality` | `TRIGGER` | `TRIGGER DEFERRABLE INITIALLY DEFERRED` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `idx_meal_log_entries_user_local_date_consumed_at` | `CREATE INDEX idx_meal_log_entries_user_local_date_consumed_at ON public.meal_log_entries USING btree (user_id, consumed_local_date, consumed_at DESC)` |
| `meal_log_entries_pkey` | `CREATE UNIQUE INDEX meal_log_entries_pkey ON public.meal_log_entries USING btree (id)` |
| `meal_log_entries_user_client_mutation_id_key` | `CREATE UNIQUE INDEX meal_log_entries_user_client_mutation_id_key ON public.meal_log_entries USING btree (user_id, client_mutation_id)` |

### `public.meal_log_item_snapshots`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` |
| `meal_log_entry_id` | `uuid` | No | — |
| `position` | `integer` | No | — |
| `display_name` | `text` | No | — |
| `brand_name` | `text` | Yes | — |
| `quantity` | `numeric` | No | — |
| `serving_unit` | `text` | No | — |
| `nutrition_snapshot` | `jsonb` | No | — |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `meal_log_item_snapshots_pkey` | `PRIMARY KEY` | `PRIMARY KEY (id)` |
| `meal_log_item_snapshots_entry_fkey` | `FOREIGN KEY` | `FOREIGN KEY (meal_log_entry_id) REFERENCES meal_log_entries(id) ON DELETE CASCADE` |
| `meal_log_item_snapshots_entry_position_key` | `UNIQUE` | `UNIQUE (meal_log_entry_id, "position")` |
| `meal_log_item_snapshots_brand_name_nonblank` | `CHECK` | `CHECK (brand_name IS NULL OR btrim(brand_name) <> ''::text)` |
| `meal_log_item_snapshots_display_name_nonblank` | `CHECK` | `CHECK (btrim(display_name) <> ''::text)` |
| `meal_log_item_snapshots_nutrition_snapshot_valid` | `CHECK` | `CHECK (private.is_valid_nutrition_snapshot_v1(nutrition_snapshot))` |
| `meal_log_item_snapshots_position_nonnegative` | `CHECK` | `CHECK ("position" >= 0)` |
| `meal_log_item_snapshots_quantity_positive_finite` | `CHECK` | `CHECK (quantity > 0::numeric AND quantity < 'Infinity'::numeric)` |
| `meal_log_item_snapshots_serving_unit_nonblank` | `CHECK` | `CHECK (btrim(serving_unit) <> ''::text)` |
| `trg_meal_log_item_snapshots_parent_cardinality` | `TRIGGER` | `TRIGGER DEFERRABLE INITIALLY DEFERRED` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `meal_log_item_snapshots_entry_position_key` | `CREATE UNIQUE INDEX meal_log_item_snapshots_entry_position_key ON public.meal_log_item_snapshots USING btree (meal_log_entry_id, "position")` |
| `meal_log_item_snapshots_pkey` | `CREATE UNIQUE INDEX meal_log_item_snapshots_pkey ON public.meal_log_item_snapshots USING btree (id)` |

### `public.onboarding_drafts`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `user_id` | `uuid` | No | — |
| `schema_version` | `integer` | No | `1` |
| `payload` | `jsonb` | No | — |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `onboarding_drafts_pkey` | `PRIMARY KEY` | `PRIMARY KEY (user_id)` |
| `onboarding_drafts_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `idx_onboarding_drafts_updated_at` | `CREATE INDEX idx_onboarding_drafts_updated_at ON public.onboarding_drafts USING btree (updated_at)` |
| `idx_onboarding_drafts_user_id` | `CREATE INDEX idx_onboarding_drafts_user_id ON public.onboarding_drafts USING btree (user_id)` |
| `onboarding_drafts_pkey` | `CREATE UNIQUE INDEX onboarding_drafts_pkey ON public.onboarding_drafts USING btree (user_id)` |

### `public.user_app_preferences`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `user_id` | `uuid` | No | — |
| `app_mode` | `text` | Yes | — |
| `active_tabs` | `text[]` | Yes | — |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_app_preferences_pkey` | `PRIMARY KEY` | `PRIMARY KEY (user_id)` |
| `user_app_preferences_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` |
| `user_app_preferences_active_tabs_check` | `CHECK` | `CHECK (active_tabs IS NULL OR COALESCE(array_ndims(active_tabs), 1) = 1 AND array_position(active_tabs, NULL::text) IS NULL)` |
| `user_app_preferences_mode_check` | `CHECK` | `CHECK (app_mode IS NULL OR (app_mode = ANY (ARRAY['workout'::text, 'nutrition'::text, 'hybrid'::text])))` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `user_app_preferences_pkey` | `CREATE UNIQUE INDEX user_app_preferences_pkey ON public.user_app_preferences USING btree (user_id)` |

### `public.user_body_goals`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` |
| `user_id` | `uuid` | No | — |
| `goal_type` | `text` | No | — |
| `starting_weight_kg` | `numeric` | Yes | — |
| `target_weight_kg` | `numeric` | Yes | — |
| `weekly_weight_change_kg` | `numeric` | Yes | — |
| `intent_rank` | `smallint` | Yes | — |
| `status` | `text` | No | `'active'::text` |
| `started_at` | `timestamp with time zone` | Yes | — |
| `ended_at` | `timestamp with time zone` | Yes | — |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_body_goals_pkey` | `PRIMARY KEY` | `PRIMARY KEY (id)` |
| `user_body_goals_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` |
| `user_body_goals_end_after_start` | `CHECK` | `CHECK (ended_at IS NULL OR started_at IS NULL OR ended_at >= started_at)` |
| `user_body_goals_intent_rank_check` | `CHECK` | `CHECK (intent_rank IS NULL OR (intent_rank = ANY (ARRAY[1, 2])))` |
| `user_body_goals_nondirectional_followups_null` | `CHECK` | `CHECK ((goal_type = ANY (ARRAY['lose_weight'::text, 'gain_weight'::text])) OR target_weight_kg IS NULL AND weekly_weight_change_kg IS NULL)` |
| `user_body_goals_starting_weight_positive` | `CHECK` | `CHECK (starting_weight_kg IS NULL OR starting_weight_kg > 0::numeric)` |
| `user_body_goals_status_check` | `CHECK` | `CHECK (status = ANY (ARRAY['active'::text, 'completed'::text, 'cancelled'::text, 'superseded'::text]))` |
| `user_body_goals_target_weight_positive` | `CHECK` | `CHECK (target_weight_kg IS NULL OR target_weight_kg > 0::numeric)` |
| `user_body_goals_type_check` | `CHECK` | `CHECK (goal_type = ANY (ARRAY['lose_weight'::text, 'gain_weight'::text, 'maintain_weight'::text, 'recomposition'::text]))` |
| `user_body_goals_weekly_change_nonnegative` | `CHECK` | `CHECK (weekly_weight_change_kg IS NULL OR weekly_weight_change_kg >= 0::numeric)` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `idx_user_body_goals_user_created_at` | `CREATE INDEX idx_user_body_goals_user_created_at ON public.user_body_goals USING btree (user_id, created_at DESC)` |
| `uq_user_body_goals_one_active` | `CREATE UNIQUE INDEX uq_user_body_goals_one_active ON public.user_body_goals USING btree (user_id) WHERE (status = 'active'::text)` |
| `user_body_goals_pkey` | `CREATE UNIQUE INDEX user_body_goals_pkey ON public.user_body_goals USING btree (id)` |

### `public.user_devices`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` |
| `user_id` | `uuid` | No | — |
| `device_id` | `text` | No | — |
| `device_fingerprint` | `text` | No | — |
| `platform` | `text` | Yes | — |
| `os_version` | `text` | Yes | — |
| `last_active_at` | `timestamp with time zone` | No | `now()` |
| `created_at` | `timestamp with time zone` | No | `now()` |
| `last_login_at` | `timestamp with time zone` | Yes | `timezone('utc'::text, now())` |
| `app_build` | `integer` | Yes | — |
| `fcm_token` | `text` | Yes | — |
| `app_version` | `text` | Yes | — |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_devices_pkey` | `PRIMARY KEY` | `PRIMARY KEY (id)` |
| `user_devices_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE` |
| `user_devices_user_id_device_id_key` | `UNIQUE` | `UNIQUE (user_id, device_id)` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `idx_user_devices_device_id` | `CREATE INDEX idx_user_devices_device_id ON public.user_devices USING btree (device_id)` |
| `idx_user_devices_last_active_at` | `CREATE INDEX idx_user_devices_last_active_at ON public.user_devices USING btree (last_active_at DESC NULLS LAST)` |
| `idx_user_devices_last_login_at` | `CREATE INDEX idx_user_devices_last_login_at ON public.user_devices USING btree (last_login_at)` |
| `idx_user_devices_user_id` | `CREATE INDEX idx_user_devices_user_id ON public.user_devices USING btree (user_id)` |
| `user_devices_pkey` | `CREATE UNIQUE INDEX user_devices_pkey ON public.user_devices USING btree (id)` |
| `user_devices_user_id_device_id_key` | `CREATE UNIQUE INDEX user_devices_user_id_device_id_key ON public.user_devices USING btree (user_id, device_id)` |

### `public.user_nutrition_profiles`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `user_id` | `uuid` | No | — |
| `preferred_diet` | `character varying` | Yes | — |
| `allergies` | `text[]` | Yes | `'{}'::text[]` |
| `disliked_foods` | `text[]` | Yes | `'{}'::text[]` |
| `medical_conditions` | `text[]` | Yes | `'{}'::text[]` |
| `updated_at` | `timestamp with time zone` | Yes | `now()` |
| `other_diet_type` | `text` | Yes | — |
| `other_allergy_restriction` | `text` | Yes | — |
| `meal_categories_config` | `jsonb` | Yes | — |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_nutrition_profiles_pkey` | `PRIMARY KEY` | `PRIMARY KEY (user_id)` |
| `user_nutrition_profiles_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE` |
| `user_nutrition_profiles_meal_categories_config_valid` | `CHECK` | `CHECK (meal_categories_config IS NULL OR private.is_valid_meal_categories_config_v1(meal_categories_config))` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `idx_user_nutrition_profiles_user_id` | `CREATE INDEX idx_user_nutrition_profiles_user_id ON public.user_nutrition_profiles USING btree (user_id)` |
| `user_nutrition_profiles_pkey` | `CREATE UNIQUE INDEX user_nutrition_profiles_pkey ON public.user_nutrition_profiles USING btree (user_id)` |

### `public.user_nutrition_targets`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `user_id` | `uuid` | No | — |
| `calories_kcal` | `integer` | Yes | — |
| `protein_grams` | `numeric` | Yes | — |
| `carbohydrate_grams` | `numeric` | Yes | — |
| `fat_grams` | `numeric` | Yes | — |
| `fiber_grams` | `numeric` | Yes | — |
| `customization_state` | `text` | No | `'unknown'::text` |
| `customized_fields` | `text[]` | No | `'{}'::text[]` |
| `recommendation_metadata` | `jsonb` | No | `'{}'::jsonb` |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `additional_nutrient_goals` | `jsonb` | Yes | — |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_nutrition_targets_pkey` | `PRIMARY KEY` | `PRIMARY KEY (user_id)` |
| `user_nutrition_targets_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` |
| `user_nutrition_targets_additional_goals_object` | `CHECK` | `CHECK (additional_nutrient_goals IS NULL OR jsonb_typeof(additional_nutrient_goals) = 'object'::text)` |
| `user_nutrition_targets_calories_positive` | `CHECK` | `CHECK (calories_kcal IS NULL OR calories_kcal > 0)` |
| `user_nutrition_targets_carbs_nonnegative` | `CHECK` | `CHECK (carbohydrate_grams IS NULL OR carbohydrate_grams >= 0::numeric)` |
| `user_nutrition_targets_customization_state_check` | `CHECK` | `CHECK (customization_state = ANY (ARRAY['unknown'::text, 'recommended'::text, 'custom'::text, 'mixed'::text]))` |
| `user_nutrition_targets_fat_nonnegative` | `CHECK` | `CHECK (fat_grams IS NULL OR fat_grams >= 0::numeric)` |
| `user_nutrition_targets_fiber_nonnegative` | `CHECK` | `CHECK (fiber_grams IS NULL OR fiber_grams >= 0::numeric)` |
| `user_nutrition_targets_metadata_object` | `CHECK` | `CHECK (jsonb_typeof(recommendation_metadata) = 'object'::text)` |
| `user_nutrition_targets_protein_nonnegative` | `CHECK` | `CHECK (protein_grams IS NULL OR protein_grams >= 0::numeric)` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `user_nutrition_targets_pkey` | `CREATE UNIQUE INDEX user_nutrition_targets_pkey ON public.user_nutrition_targets USING btree (user_id)` |

### `public.user_profiles`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `user_id` | `uuid` | No | — |
| `name` | `text` | No | — |
| `gender` | `text` | Yes | — |
| `date_of_birth` | `date` | Yes | — |
| `height_cm` | `numeric` | Yes | — |
| `activity_level` | `text` | Yes | — |
| `health_conditions` | `text[]` | No | `'{}'::text[]` |
| `other_health_condition` | `text` | Yes | — |
| `unit_preferences` | `jsonb` | No | `'{"height": "cm", "volume": "ml", "weight": "kg", "distance": "km"}'::jsonb` |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `country_code` | `text` | Yes | — |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_profiles_pkey` | `PRIMARY KEY` | `PRIMARY KEY (user_id)` |
| `user_profiles_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` |
| `user_profiles_activity_level_check` | `CHECK` | `CHECK (activity_level IS NULL OR (activity_level = ANY (ARRAY['sedentary'::text, 'light'::text, 'active'::text, 'very_active'::text, 'dynamic'::text])))` |
| `user_profiles_country_code_check` | `CHECK` | `CHECK (country_code IS NULL OR country_code ~ '^[A-Z]{2}$'::text)` |
| `user_profiles_gender_check` | `CHECK` | `CHECK (gender IS NULL OR (gender = ANY (ARRAY['male'::text, 'female'::text, 'other'::text])))` |
| `user_profiles_health_conditions_check` | `CHECK` | `CHECK (health_conditions <@ ARRAY['none'::text, 'diabetes'::text, 'hypertension'::text, 'low_blood_pressure'::text, 'other'::text] AND array_position(health_conditions, NULL::text) IS NULL AND NOT (('none'::text = ANY (health_conditions)) AND cardinality(health_conditions) > 1))` |
| `user_profiles_height_positive` | `CHECK` | `CHECK (height_cm IS NULL OR height_cm > 0::numeric)` |
| `user_profiles_unit_preferences_check` | `CHECK` | `CHECK (COALESCE(jsonb_typeof(unit_preferences) = 'object'::text AND unit_preferences ?& ARRAY['weight'::text, 'height'::text, 'distance'::text, 'volume'::text] AND ((unit_preferences ->> 'weight'::text) = ANY (ARRAY['kg'::text, 'lb'::text])) AND ((unit_preferences ->> 'height'::text) = ANY (ARRAY['cm'::text, 'ft_in'::text])) AND ((unit_preferences ->> 'distance'::text) = ANY (ARRAY['km'::text, 'mi'::text])) AND ((unit_preferences ->> 'volume'::text) = ANY (ARRAY['ml'::text, 'fl_oz'::text])), false))` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `user_profiles_pkey` | `CREATE UNIQUE INDEX user_profiles_pkey ON public.user_profiles USING btree (user_id)` |

### `public.user_wellness_targets`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `user_id` | `uuid` | No | — |
| `steps_target` | `integer` | Yes | — |
| `water_target_ml` | `integer` | Yes | — |
| `sleep_target_minutes` | `integer` | Yes | — |
| `bed_time` | `time without time zone` | Yes | — |
| `wake_up_time` | `time without time zone` | Yes | — |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_wellness_targets_pkey` | `PRIMARY KEY` | `PRIMARY KEY (user_id)` |
| `user_wellness_targets_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` |
| `user_wellness_targets_sleep_nonnegative` | `CHECK` | `CHECK (sleep_target_minutes IS NULL OR sleep_target_minutes >= 0)` |
| `user_wellness_targets_steps_nonnegative` | `CHECK` | `CHECK (steps_target IS NULL OR steps_target >= 0)` |
| `user_wellness_targets_water_nonnegative` | `CHECK` | `CHECK (water_target_ml IS NULL OR water_target_ml >= 0)` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `user_wellness_targets_pkey` | `CREATE UNIQUE INDEX user_wellness_targets_pkey ON public.user_wellness_targets USING btree (user_id)` |

### `public.user_workout_exercises`

**RLS:** Enabled

**Verified Data API access:** `anon` has no table privileges. `authenticated` has table `SELECT`, column-level `INSERT(id, user_id, display_name, based_on_catalog_exercise_id, description, exercise_type, primary_muscle, secondary_muscles, primary_equipment)`, and column-level `UPDATE(display_name, status, description, exercise_type, primary_muscle, secondary_muscles, primary_equipment)`; it has no table-wide `INSERT` / `UPDATE` and no `DELETE`. Owner-scoped `SELECT` / `INSERT` / `UPDATE` RLS policies are present with no authenticated `DELETE` policy. `service_role` retains full table CRUD.

**W3D2 live definition fields:** migration `20260930180700_add_custom_exercise_definition_fields.sql` is applied and hosted-verified. It adds nullable text `description`, `exercise_type`, `primary_muscle`, `primary_equipment`, plus `secondary_muscles text[] NOT NULL DEFAULT '{}'`. Existing W1B1 rows remain compatible with NULL scalars and an empty array. CHECK constraints enforce nonblank descriptions, the 11 stable Exercise Type tokens, the 44 approved muscle tokens (single primary, unique secondary array without nulls/primary overlap), and 18 equipment tokens. `private.valid_user_exercise_muscles` is an immutable SECURITY INVOKER validator with empty search_path and restricted EXECUTE.

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | `uuid` | No | — |
| `user_id` | `uuid` | No | — |
| `display_name` | `text` | No | — |
| `status` | `text` | No | `'active'::text` |
| `based_on_catalog_exercise_id` | `text` | Yes | — |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `description` | `text` | Yes | — |
| `exercise_type` | `text` | Yes | — |
| `primary_muscle` | `text` | Yes | — |
| `secondary_muscles` | `text[]` | No | `'{}'::text[]` |
| `primary_equipment` | `text` | Yes | — |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_workout_exercises_catalog_lineage_format_check` | `CHECK` | `CHECK (based_on_catalog_exercise_id IS NULL OR based_on_catalog_exercise_id ~ '^ex_[a-z0-9]+(?:_[a-z0-9]+)*$'::text)` |
| `user_workout_exercises_description_nonblank` | `CHECK` | description is NULL or contains a non-whitespace character |
| `user_workout_exercises_display_name_nonblank` | `CHECK` | `CHECK ((btrim(display_name) <> ''::text))` |
| `user_workout_exercises_equipment_check` | `CHECK` | primary equipment is NULL or one of the 18 approved equipment tokens |
| `user_workout_exercises_muscles_check` | `CHECK` | primary/secondary muscles satisfy the approved 44-token taxonomy, uniqueness and no-primary-overlap rules |
| `user_workout_exercises_type_check` | `CHECK` | exercise type is NULL or one of the 11 approved Exercise Type tokens |
| `user_workout_exercises_id_user_id_key` | `UNIQUE` | `UNIQUE (id, user_id)` |
| `user_workout_exercises_pkey` | `PRIMARY KEY` | `PRIMARY KEY (id)` |
| `user_workout_exercises_status_check` | `CHECK` | `CHECK ((status = ANY (ARRAY['active'::text, 'archived'::text])))` |
| `user_workout_exercises_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `idx_user_workout_exercises_user_status_created_at` | `CREATE INDEX idx_user_workout_exercises_user_status_created_at ON public.user_workout_exercises USING btree (user_id, status, created_at DESC)` |
| `user_workout_exercises_id_user_id_key` | `CREATE UNIQUE INDEX user_workout_exercises_id_user_id_key ON public.user_workout_exercises USING btree (id, user_id)` |
| `user_workout_exercises_pkey` | `CREATE UNIQUE INDEX user_workout_exercises_pkey ON public.user_workout_exercises USING btree (id)` |

### `public.user_workout_programs`

**RLS:** Enabled

**Data API access boundary:** Earlier verified access includes owner-scoped `SELECT`, `UPDATE(name)` and RLS; `authenticated` has no table-wide UPDATE or DELETE. The **checked-in deployed W1 migration** revokes table-wide authenticated INSERT and grants **column-level `INSERT(id, user_id, name)`** only, protecting the server-owned `is_default` marker. The narrower INSERT statement is grounded in migration source and the W1 deployment receipt; a standalone **2026-10-20 table/column ACL metadata query was not independently completed** in this inventory audit. Owner RLS remains; no authenticated DELETE policy was added. `service_role` access is unchanged by the W1 migration.

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | `uuid` | No | — |
| `user_id` | `uuid` | No | — |
| `name` | `text` | No | — |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `is_default` | `boolean` | No | `false` |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_workout_programs_id_user_id_key` | `UNIQUE` | `UNIQUE (id, user_id)` |
| `user_workout_programs_name_nonblank` | `CHECK` | `CHECK ((btrim(name) <> ''::text))` |
| `user_workout_programs_pkey` | `PRIMARY KEY` | `PRIMARY KEY (id)` |
| `user_workout_programs_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `idx_user_workout_programs_owner_default` | `CREATE UNIQUE INDEX idx_user_workout_programs_owner_default ON public.user_workout_programs USING btree (user_id) WHERE is_default` |
| `idx_user_workout_programs_user_created_at` | `CREATE INDEX idx_user_workout_programs_user_created_at ON public.user_workout_programs USING btree (user_id, created_at DESC)` |
| `user_workout_programs_id_user_id_key` | `CREATE UNIQUE INDEX user_workout_programs_id_user_id_key ON public.user_workout_programs USING btree (id, user_id)` |
| `user_workout_programs_pkey` | `CREATE UNIQUE INDEX user_workout_programs_pkey ON public.user_workout_programs USING btree (id)` |

### `public.user_workout_routines`

**RLS:** Enabled

**Data API access boundary (2026-10-20):** `authenticated` retains SELECT and narrow column-level INSERT on the original six metadata columns (`id`, `user_id`, `program_id`, `name`, `created_at`, `updated_at`); **direct UPDATE, including `UPDATE(name)`, is retired** by the applied `20261017154241_retire_legacy_routine_name_update.sql` migration. That migration revokes the column grant and fails closed unless neither table-wide nor name/program ownership column UPDATE is available while protected RPC access is preserved. Owner SELECT/INSERT/UPDATE RLS policies may remain, but an RLS UPDATE policy **does not grant Data API UPDATE privileges**. Direct client revision/mutation-hash writes, Routine DELETE, renames and moves are denied. Atomic composition, Create, Name+composition Update and Delete instead use their owner-guarded RPC contracts below. This privilege statement is supported by the checked-in deployed fail-closed migration and the 66/66 applied ledger; **a separate live Routine table/column ACL query was not completed** in this review. RPC existence does not imply Move/Workout Start UI activation or a device release.

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | `uuid` | No | — |
| `user_id` | `uuid` | No | — |
| `program_id` | `uuid` | No | — |
| `name` | `text` | No | — |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `composition_revision` | `bigint` | No | `0` |
| `last_composition_mutation_id` | `uuid` | Yes | — |
| `last_routine_update_request_hash` | `bytea` | Yes | — |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_workout_routines_composition_revision_nonnegative` | `CHECK` | `CHECK ((composition_revision >= 0))` |
| `user_workout_routines_id_user_id_key` | `UNIQUE` | `UNIQUE (id, user_id)` |
| `user_workout_routines_name_nonblank` | `CHECK` | `CHECK ((btrim(name) <> ''::text))` |
| `user_workout_routines_pkey` | `PRIMARY KEY` | `PRIMARY KEY (id)` |
| `user_workout_routines_program_owner_fkey` | `FOREIGN KEY` | `FOREIGN KEY (program_id, user_id) REFERENCES user_workout_programs(id, user_id) ON DELETE CASCADE` |
| `user_workout_routines_update_hash_length` | `CHECK` | `CHECK (last_routine_update_request_hash IS NULL OR octet_length(last_routine_update_request_hash) = 32)` |
| `user_workout_routines_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `idx_user_workout_routines_user_program_created_at` | `CREATE INDEX idx_user_workout_routines_user_program_created_at ON public.user_workout_routines USING btree (user_id, program_id, created_at DESC)` |
| `user_workout_routines_id_user_id_key` | `CREATE UNIQUE INDEX user_workout_routines_id_user_id_key ON public.user_workout_routines USING btree (id, user_id)` |
| `user_workout_routines_pkey` | `CREATE UNIQUE INDEX user_workout_routines_pkey ON public.user_workout_routines USING btree (id)` |

### `public.user_workout_routine_exercises`

**RLS:** Enabled

**Verified Data API access:** `authenticated` has SELECT only, restricted by the sole owner SELECT RLS policy (`user_id = (select auth.uid())`). No direct INSERT/UPDATE/DELETE grants or write policies; no anon/PUBLIC table or column privileges. Composition writes use the narrow RPC below.

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | `uuid` | No | — |
| `user_id` | `uuid` | No | — |
| `routine_id` | `uuid` | No | — |
| `position` | `integer` | No | — |
| `catalog_exercise_id` | `text` | Yes | — |
| `user_exercise_id` | `uuid` | Yes | — |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_workout_routine_exercises_catalog_ref_format` | `CHECK` | `CHECK (((catalog_exercise_id IS NULL) OR (catalog_exercise_id ~ '^ex_[a-z0-9]+(?:_[a-z0-9]+)*$'::text)))` |
| `user_workout_routine_exercises_id_user_id_key` | `UNIQUE` | `UNIQUE (id, user_id)` |
| `user_workout_routine_exercises_owner_fkey` | `FOREIGN KEY` | `FOREIGN KEY (routine_id, user_id) REFERENCES user_workout_routines(id, user_id) ON DELETE CASCADE` |
| `user_workout_routine_exercises_pkey` | `PRIMARY KEY` | `PRIMARY KEY (id)` |
| `user_workout_routine_exercises_position_key` | `UNIQUE` | `UNIQUE (routine_id, user_id, "position")` |
| `user_workout_routine_exercises_position_nonnegative` | `CHECK` | `CHECK (("position" >= 0))` |
| `user_workout_routine_exercises_reference_exclusive` | `CHECK` | `CHECK (((catalog_exercise_id IS NOT NULL) <> (user_exercise_id IS NOT NULL)))` |
| `user_workout_routine_exercises_user_exercise_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_exercise_id, user_id) REFERENCES user_workout_exercises(id, user_id) DEFERRABLE INITIALLY DEFERRED` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `idx_user_workout_routine_exercises_custom_fk` | `CREATE INDEX idx_user_workout_routine_exercises_custom_fk ON public.user_workout_routine_exercises USING btree (user_exercise_id, user_id) WHERE (user_exercise_id IS NOT NULL)` |
| `user_workout_routine_exercises_id_user_id_key` | `CREATE UNIQUE INDEX user_workout_routine_exercises_id_user_id_key ON public.user_workout_routine_exercises USING btree (id, user_id)` |
| `user_workout_routine_exercises_pkey` | `CREATE UNIQUE INDEX user_workout_routine_exercises_pkey ON public.user_workout_routine_exercises USING btree (id)` |
| `user_workout_routine_exercises_position_key` | `CREATE UNIQUE INDEX user_workout_routine_exercises_position_key ON public.user_workout_routine_exercises USING btree (routine_id, user_id, "position")` |

### `public.user_workout_routine_sets`

**RLS:** Enabled

**Verified Data API access:** `authenticated` has SELECT only, restricted by the sole owner SELECT RLS policy (`user_id = (select auth.uid())`). No direct INSERT/UPDATE/DELETE grants or write policies; no anon/PUBLIC table or column privileges. Composition writes use the narrow RPC below.

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | `uuid` | No | — |
| `user_id` | `uuid` | No | — |
| `routine_exercise_id` | `uuid` | No | — |
| `position` | `integer` | No | — |
| `reps` | `integer` | Yes | — |
| `load_kg` | `double precision` | Yes | — |
| `rest_seconds` | `integer` | Yes | — |
| `set_type` | `text` | No | `'normal'::text` |
| `reps_max` | `integer` | Yes | — |
| `distance_meters` | `double precision` | Yes | — |
| `duration_seconds` | `integer` | Yes | — |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_workout_routine_sets_distance_nonnegative_finite` | `CHECK` | `CHECK (distance_meters IS NULL OR distance_meters >= 0::double precision AND distance_meters < 'Infinity'::double precision AND distance_meters <> 'NaN'::double precision)` |
| `user_workout_routine_sets_duration_nonnegative` | `CHECK` | `CHECK (duration_seconds IS NULL OR duration_seconds >= 0)` |
| `user_workout_routine_sets_exercise_owner_fkey` | `FOREIGN KEY` | `FOREIGN KEY (routine_exercise_id, user_id) REFERENCES user_workout_routine_exercises(id, user_id) ON DELETE CASCADE` |
| `user_workout_routine_sets_load_nonnegative_finite` | `CHECK` | `CHECK (((load_kg IS NULL) OR ((load_kg >= (0)::double precision) AND (load_kg < 'Infinity'::double precision) AND (load_kg <> 'NaN'::double precision))))` |
| `user_workout_routine_sets_max_eight_position` | `CHECK` | `CHECK ("position" < 8) NOT VALID` |
| `user_workout_routine_sets_pkey` | `PRIMARY KEY` | `PRIMARY KEY (id)` |
| `user_workout_routine_sets_position_key` | `UNIQUE` | `UNIQUE (routine_exercise_id, user_id, "position")` |
| `user_workout_routine_sets_position_nonnegative` | `CHECK` | `CHECK (("position" >= 0))` |
| `user_workout_routine_sets_reps_max_valid` | `CHECK` | `CHECK (reps_max IS NULL OR reps IS NOT NULL AND reps_max >= reps AND reps_max > 0)` |
| `user_workout_routine_sets_reps_positive` | `CHECK` | `CHECK ((reps > 0))` |
| `user_workout_routine_sets_rest_nonnegative` | `CHECK` | `CHECK (((rest_seconds IS NULL) OR (rest_seconds >= 0)))` |
| `user_workout_routine_sets_set_type_allowed` | `CHECK` | `CHECK (set_type = ANY (ARRAY['normal'::text, 'warm_up'::text, 'failure'::text, 'drop'::text]))` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `user_workout_routine_sets_pkey` | `CREATE UNIQUE INDEX user_workout_routine_sets_pkey ON public.user_workout_routine_sets USING btree (id)` |
| `user_workout_routine_sets_position_key` | `CREATE UNIQUE INDEX user_workout_routine_sets_position_key ON public.user_workout_routine_sets USING btree (routine_exercise_id, user_id, "position")` |

**Constraint-validation boundary:** `user_workout_routine_sets_max_eight_position` was installed `NOT VALID` and remains `convalidated = false` in the verified live catalog. It is not evidence that historical rows have been validated. The other five new CHECK constraints are validated. Nullable `reps` is intentional; the retained `CHECK (reps > 0)` does not prohibit SQL NULL.

### `public.user_workout_profiles`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `user_id` | `uuid` | No | — |
| `experience_level` | `character varying` | Yes | — |
| `workout_location` | `character varying` | Yes | — |
| `available_equipment` | `text[]` | Yes | `'{}'::text[]` |
| `focus_areas` | `text[]` | Yes | `'{}'::text[]` |
| `health_concerns` | `text[]` | Yes | `'{}'::text[]` |
| `updated_at` | `timestamp with time zone` | Yes | `timezone('utc'::text, now())` |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_workout_profiles_pkey` | `PRIMARY KEY` | `PRIMARY KEY (user_id)` |
| `user_workout_profiles_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `idx_user_workout_profiles_user_id` | `CREATE INDEX idx_user_workout_profiles_user_id ON public.user_workout_profiles USING btree (user_id)` |
| `user_workout_profiles_pkey` | `CREATE UNIQUE INDEX user_workout_profiles_pkey ON public.user_workout_profiles USING btree (user_id)` |

### `public.user_workout_targets`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `user_id` | `uuid` | No | — |
| `primary_workout_goal` | `text` | Yes | — |
| `primary_goal_rank` | `smallint` | Yes | — |
| `supporting_workout_goal` | `text` | Yes | — |
| `supporting_goal_rank` | `smallint` | Yes | — |
| `training_days` | `text[]` | No | `'{}'::text[]` |
| `preferred_duration_mins` | `integer` | Yes | — |
| `split_program` | `text` | Yes | — |
| `special_event` | `text` | Yes | — |
| `special_event_date` | `date` | Yes | — |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_workout_targets_pkey` | `PRIMARY KEY` | `PRIMARY KEY (user_id)` |
| `user_workout_targets_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` |
| `user_workout_targets_distinct_goals` | `CHECK` | `CHECK (supporting_workout_goal IS NULL OR primary_workout_goal IS NULL OR supporting_workout_goal <> primary_workout_goal)` |
| `user_workout_targets_distinct_known_ranks` | `CHECK` | `CHECK (primary_goal_rank IS NULL OR supporting_goal_rank IS NULL OR primary_goal_rank <> supporting_goal_rank)` |
| `user_workout_targets_duration_positive` | `CHECK` | `CHECK (preferred_duration_mins IS NULL OR preferred_duration_mins > 0)` |
| `user_workout_targets_primary_goal_check` | `CHECK` | `CHECK (primary_workout_goal IS NULL OR (primary_workout_goal = ANY (ARRAY['build_muscle'::text, 'get_stronger'::text, 'improve_endurance'::text, 'stay_fit'::text])))` |
| `user_workout_targets_primary_rank_check` | `CHECK` | `CHECK (primary_goal_rank IS NULL OR (primary_goal_rank = ANY (ARRAY[1, 2])))` |
| `user_workout_targets_primary_rank_requires_goal` | `CHECK` | `CHECK (primary_goal_rank IS NULL OR primary_workout_goal IS NOT NULL)` |
| `user_workout_targets_support_requires_primary` | `CHECK` | `CHECK (supporting_workout_goal IS NULL OR primary_workout_goal IS NOT NULL)` |
| `user_workout_targets_supporting_goal_check` | `CHECK` | `CHECK (supporting_workout_goal IS NULL OR (supporting_workout_goal = ANY (ARRAY['build_muscle'::text, 'get_stronger'::text, 'improve_endurance'::text, 'stay_fit'::text])))` |
| `user_workout_targets_supporting_rank_check` | `CHECK` | `CHECK (supporting_goal_rank IS NULL OR (supporting_goal_rank = ANY (ARRAY[1, 2])))` |
| `user_workout_targets_supporting_rank_requires_goal` | `CHECK` | `CHECK (supporting_goal_rank IS NULL OR supporting_workout_goal IS NOT NULL)` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `user_workout_targets_pkey` | `CREATE UNIQUE INDEX user_workout_targets_pkey ON public.user_workout_targets USING btree (user_id)` |

### `public.users`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | `uuid` | No | — |
| `username` | `text` | Yes | — |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `avatar_url` | `text` | Yes | — |
| `plan` | `text` | No | `'free'::text` |
| `firebase_uid` | `character varying` | Yes | — |
| `email` | `character varying` | Yes | — |
| `mobile` | `character varying` | Yes | — |
| `timezone` | `character varying` | Yes | — |
| `is_onboarded` | `boolean` | Yes | `false` |
| `current_streak` | `integer` | Yes | `0` |
| `best_streak` | `integer` | Yes | `0` |
| `referral_code` | `character varying` | Yes | — |
| `referred_by_id` | `uuid` | Yes | — |
| `is_active` | `boolean` | Yes | `true` |
| `deleted_at` | `timestamp with time zone` | Yes | — |
| `last_active_at` | `timestamp with time zone` | Yes | — |
| `mobile_verified_at` | `timestamp with time zone` | Yes | — |
| `account_setup_completed_at` | `timestamp with time zone` | Yes | — |
| `email_verified_at` | `timestamp with time zone` | Yes | — |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `users_pkey` | `PRIMARY KEY` | `PRIMARY KEY (id)` |
| `users_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE` |
| `users_username_key` | `UNIQUE` | `UNIQUE (username)` |
| `users_username_policy_check` | `CHECK` | `CHECK (username IS NULL OR username = lower(username) AND length(username) >= 3 AND length(username) <= 30 AND username ~ '^[a-z0-9._]+$'::text AND (lower(username) <> ALL (ARRAY['admin'::text, 'administrator'::text, 'support'::text, 'help'::text, 'security'::text, 'billing'::text, 'official'::text, 'moderator'::text, 'mod'::text, 'root'::text, 'system'::text, 'staff'::text, 'tio'::text, 'tioworld'::text, 'tioofficial'::text])) AND username !~ '^(admin\|administrator\|support\|help\|security\|billing\|official\|moderator\|mod\|root\|system\|staff)[._].+$'::text AND username !~ '^tio[._]?(admin\|administrator\|support\|help\|security\|billing\|official\|moderator\|mod\|root\|system\|staff)$'::text AND username !~ '^(admin\|administrator\|support\|help\|security\|billing\|official\|moderator\|mod\|root\|system\|staff)[._]?tio$'::text)` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `idx_users_active_onboarded` | `CREATE INDEX idx_users_active_onboarded ON public.users USING btree (id) WHERE ((is_active = true) AND (is_onboarded = true))` |
| `idx_users_created_at` | `CREATE INDEX idx_users_created_at ON public.users USING btree (created_at)` |
| `idx_users_email_lower` | `CREATE INDEX idx_users_email_lower ON public.users USING btree (lower((email)::text)) WHERE (email IS NOT NULL)` |
| `idx_users_mobile` | `CREATE INDEX idx_users_mobile ON public.users USING btree (mobile) WHERE (mobile IS NOT NULL)` |
| `idx_users_referral_code` | `CREATE INDEX idx_users_referral_code ON public.users USING btree (referral_code) WHERE (referral_code IS NOT NULL)` |
| `idx_users_referred_by_id` | `CREATE INDEX idx_users_referred_by_id ON public.users USING btree (referred_by_id) WHERE (referred_by_id IS NOT NULL)` |
| `idx_users_username_lower` | `CREATE UNIQUE INDEX idx_users_username_lower ON public.users USING btree (lower(username))` |
| `users_pkey` | `CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id)` |
| `users_username_key` | `CREATE UNIQUE INDEX users_username_key ON public.users USING btree (username)` |
| `users_verified_email_identity_uidx` | `CREATE UNIQUE INDEX users_verified_email_identity_uidx ON public.users USING btree (private.canonical_email_identity((email)::text)) WHERE (email_verified_at IS NOT NULL)` |
| `users_verified_mobile_uidx` | `CREATE UNIQUE INDEX users_verified_mobile_uidx ON public.users USING btree (mobile) WHERE (mobile_verified_at IS NOT NULL)` |

## Routine Composition RPC

RPC signatures and return types were inspected on **2026-10-20**. The `authenticated` EXECUTE and other client-role privileges shown below were **reverified live on 2026-10-21** after the combined #568/#569 hosted deployment:

| Function | Argument types (in order) | Returns | `authenticated` EXECUTE |
| :--- | :--- | :--- | :---: |
| `save_user_workout_routine_composition` | `uuid, bigint, uuid, jsonb` | `bigint` | Yes |
| `create_user_workout_routine_with_composition` | `uuid, uuid, text, uuid, jsonb` | `bigint` | Yes |
| `update_user_workout_routine_with_composition` | `uuid, uuid, bigint, text, uuid, text, jsonb` | `bigint` | Yes |
| `delete_user_workout_routine` | `uuid, uuid, bigint` | `boolean` | Yes |
| `move_user_workout_routine` | `uuid, uuid, uuid, bigint, uuid` | `bigint` | **No — dormant** |
| `create_user_workout_program_and_move_routine` | `uuid, uuid, uuid, text, bigint, uuid` | `bigint` | **No — dormant** |
| `create_user_workout_routine_in_my_program` | `uuid, text, uuid, jsonb` | `jsonb` | **Yes — API granted; Flutter release OFF** |

Read-only catalog inspection confirms **SECURITY DEFINER**, empty `search_path` and denied `anon`/`PUBLIC` EXECUTE on **all seven** RPCs. The four existing composition/Create/Update/Delete RPCs and the #568 `create_user_workout_routine_in_my_program` RPC now permit `authenticated` EXECUTE; the latter is directly callable via authenticated REST by eligible permanent owners even though Flutter's `myProgramRoutineCreateReleaseEnabledProvider` is hard `false`. Only the two #569 Move/Create+Move RPCs remain `authenticated`/`service_role` EXECUTE-denied, and `routineMoveReleaseEnabledProvider` remains hard `false`. The first-Routine grant is a real privileged backend boundary, **not** a verified mobile release or real-write QA pass. The current checked-in migrations define the server ownership, revision/atomicity and anti-resurrection contracts. The Routine Delete implementation retires deleted Routine IDs in private `private.deleted_user_workout_routine_ids` (not an ordinary `public` table). No direct authenticated Routine table DELETE is authorized by these RPC observations.

**Evidence boundary:** Live metadata verification establishes table structure, RPC signatures and RPC EXECUTE status; the W1 table/column ACL description is additionally source-backed but was not independently queried successfully in this pass. This inventory update did not execute mutating RPCs, retest concurrency, validate existing rows against the `NOT VALID` Set position constraint or establish a distributed phone-app release. Workout Start, Routine Move release, programless first-Routine UI and device QA are tracked by live GitHub/Linear and runtime source, not by this catalog.

## Maintenance Rule

When a schema migration changes any documented table, column, default, constraint, index, or RLS enabled/disabled state:

1. apply and validate the migration through the normal Supabase workflow;
2. verify the deployed live metadata;
3. refresh this inventory in the same bounded documentation follow-up or schema-change lifecycle;
4. do not copy row data into this document.

Historical applied migrations remain immutable records; do not rewrite old migration files merely to make this inventory match a newer structure.
