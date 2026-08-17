-- Add sleep_target_minutes column to user_nutrition_profiles idempotently
ALTER TABLE public.user_nutrition_profiles
    ADD COLUMN IF NOT EXISTS sleep_target_minutes INTEGER;

-- Add check constraint for realistic sleep duration in minutes (4 hours to 12 hours = 240..720)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'check_user_nutrition_profiles_sleep_target'
    ) THEN
        ALTER TABLE public.user_nutrition_profiles
            ADD CONSTRAINT check_user_nutrition_profiles_sleep_target
            CHECK (sleep_target_minutes IS NULL OR (sleep_target_minutes >= 240 AND sleep_target_minutes <= 720));
    END IF;
END $$;

COMMENT ON COLUMN public.user_nutrition_profiles.sleep_target_minutes IS
    'Target daily sleep duration in minutes (e.g. 480 for 8 hours, 450 for 7.5 hours). Stored independently from bed/wake times.';
