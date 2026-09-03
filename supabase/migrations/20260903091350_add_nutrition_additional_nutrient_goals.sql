-- Persist Additional Nutrient Goals V1 for canonical Nutrition Targets.
--
-- TNYX-141 adds four owner-authorized goals (saturated_fat, trans_fat, sodium,
-- vitamin_d) on top of the existing five core targets. Only configuration and
-- explicit override intent is stored: recommended values are runtime
-- derivations of canonical Calories and Profile date of birth, so persisting
-- them would create a second, immediately stale source of truth.
--
-- Shape is a single versioned JSONB envelope rather than per-nutrient columns
-- or a child table, because the set is expected to grow and the goal state per
-- nutrient is one nullable number:
--
--   {"schema_version": 1, "goals": {"sodium": {"custom_value": null}}}
--
-- Semantics the client depends on:
--   column NULL                     -> no Additional Nutrient Goals payload
--   schema_version 1 + goals {}     -> valid V1 payload, nothing configured
--   nutrient key absent             -> not configured
--   key present, custom_value null  -> configured, uses the recommendation
--   key present, numeric value      -> configured, explicit override
--   custom_value 0                  -> explicit zero, not "unset"
--
-- The check constrains only the envelope's outermost type. Per-nutrient
-- validation stays in the client codec so that a newer client can add keys
-- this database version has never heard of without a migration, and an older
-- client preserves them untouched.
--
-- Additive and idempotent: one nullable column with no default, no existing
-- column altered or dropped, no RLS, policy, trigger, RPC or view change.

ALTER TABLE public.user_nutrition_targets
    ADD COLUMN IF NOT EXISTS additional_nutrient_goals JSONB;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'public.user_nutrition_targets'::regclass
          AND conname = 'user_nutrition_targets_additional_goals_object'
    ) THEN
        ALTER TABLE public.user_nutrition_targets
            ADD CONSTRAINT user_nutrition_targets_additional_goals_object
            CHECK (
                additional_nutrient_goals IS NULL
                OR jsonb_typeof(additional_nutrient_goals) = 'object'
            );
    END IF;
END
$$;

COMMENT ON COLUMN public.user_nutrition_targets.additional_nutrient_goals IS
    'Versioned Additional Nutrient Goals envelope. NULL means no payload. Stores only configuration and explicit custom overrides; recommended values, units and eligibility remain runtime derivations.';
