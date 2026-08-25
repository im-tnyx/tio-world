# Production Hardening — Shared / Domain Contracts

**Status:** Complete / Frozen  
**Primary owner:** feature domain models + shared transport boundary  
**Tracking:** production hardening #5 item 21

## Global Guardrail

This was a contract-correctness slice, not a generic model cleanup. No schema, persistence ownership, UI, routing, auth-provider, or product-flow change was authorized.

## 1. Discovery

Equal immutable domain values must satisfy Dart's equality/hash contract so they remain safe in `Set`, `Map`, cache and deduplication usage. Shared transport parsing only expands when an actual repository/backend error shape demonstrates a gap.

## 2. Fresh Current-Head Audit

Audit head:

```text
81a19a5ebe49f730894f4c06983110900e810448
```

Reproducible findings:

1. `ProfileSetupData` compared `goals` and `healthConditions` as mathematical Sets (`length` + `containsAll`) but hashed them with iteration-order-sensitive `Object.hashAll(...)`.
2. `NutritionTargetRecommendationInsufficientInput` compared `missingFields` order-insensitively but also used order-sensitive `Object.hashAll(missingFields)`.
3. Repository search found these as the current production `Object.hashAll(...)` + order-insensitive Set equality defects in scope. Historical `WorkoutPreferencesData` search hits are absent on the current branch and were not revived.
4. `DioApiClient._extractErrorMessage()` accepts top-level string `message` or string `error`. Current tests/backend fixtures evidence that contract; no nested/object error response contract was found, so parser expansion remained out of scope.

## 3. Decisions

- use `Object.hashAllUnordered(...)` for Sets whose equality ignores insertion order;
- keep order-sensitive collection hashing unchanged where order can be semantic;
- do not add a generic equality framework/helper for two bounded defects;
- do not expand shared network error parsing without current contract evidence.

## 4. Accepted Implementation

Production:
- `apps/features/profile/lib/src/domain/models/profile_setup_data.dart`
- `apps/features/nutrition/lib/src/domain/models/nutrition_target_recommendation_result.dart`

Focused regressions:
- `apps/features/profile/test/domain/profile_setup_data_equality_test.dart`
- `apps/features/nutrition/test/domain/nutrition_target_recommendation_result_equality_test.dart`

The regressions construct equal Sets in opposite insertion order and prove:

```text
first == second
first.hashCode == second.hashCode
{first, second}.length == 1
```

## 5. Quality Review

Accepted source/test checkpoint:

```text
08b9d8f9c7212132426dcae20483a040f478112e
Flutter CI #1984 / run 32846700986 ✅
Android Native CI #396 / run 32846701001 ✅
```

Validation:
- Flutter analyze ✅
- Dart analyze ✅
- Flutter tests ✅
- Dart tests ✅
- Android debug APK/native compile ✅

Two intermediate candidates were rejected before acceptance for test-only lint findings (`prefer_collection_literals`, then `prefer_const_constructors`). Neither is an accepted checkpoint.

## 6. Final Handoff

Item 21 is COMPLETE / FROZEN. Runtime acceptance remains `08b9d8f9c7212132426dcae20483a040f478112e`; this docs-only closeout does not replace it.

Next fresh-audited bounded lane: **P2 item 22 — Wear OS hardening**. Audit current Flutter Wear architecture, synchronized App Mode state, circular-display behavior, and theme ownership before any implementation.
