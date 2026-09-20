# TNYX-240 — N5D-9 Natural-language meal parsing robustness (slice S1)

**Status:** In progress (S1 implemented and validated; PR #302 is open and in technical review; not deployed)
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
- `edamam_client.ts`, `fatsecret_client.ts`: each `incomplete` path names its reason. Edamam's combined condition is split into ordered checks with identical outcomes. The reasons mean the same thing for both providers (see "Reason semantics" below); the review fix R1 made the labels exact without changing any outcome.
- `resolver.ts`: the last resolver that stopped the item explains it (FatSecret's `region_unsupported` is not the real cause when Edamam then ran).
- `handler.ts`: one event per incomplete meal, with the reason of the first item that stopped it; `country_missing` and `no_items` are reported too.

## Validation

- `deno check supabase/functions/nutrition-meal-text-parse/index.ts`: PASS. `deno check supabase/functions/nutrition-meal-text-parse/*.ts`: PASS, 0 errors.
- `deno test --allow-read=supabase/functions/nutrition-meal-text-parse supabase/functions/nutrition-meal-text-parse`: 108 passed / 0 failed at the original implementation commit (Deno 2.9.7; baseline on `main` was 93); 115 passed / 0 failed after the review fix (see Review).
- Five existing assertions in `providers_test.ts` that matched `{ kind: "incomplete" }` exactly now include the reason; the behaviour they cover is unchanged.
- New `incomplete_reason_test.ts` (15 tests) covers the normalizer (limit, unit without quantity, instruction text), resolver reason merge, every Edamam reason, no request when there is no amount, one event per meal with no meal text, `unknown`, `country_missing` before any provider call, `no_items`, and no event on success.
- Mutation check: removing the bare-count rule and the `country_missing` event makes 4 of the new tests fail; restored, all pass.
- Not validated: real Edamam behaviour for `2 piece banana` (needs a deployed run).

## Handoff

**Implementation owner:** current session (branch `tnyx/tnyx-240-n5d-9-natural-language-meal-parsing-robustness`).
**State:** PR #302 exists against `main` (parent `170a18ca509876e7172a451fae1d3b6d8529e218`, normal merge, no rewrite). Supabase Functions CI passed on `e3c8ed81ce84bad34f3e77066c6e61db7f6924e0`, the head before the review fix R1. The exact final head, its CI and the Codex result are recorded on the PR, not here. No deploy has happened; S2–S6 are untouched.
**Next exact action:** finish exact-head CI and the Codex review of #302, resolve any finding with evidence, then wait for an explicit owner instruction to merge. Deploying the Edge Function and the live table re-run are owner actions after merge and will use the new `meal_incomplete` events to decide S2–S6.
**Open decisions for the owner:** S3 (household units), S4 (partial results UI), S5 (missing-country outcome and message).

## Current reconciliation — 2026-09-20

- **Current `main` anchor:** `170a18ca509876e7172a451fae1d3b6d8529e218` (PR #301 squash merge). Preserved S1 implementation commit: `77daf0944d1d0ccaf0f5e6dec94f43a0874a2adc`. It was integrated by the normal merge commit `c45beade` without a rebase or rewrite.
- **Effective S1-owned files:** this brief; `diagnostics.ts`; `edamam_client.ts`; `fatsecret_client.ts`; `handler.ts`; `incomplete_reason_test.ts`; `interpretation_schema.ts`; `providers_test.ts`; `resolver.ts`; and `types.ts` under `supabase/functions/nutrition-meal-text-parse` unless named otherwise.
- **Exact closed diagnostic contract:** `missing_amount`, `no_match`, `name_mismatch`, `amount_mismatch`, `unit_mismatch`, `nutrients_missing`, `region_unsupported`, `country_missing`, `no_items`, `unknown`. Each emitted event is `{ component, stage: "meal_incomplete", reason }`; no meal text, provider body, or user data is included. `unknown` is the safe compatibility fallback for an incomplete resolver result with no reason; `no_items` is the handler's defensive recognized-empty-items path.
- **Bare-count rule:** a finite positive quantity with no unit at or below `MAX_BARE_COUNT = 50` reaches factual resolvers as `piece`; a larger bare number remains incomplete. A unit without a quantity remains incomplete. No gram weight or household-unit conversion is invented.
- **Scope remains S1 only:** no Flutter/UI, schema/RLS/RPC, provider/model/secret, deployment, or `services/api` change. S2 Hinglish normalization, S3 household conversions, S4 partial-results UI, S5 missing-country UX, and S6 accuracy remediation remain untouched.
- **Validation on the merged tree before the review fix (`e3c8ed81…`):** `deno check supabase/functions/nutrition-meal-text-parse/index.ts` PASS; `deno test --allow-read=supabase/functions/nutrition-meal-text-parse supabase/functions/nutrition-meal-text-parse` PASS — 108 passed / 0 failed; `git diff --check origin/main...HEAD` PASS. The first non-elevated Deno test invocation hit a Windows named-pipe panic after type checking; the elevated retry completed successfully.

## Reason semantics

Each reason means the same for FatSecret and Edamam. The handler reports the reason of the first incomplete item; the resolver merge keeps the last resolver that stopped the item (see `resolver.ts`).

| Reason | Condition |
|---|---|
| `missing_amount` | the item has no quantity or no unit (no provider request is made) |
| `no_match` | the provider returned nothing for the item, or a parse result without a food identity |
| `name_mismatch` | the provider returned food(s) but none is a safe identity match for the requested name (FatSecret also when two tie) |
| `amount_mismatch` | Edamam only: the parsed amount is absent or differs from the requested one |
| `unit_mismatch` | no measure or serving fits the requested unit (Edamam: measure absent or incompatible; FatSecret: no compatible serving, or no serving at all) |
| `nutrients_missing` | the food or the chosen serving carries no usable nutrient values |
| `region_unsupported` | FatSecret only: the account's country has no FatSecret region |
| `country_missing` | handler: the account has no saved country; reported before any provider call |
| `no_items` | handler: a recognized meal came back with no items (defensive) |
| `unknown` | compatibility fallback for an incomplete result that names no reason; no real resolver returns one |

## Review — 2026-09-20

Independent technical review of the complete effective diff against `main` `170a18ca…` (behaviour, privacy, failure semantics), then a fix for the one valid finding.

- **Bare count:** `2 banana` becomes quantity 2, unit `piece` in the shared `parseInterpretationJson`, used by both Gemini and OpenAI. `0`, negative and non-finite quantities (including `1e999`) never get that far: the whole interpretation is `unavailable`, as before. `50` is completed, `51` stays without a unit and is `missing_amount` at the resolver. A stated unit is never replaced and a unit without a quantity stays incomplete. No gram or household conversion is inferred.
- **Privacy:** an event is `{component, stage: "meal_incomplete", reason}` and nothing else; the only writer is `mealParserIncompleteDiagnostic`, whose argument is the closed reason set. No meal text, food name, provider body, user id or nutrient value reaches it.
- **Exactly once:** only `handler.ts` writes `meal_incomplete`, at three mutually exclusive points (country missing, any incomplete item, defensive empty). Resolvers and the fallback merge never write one. A meal with several incomplete items, or one incomplete next to resolved or unavailable items, writes one event.
- **Outcomes:** `recognized`, `unrecognized`, `unavailable` and the precedence of `incomplete` over `unavailable` are unchanged; `unrecognized` and `unavailable` write no incomplete event.

| ID | Severity | Status | Finding |
|---|---|---|---|
| R1 | P2 | Resolved in the review-fix commit | Four reasons were attached to the wrong condition, which defeats the purpose of the diagnostic. Edamam reported `no_match` when a food was parsed but its amount or measure was missing (should be `amount_mismatch` / `unit_mismatch`). FatSecret reported `no_match` when foods came back but none was a safe identity match (Edamam calls the same condition `name_mismatch`), and `unit_mismatch` when the serving fit but had no nutrient values (`nutrients_missing`). Reproduced with a probe against `e3c8ed81…`; only labels change, no outcome does. |
| R2 | P3 | Deferred | `finitePositiveNumber` accepts numeric strings and booleans. It is pre-existing and shared, and the providers' structured schemas type `quantity` as a number. Out of S1. |
| R3 | P3 | Deferred | If the second resolver is incomplete without a reason, the first resolver's reason is dropped and the meal reports `unknown`. Both real resolvers always name a reason, so it is reachable only through a custom resolver. |
| R4 | P3 | Deferred | `mealParserDiagnostic` still takes a free `reason: string`; the closed set is enforced by the `mealParserIncompleteDiagnostic` wrapper, the only caller for this stage. Tightening it belongs with a diagnostics-wide cleanup, not S1. |

Review-fix validation (working tree with R1): `deno check supabase/functions/nutrition-meal-text-parse/index.ts` PASS and `deno check` of every `*.ts` in the function PASS; `deno test --allow-read=supabase/functions/nutrition-meal-text-parse supabase/functions/nutrition-meal-text-parse` 115 passed / 0 failed; `git diff --check` PASS.

- Tests added for R1 and for review gaps: Edamam cases (no food identity, no parsed amount, no measure); a FatSecret reason table (missing amount, region, no result, only a different food, no serving in the unit, serving without nutrients); the FatSecret serving helper keeps returning `null`; non-positive and non-finite quantities; a stated unit is kept; one event for a meal mixing resolved and incomplete items; incomplete next to unavailable; `unrecognized` / `unavailable` write no event. The existing FatSecret identity test now expects `name_mismatch`.
- Against the previous source (`e3c8ed81…`) three of them fail (the Edamam table, the FatSecret table, the identity test), so they prove R1. The others pass on the previous source and document behaviour that was preserved.
- Mutation check repeated on the current tree: disabling the bare-count rule and the `country_missing` event makes 4 tests fail (`a stated count without a unit becomes pieces`, `a bare count is completed at the limit and not above it`, `a counted item with no unit now reaches Edamam as pieces`, `an account without a country is reported before any provider is called`).
- GitHub AI scanner (`github-advanced-security`) on `e3c8ed81…` is red for an external reason: `SessionModelError: CAPIError: 400 The requested model is not supported` while creating its review session, before any analysis; no code-scanning analysis or alert exists. It is not a source or security finding.
- Not validated: real Edamam/FatSecret behaviour for `2 piece banana` and for unit-less or unit-unknown parses (needs a deployed run); that run is what these reasons are for.
