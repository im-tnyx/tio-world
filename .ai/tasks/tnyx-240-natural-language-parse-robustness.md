# TNYX-240 — N5D-9 Natural-language meal parsing robustness (slice S1)

**Status:** In progress (S1 validated locally, not deployed; Draft PR pending)
**Primary owner:** `supabase/functions/nutrition-meal-text-parse`
**Affected platforms:** Supabase Edge Function only (no Flutter, no schema)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped task (follow-up to TNYX-226/TNYX-229 live testing).
**Approval status:** Approved for S1 only.
**Approval evidence:** Owner (chat, 2026-09-20) reported that typed input like `2 kele 2 gilas milk/dudh 3 mediam roti and dal 200g` must give a correct result, then asked to make this the next issue and solve it following AGENTS.md. Linear TNYX-240 records the full problem, the slices and which need a further owner decision.
**Approved boundary (S1):** deterministic, server-side changes inside the parser function that need no product decision:

1. a stated count without a unit (`2 banana`) is completed as `piece`;
2. every `incomplete` meal writes exactly one closed-set, text-free diagnostic saying why.

**Explicit non-changes:** no Flutter/UI change, no schema/RLS/RPC, no provider, model, key or secret change, no new provider, no `services/api`, no deploy (the owner deploys Edge Functions), no change to `unrecognized`/`unavailable` behaviour or to the response contract.

**Recorded, not started (need an owner decision or live validation):** S2 Hinglish→English generic names in the interpreter rules; S3 household unit table (katori, glass, plate…), which reverses the current "no invented conversions" rule; S4 partial results (Meal Editor / Add Food UI); S5 dedicated outcome and message for an account without a saved country; S6 nutrition accuracy audit (`2 roti` = 403.9 kcal).

## Verified evidence

Live emulator run on 2026-09-20 (owner account, country saved, Gemini→OpenAI→Edamam, nothing logged): plain and typo'd single items with grams resolve; `2 roti` resolves; `2 banana`, `2 kele`, `dal 200g`, `1 katori dal` and every multi-item sentence tried return `incomplete`. Full table in TNYX-240.

Code facts (`supabase/functions/nutrition-meal-text-parse`):

- `interpretation_schema.ts` set quantity and unit to null when a unit was not stated and kept them as a pair, so a bare count reached the resolvers as a missing amount. `2 roti` only worked because the model answered `pieces`.
- `edamam_client.ts` folded five different checks into one `incomplete`; `fatsecret_client.ts` had four. Nothing recorded which one stopped an item, so the failures above could not be attributed from logs.
- `handler.ts` returned `incomplete` without any event, including for an account with no `country_code`, where no provider is called at all.

## Implementation (S1)

- `interpretation_schema.ts`: `BARE_COUNT_UNIT = "piece"` and `MAX_BARE_COUNT = 50`. A quantity with a null unit and quantity ≤ 50 is completed as pieces in the shared normalizer, so Gemini and OpenAI behave the same; a larger bare number is more likely a weight and stays partial. A unit without a quantity stays partial. The interpreter instructions state the same rule.
- `diagnostics.ts`: closed `MealParserIncompleteReason` (`missing_amount`, `no_match`, `name_mismatch`, `amount_mismatch`, `unit_mismatch`, `nutrients_missing`, `region_unsupported`, `country_missing`, `no_items`, `unknown`) and `mealParserIncompleteDiagnostic`, which writes `{component, stage: "meal_incomplete", reason}` and nothing else.
- `types.ts`: `ResolverResult` `incomplete` carries an optional `reason`.
- `edamam_client.ts`, `fatsecret_client.ts`: each `incomplete` path names its reason. Edamam's combined condition is split into ordered checks with identical outcomes.
- `resolver.ts`: the last resolver that stopped the item explains it (FatSecret's `region_unsupported` is not the real cause when Edamam then ran).
- `handler.ts`: one event per incomplete meal, with the reason of the first item that stopped it; `country_missing` and `no_items` are reported too.

## Validation

- `deno check supabase/functions/nutrition-meal-text-parse/index.ts`: PASS. `deno check supabase/functions/nutrition-meal-text-parse/*.ts`: PASS, 0 errors.
- `deno test --allow-read=supabase/functions/nutrition-meal-text-parse supabase/functions/nutrition-meal-text-parse`: 108 passed / 0 failed (Deno 2.9.7; baseline on `main` was 93).
- Five existing assertions in `providers_test.ts` that matched `{ kind: "incomplete" }` exactly now include the reason; the behaviour they cover is unchanged.
- New `incomplete_reason_test.ts` (15 tests) covers the normalizer (limit, unit without quantity, instruction text), resolver reason merge, every Edamam reason, no request when there is no amount, one event per meal with no meal text, `unknown`, `country_missing` before any provider call, `no_items`, and no event on success.
- Mutation check: removing the bare-count rule and the `country_missing` event makes 4 of the new tests fail; restored, all pass.
- Not validated: real Edamam behaviour for `2 piece banana` (needs a deployed run).

## Handoff

**Implementation owner:** current session (branch `tnyx/tnyx-240-n5d-9-natural-language-meal-parsing-robustness`).
**Next exact action:** complete the approved Draft PR handoff. A later owner-approved deployment and live table re-run will use the new `meal_incomplete` events to decide S2–S6.
**Open decisions for the owner:** S3 (household units), S4 (partial results UI), S5 (missing-country outcome and message).

## Current reconciliation — 2026-09-20

- **Current `main` anchor:** `170a18ca509876e7172a451fae1d3b6d8529e218` (PR #301 squash merge). Preserved S1 implementation commit: `77daf0944d1d0ccaf0f5e6dec94f43a0874a2adc`. It was integrated by the normal merge commit `c45beade` without a rebase or rewrite.
- **Effective S1-owned files:** this brief; `diagnostics.ts`; `edamam_client.ts`; `fatsecret_client.ts`; `handler.ts`; `incomplete_reason_test.ts`; `interpretation_schema.ts`; `providers_test.ts`; `resolver.ts`; and `types.ts` under `supabase/functions/nutrition-meal-text-parse` unless named otherwise.
- **Exact closed diagnostic contract:** `missing_amount`, `no_match`, `name_mismatch`, `amount_mismatch`, `unit_mismatch`, `nutrients_missing`, `region_unsupported`, `country_missing`, `no_items`, `unknown`. Each emitted event is `{ component, stage: "meal_incomplete", reason }`; no meal text, provider body, or user data is included. `unknown` is the safe compatibility fallback for an incomplete resolver result with no reason; `no_items` is the handler's defensive recognized-empty-items path.
- **Bare-count rule:** a finite positive quantity with no unit at or below `MAX_BARE_COUNT = 50` reaches factual resolvers as `piece`; a larger bare number remains incomplete. A unit without a quantity remains incomplete. No gram weight or household-unit conversion is invented.
- **Scope remains S1 only:** no Flutter/UI, schema/RLS/RPC, provider/model/secret, deployment, or `services/api` change. S2 Hinglish normalization, S3 household conversions, S4 partial-results UI, S5 missing-country UX, and S6 accuracy remediation remain untouched.
- **Fresh validation on the merged tree:** `deno check supabase/functions/nutrition-meal-text-parse/index.ts` PASS; `deno test --allow-read=supabase/functions/nutrition-meal-text-parse supabase/functions/nutrition-meal-text-parse` PASS — 108 passed / 0 failed; `git diff --check origin/main...HEAD` PASS. The first non-elevated Deno test invocation hit a Windows named-pipe panic after type checking; the elevated retry completed successfully.
