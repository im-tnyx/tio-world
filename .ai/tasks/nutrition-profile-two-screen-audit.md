# #114 Nutrition Profile two-screen navigation audit

Status: ✅ COMPLETE / FROZEN

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

## Accepted result

The current production navigation already implements the intended two-screen Nutrition Profile. The reported one-screen behavior was **not reproduced** against current source wiring, so no production navigation change was made.

Accepted page-level regression coverage proves:

1. fresh Nutrition Profile entry starts at Diet Type;
2. Continue moves Diet Type → Allergies & Restrictions;
3. Continue from Allergies moves to Wellness;
4. Back from Wellness returns to Allergies, then Back returns to Diet Type;
5. selected Diet Type and multiple restrictions survive Back/edit-back;
6. exact resume preserves an Allergies child cursor;
7. Hybrid `later` enters Diet Type from Workout Intro;
8. Hybrid `setupNow` enters Diet Type from Workout Targets.

The initial regression used a stale presentation-icon assertion (`Icons.check_circle`) even though the shared choice card renders `Icons.check_circle_rounded`. The final acceptance asserts typed screen selection state instead, so answer-persistence coverage is not coupled to icon implementation details.

## Exact accepted source/test checkpoint

```text
3d917fb6dca82f700c5120daf2ecbccc36992f0d
Flutter CI #1820 / run 32748109328 ✅
Android Native CI #232 / run 32748109520 ✅

Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
Android debug APK/native compile ✅
```

## Selection contract retained

- Diet Type is single-select.
- Allergies & Restrictions is multi-select.
- `None` is mutually exclusive with real restrictions.
- `null` restrictions means unanswered; `{none}` means explicit none; empty set is incomplete.
- canonical Nutrition Profile mapping and ownership are unchanged.

## Guardrails preserved

- no Supabase/schema migration;
- no ownership change;
- no new first-run Nutrition question;
- no invented `Other` detail field;
- #106 top-level order preserved;
- PR #50 stays Draft/open/unmerged.
