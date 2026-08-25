# Production Hardening — Shared / Domain Contracts

**Status:** In progress  
**Primary owner:** feature domain models + shared transport boundary  
**Tracking:** production hardening #5 item 21

## Global Guardrail

This is a contract-correctness slice, not a generic model cleanup. Change only current-head defects that are reproducible. No schema, persistence ownership, UI, routing, auth-provider, or product-flow changes.

## 1. Discovery

### User Outcome

Equal immutable domain values must satisfy Dart's equality/hash contract so they remain safe in `Set`, `Map`, cache and deduplication usage. Shared transport parsing should only expand when an actual repository/backend error shape demonstrates a gap.

### Success Criteria

- any audited `==` implementation that treats a `Set` as order-insensitive has an order-insensitive `hashCode`;
- focused regressions prove equal values with different Set insertion order have equal hashes;
- no speculative network error parser expansion without an evidenced response contract;
- full Flutter/Dart + Android exact-SHA CI is green.

## 2. Fresh Current-Head Audit

Audit head:

```text
81a19a5ebe49f730894f4c06983110900e810448
```

### Reproducible findings

1. `ProfileSetupData` compares `goals` and `healthConditions` as mathematical Sets (`length` + `containsAll`) but hashes each with `Object.hashAll(...)`, which is iteration-order-sensitive. Two equal instances can therefore produce different hashes.
2. `NutritionTargetRecommendationInsufficientInput` compares `missingFields` order-insensitively but also uses order-sensitive `Object.hashAll(missingFields)`.
3. Repository search found these as the current `Object.hashAll(...)` + order-insensitive Set equality defects in production domain code. Historical `WorkoutPreferencesData` search hits are not present on the current branch and are not in scope.
4. `DioApiClient._extractErrorMessage()` currently accepts top-level string `message` or string `error`. Existing current tests/backend fixtures use the top-level message contract. No concrete current nested/object error contract was found during this audit, so parser expansion is not authorized in this slice.

## 3. Decisions

| Decision | Status | Rationale |
|---|---|---|
| Use `Object.hashAllUnordered(...)` for Sets whose equality ignores insertion order | Made | restores Dart equality/hash invariant without changing domain meaning |
| Keep List/order-sensitive hashes unchanged | Made | order may be semantic there |
| Do not add generic equality helpers/packages | Made | two bounded defects do not justify framework expansion |
| Do not expand shared error parsing | Made | no current contract evidence |

## 4. Scope

Production:
- `apps/features/profile/lib/src/domain/models/profile_setup_data.dart`
- `apps/features/nutrition/lib/src/domain/models/nutrition_target_recommendation_result.dart`

Focused tests:
- Profile domain equality/hash regression
- Nutrition recommendation-result equality/hash regression

## 5. Non-Goals

- no DTO/schema/persistence changes;
- no change to `ProfileSetupData` field semantics;
- no change to nutrition recommendation calculation;
- no network/API behavior change;
- no broad Equatable/freezed migration;
- no UI/navigation/auth changes.

## 6. Implementation Plan

- [ ] replace order-sensitive Set hashing in `ProfileSetupData`;
- [ ] replace order-sensitive `missingFields` hashing in nutrition result;
- [ ] add reversed-insertion-order equality/hash regressions;
- [ ] run focused/full Flutter/Dart tests and analyze;
- [ ] run Android exact-SHA CI;
- [ ] freeze accepted checkpoint in #5.

## 7. Quality Review

Pending.

## 8. Final Handoff

Pending.
