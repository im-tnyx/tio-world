# Supabase Public Schema Inventory

Document Status: Canonical Live Doc
Last Verified: 2026-09-29
Owner: Supabase data ownership
Truth Boundary: Authoritative as a readable inventory of the verified current `public` schema; executable truth remains checked-in migrations plus verified live schema, and no user data belongs here.

## Status

**Canonical readable inventory of the current Tio-world Supabase `public` schema.**

Verified on **2026-09-29** against:

- repository base `main@71fef2c9e2393e89c4cf415799a5ae8f5e7e4d8a` plus the content-preserving Program migration identity reconciliation included with this inventory refresh;
- checked-in `supabase/migrations/` history;
- live Supabase project `tio-world` structural metadata.

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
| Active ordinary `public` tables | 15 |
| Columns | 152 |
| Primary-key constraints | 15 |
| Foreign-key constraints | 15 |
| Unique constraints | 4 |
| Check constraints | 55 |
| Constraint-trigger records | 2 |
| Total catalog constraint records | 91 |
| Indexes | 41 |
| Tables with RLS enabled | 15 / 15 |
| Partitioned tables | 0 |
| Views | 0 |
| Materialized views | 0 |
| Applied live migrations matched to repository | 50 / 50 |
| Repository-only pending migrations | 1 |

The verified live migration history currently ends at `20260929040034_create_user_workout_programs`. The repository also contains the newer, intentionally unapplied `20260929050000_create_user_workout_routines` migration; this inventory does not describe that future table until it is deployed and verified live.

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
| `public.user_workout_programs` | 5 | Enabled |
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

### `public.user_workout_programs`

**RLS:** Enabled

#### Columns

| Column | Type | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | `uuid` | No | — |
| `user_id` | `uuid` | No | — |
| `name` | `text` | No | — |
| `created_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |
| `updated_at` | `timestamp with time zone` | No | `timezone('utc'::text, now())` |

#### Constraints

| Name | Type | Definition |
| :--- | :--- | :--- |
| `user_workout_programs_pkey` | `PRIMARY KEY` | `PRIMARY KEY (id)` |
| `user_workout_programs_user_id_fkey` | `FOREIGN KEY` | `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` |
| `user_workout_programs_name_nonblank` | `CHECK` | `CHECK ((btrim(name) <> ''::text))` |

#### Indexes

| Name | Definition |
| :--- | :--- |
| `idx_user_workout_programs_user_created_at` | `CREATE INDEX idx_user_workout_programs_user_created_at ON public.user_workout_programs USING btree (user_id, created_at DESC)` |
| `user_workout_programs_pkey` | `CREATE UNIQUE INDEX user_workout_programs_pkey ON public.user_workout_programs USING btree (id)` |

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

## Maintenance Rule

When a schema migration changes any documented table, column, default, constraint, index, or RLS enabled/disabled state:

1. apply and validate the migration through the normal Supabase workflow;
2. verify the deployed live metadata;
3. refresh this inventory in the same bounded documentation follow-up or schema-change lifecycle;
4. do not copy row data into this document.

Historical applied migrations remain immutable records; do not rewrite old migration files merely to make this inventory match a newer structure.
