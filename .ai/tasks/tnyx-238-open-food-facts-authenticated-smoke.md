# TNYX-238 — Open Food Facts authenticated smoke validation

**Status:** Complete — PARTIAL candidate outcome
**Primary owner:** TNYX-238 / bounded capability validation
**Affected surface:** existing debug-only Flutter smoke harness + already-deployed synthetic Open Food Facts probe

## Scope

Owner approved this bounded validation slice via repeated `go` / `go next` instructions.

Validated:
- existing signed-in Supabase client + debug-only smoke route;
- `tnyx-238-open-food-facts-probe`;
- bounded synthetic query/category + sanitized matched product name + complete per-100g kcal/protein/carbs/fat;
- semantic/nutrition defensibility;
- runtime behavior for the four fixed queries.

Explicitly unchanged:
- no production meal-parser routing;
- no Add Food / TNYX-226 activation;
- no persistence, schema/RLS/RPC, secrets, provider-key, or `services/api` change;
- no deployment/merge authorization.

## Exact Tested Source State

Branch:
- `tnyx/tnyx-238-open-food-facts-smoke-action`

Exact source/test head validated locally:
- `9979985638bb3bae986f0c4ee82356774787d899`

Immediate stacked base:
- PR #289 / `83392b32e7e9baf7cf88b10a7d7e390d90aabbc1`

The final task-handoff edit after validation is docs-only. Do not confuse that later docs SHA with the exact source head above that was actually analyzed, tested, and run.

## Executable Validation

On exact tested source head `9979985638bb3bae986f0c4ee82356774787d899`:

- working tree clean and expected SHA matched;
- `flutter test test/app/meal_parser_smoke_page_test.dart`: PASS (2 tests);
- `flutter test test/app/meal_parser_smoke_route_test.dart`: PASS (3 tests);
- `flutter analyze`: completed with one info-level lint at `meal_parser_smoke_page.dart:154` (`unnecessary braces in string interpolation`), so no error/warning blocker but not zero-diagnostic clean;
- normal restored signed-in session reached the debug smoke page;
- Open Food Facts capability action invoked once;
- no JWT/access token/key/runtime file contents exposed.

## Live Provenance Results

- `plain yogurt` → `resolved` | `Yogurt Greek Style` | 96.1759082217972 kcal, P 4.6g, C 3.2g, F 10g /100g
- `dal` → `unavailable`
- `roti` → `unavailable`
- `dahi` → `resolved` | `Dahi Yogurt` | 65 kcal, P 4g, C 4.6g, F 3.1g /100g

## Quality Assessment

### dahi

`Dahi Yogurt` is a plausible/defensible match for this bounded probe.

Macro-derived energy:
- protein: 4g × 4 = 16 kcal
- carbs: 4.6g × 4 = 18.4 kcal
- fat: 3.1g × 9 = 27.9 kcal
- total ≈ 62.3 kcal vs reported 65 kcal

The ~4% difference is reasonably consistent with label/rounding variation.

### plain yogurt

`Yogurt Greek Style` is technically complete but not defensible enough for generic production mapping.

Macro-derived energy:
- protein: 4.6g × 4 = 18.4 kcal
- carbs: 3.2g × 4 = 12.8 kcal
- fat: 10g × 9 = 90 kcal
- total ≈ 121.2 kcal vs reported 96.1759 kcal

That is about a 26% difference. The current probe cannot determine whether this is source-data inconsistency or another product-data nuance, and it has no nutrition consistency guardrail.

The product identity is also a specific `Greek Style` yogurt rather than a strong generic `plain yogurt` match.

### dal / roti

Both returned `unavailable` in the final run.

The bounded UI intentionally collapses no-match, timeout, and provider/runtime errors into `unavailable`, so the exact cause is not claimed.

## Provider / Endpoint Constraints

Previously recorded TNYX-238 provider audit remains applicable:
- public read access does not require a provider secret;
- legacy full-text search rate limit: 10 requests/min/IP;
- product read rate limit: 15 requests/min/IP;
- Open Food Facts community data has no completeness/accuracy guarantee;
- database reuse carries ODbL / attribution/storage implications;
- current probe uses legacy `/cgi/search.pl`, which provides full-text search but is not the preferred new-integration direction.

## Final Verdict

**Open Food Facts candidate: PARTIAL**

The source is useful for some packaged/branded products, but this validation does not support using the current plain-text legacy search as a generic factual resolver for common Indian home-food terms.

The current probe:
- resolves only 2/4 final queries;
- can return a semantically loose first complete match;
- does not perform semantic ranking/confidence;
- does not reject internally inconsistent nutrition;
- uses a legacy full-text search endpoint.

## Adapter Recommendation

Do **not** start a generic production Open Food Facts adapter slice from this evidence.

A future separate slice is justified only if deliberately narrowed, such as barcode/product-identity or packaged-food use, and should include:
- non-legacy lookup/search strategy where possible;
- semantic/product-identity confidence guardrails;
- nutrition consistency checks;
- deterministic rounding/presentation;
- explicit ODbL attribution/storage treatment;
- rate-limit handling and fallback behavior.

## Handoff

TNYX-238 is complete with a `PARTIAL` candidate result.

This result does **not** clear TNYX-229 or TNYX-226 and does not authorize production routing changes.
