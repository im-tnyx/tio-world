-- Persist the "Other" free-text elaboration for canonical Nutrition Profile.
--
-- Product Onboarding already collects this text (NutritionOnboardingDraft
-- .otherDietType / .otherAllergyRestriction) but had nowhere to store it, so
-- NutritionProfileMapper discarded it at completion. A bare `other` token
-- records that a restriction exists without recording what it is, which a diet
-- plan cannot act on safely.
--
-- Naming and shape follow the existing house pattern for this concept,
-- `users.other_health_condition TEXT`.
--
-- Additive and idempotent: both columns are nullable with no default, no
-- existing column is altered or dropped, and RLS is unchanged.

ALTER TABLE public.user_nutrition_profiles
    ADD COLUMN IF NOT EXISTS other_diet_type TEXT,
    ADD COLUMN IF NOT EXISTS other_allergy_restriction TEXT;

COMMENT ON COLUMN public.user_nutrition_profiles.other_diet_type IS
    'Free-text diet elaboration. Meaningful only while preferred_diet = ''other''; NULL when unanswered or left blank.';

COMMENT ON COLUMN public.user_nutrition_profiles.other_allergy_restriction IS
    'Free-text allergy/restriction elaboration. Meaningful only while allergies contains ''other''; NULL when unanswered or left blank.';
