# TNYX-229 — Gemini responseJsonSchema compatibility fix

**Status:** Review ready
**Primary owner:** ChatGPT
**Affected platforms:** Supabase Edge Function only

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Owner said `next` after the exact bounded follow-up was stated: switch Gemini GenerateContent from `responseSchema` to `responseJsonSchema`, then branch/tests/Draft PR/CI/review-ready only.
**Approved product/UI/data-shape boundaries:** Existing TNYX-229 Gemini request-compatibility defect only.
**Explicit non-changes:** No Flutter/UI, no model/endpoint/prompt change, no interpretation schema content change, no OpenAI schema change, no provider-order/fallback change, no diagnostic weakening, no secret/config change, no schema/RLS/RPC/migration, no deploy, no merge, no TNYX-226 work.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** ChatGPT
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub `main@09f3609afbd4a54a8379e29accd7b28fe00291cd`; live parser ACTIVE v35, `verify_jwt=true`, bundle SHA `ad0c2fc3a6744b2db2622c0db113b960213ba1ef98231eea0f6976e0647665ba`.
**Branch:** `tnyx/tnyx-229-gemini-response-json-schema`
**HEAD SHA:** `09f3609afbd4a54a8379e29accd7b28fe00291cd` at branch creation
**Observed working-tree state:** Not applicable through GitHub connector.
**Observed uncommitted/dirty files:** Not observable through connector-only execution.
**PR / tracker:** Draft PR #299; TNYX-229 In Progress; TNYX-226 Backlog / blocked.
**Current implementation state:** `responseJsonSchema` compatibility change implemented; source validation passed.
**Relevant execution surface:** `supabase/functions/nutrition-meal-text-parse`
**Validation completed at SHA:** `f0902d551fcd290f055bfcca16481a08e256ed90` — Supabase Functions CI #42 PASS.
**Validation remaining:** None for review readiness; merge/deploy/live observation remain separate owner-authorized gates.
**Current blocker:** Live acceptance remains unverified until separate merge/deploy/authenticated smoke.
**Open review finding IDs:** None.
**Next exact action:** Final exact-head review and Ready for Review. Do not merge/deploy without separate owner authorization.

## 1. Discovery

### User Outcome

Send the existing Gemini JSON Schema through the GenerateContent JSON-Schema field so nullable union types remain valid without duplicating or rewriting provider schema semantics.

### Success Criteria

- Request keeps `generationConfig.responseMimeType = "application/json"`.
- Request sends `generationConfig.responseJsonSchema = geminiInterpretationSchema`.
- `generationConfig.responseSchema` and `generationConfig.responseFormat` are absent.
- `interpretation_schema.ts` remains unchanged.
- OpenAI schema remains unchanged.
- Model, endpoint, prompt, timeout, auth header, diagnostics, provider ordering, fallback and client-visible parser result remain unchanged.

### Scope

- `gemini_client.ts`: one request-field compatibility change.
- `gemini_client_test.ts`: exact request-envelope regression update.
- this task handoff and PR metadata.

### Non-Goals

- No nullable-to-`nullable:true` schema rewrite.
- No Gemini schema fork/duplication.
- No API key/model/secret mutation.
- No deployment or merge.
- No TNYX-226 work.

## 2. Codebase Exploration

### Verified Evidence

- Current main sends `responseMimeType` + `responseSchema`.
- Live v33/v35 bundle smoke succeeded overall through fallback but Gemini returned `400 INVALID_ARGUMENT`, `providerErrorReason=UNKNOWN`, `providerErrorField=schema`.
- `interpretation_schema.ts` has not changed since commit `13da1de59ad4980dc36ce6a9fbc3c206d1463224`.
- Current Gemini schema uses JSON-Schema nullable unions:
  - `mealName.type = ["string", "null"]`
  - `quantity.type = ["number", "null"]`
  - `unit.type = ["string", "null"]`
- Current Google structured-output documentation supports JSON Schema nullable union types and examples expose `ResponseJsonSchema` for GenerateContent.
- `responseSchema` and `responseJsonSchema` must not be mixed.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Rewrite Gemini schema to OpenAPI nullable form? | Rejected for this slice | Duplicates semantics and is unnecessary if JSON Schema is passed through the intended JSON-Schema field. | ChatGPT |
| Change only request field to `responseJsonSchema` | Chosen | Smallest reversible fix preserving existing shared schema. | ChatGPT |
| Change OpenAI schema | Rejected | No evidence of an OpenAI schema defect. | ChatGPT |

## 4. Architecture Design

### Chosen Approach

Keep the existing JSON Schema object single-sourced and change only:

```text
generationConfig.responseSchema
→
generationConfig.responseJsonSchema
```

Keep `responseMimeType = "application/json"`.

### Ownership and Data Flow

`meal text -> Gemini interpreter -> same GenerateContent endpoint -> responseMimeType + responseJsonSchema -> unchanged normalization -> unchanged fallback`

### Alternative Rejected

Creating a Gemini-only OpenAPI schema variant with `nullable:true` is deferred because it adds duplication and changes schema representation before trying the JSON-Schema field designed for the current schema shape.

## 5. Implementation Plan

- [x] Replace only `responseSchema` with `responseJsonSchema`.
- [x] Update request-envelope test to assert JSON-Schema field present and legacy fields absent.
- [x] Confirm `interpretation_schema.ts` is unchanged.
- [x] Audit exact main-to-branch delta.
- [x] Open Draft PR and run Supabase Functions CI.
- [x] Final exact-head CI/review preparation complete; stop before merge/deploy.

## 6. Quality Review

### Validation Run

- Supabase Functions CI #42 on source head `f0902d551fcd290f055bfcca16481a08e256ed90`: PASS.
- Supabase Functions CI #43 on docs-synced head `a087d75de7a87afa54440453b004e838d3871d44`: PASS.
- Parser entrypoint type-check: PASS.
- Parser source/tests type-check: PASS.
- Parser tests: PASS.
- Complete `main...branch` delta reviewed: exactly 3 owned files.
- Runtime diff is exactly one field: `responseSchema` → `responseJsonSchema`.
- Request-envelope regression asserts `responseJsonSchema` present and `responseSchema` / `responseFormat` absent.
- `interpretation_schema.ts`, OpenAI client/schema, diagnostics, model, endpoint, prompt, provider order and fallback are unchanged.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-229-gemini-response-json-schema.md`
- `supabase/functions/nutrition-meal-text-parse/gemini_client.ts`
- `supabase/functions/nutrition-meal-text-parse/gemini_client_test.ts`

### Actual Behavior

Gemini GenerateContent keeps `responseMimeType = "application/json"` and now sends the existing JSON Schema through `responseJsonSchema`. The deprecated/openapi-style `responseSchema` field is absent. No schema content or provider behavior outside this request field changed.

### Known Limitations

Passing CI proves request construction, not live Gemini acceptance. Separate owner-authorized merge, deploy and one authenticated smoke remain required.

### Final Status

`REVIEW`
