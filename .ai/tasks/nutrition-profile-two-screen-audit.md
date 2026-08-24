# #114 Nutrition Profile two-screen navigation audit

Status: ACTIVE

## Goal

Verify the real `OnboardingFlowPage` path for the frozen Nutrition Profile contract without changing canonical schema or adding new product questions.

Canonical child flow:

```text
Diet Type
→ Allergies & Restrictions
```

Frozen top-level boundaries from #106:

```text
Nutrition: Body Goal → Nutrition Profile → Wellness
Hybrid setupNow: Workout Targets → Nutrition Profile → Wellness
Hybrid later: Workout Intro → Nutrition Profile → Wellness
```

## Current source contract

- `NutritionProfileFlowPlan` owns exactly two children.
- page composition resolves the Nutrition-aware onboarding provider.
- Diet Type is single-select.
- Allergies & Restrictions is multi-select.
- `None` is mutually exclusive with real restrictions.
- `null` restrictions means unanswered; `{none}` means explicit none; empty set is incomplete.
- exact resume may begin on Allergies when that child cursor was actually persisted.

## Execution

1. Add a real `OnboardingFlowPage` regression proving fresh Nutrition Profile entry starts on Diet Type.
2. Prove Continue moves Diet Type → Allergies, then Allergies → Wellness.
3. Prove Back from Wellness returns to Allergies, then Back returns to Diet Type with answers preserved.
4. Prove Hybrid `later` enters Diet Type from Workout Intro.
5. Prove Hybrid `setupNow` enters Diet Type from Workout Targets.
6. If those tests pass on current production wiring, classify the one-screen device report as unreproduced by current source and make no production navigation change.
7. If a test fails, make only the smallest schema-free navigation fix.
8. Run full Flutter/Dart + Android CI on one exact final SHA before closing #114.

## Guardrails

- no Supabase/schema migration;
- no ownership change;
- no new first-run Nutrition question;
- do not invent `Other` detail fields;
- preserve #106 top-level order;
- PR #50 stays Draft/open/unmerged.
