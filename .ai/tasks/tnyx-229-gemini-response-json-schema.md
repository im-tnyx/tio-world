# TNYX-229 — Gemini responseJsonSchema compatibility fix

**Status:** In progress
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
**Review owner:** Unassigned until implementation completes
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub `main@09f3609afbd4a54a8379e29accd7b28fe00291cd`; live parser ACTIVE v35, `verify_jwt=true`, bundle SHA `ad0c2fc3a6744b2db2622c0db113b960213ba1ef98231eea0f6976e0647665ba`.
**Branch:** `tnyx/tnyx-229-gemini-response-json-schema`
**HEAD SHA:** `09f3609afbd4a54a8379e29accd7b28fe00291cd` at branch creation
**Observed working-tree state:** Not applicable through GitHub connector.
**Observed uncommitted/dirty files:** Not observable through connector-only execution.
**PR / tracker:** TNYX-229 In Progress; TNYX-226 Backlog / blocked; no PR yet.
**Current implementation state:** Task brief created before source mutation.
**Relevant execution surface:** `supabase/functions/nutrition-meal-text-parse`
**Validation completed at SHA:** Existing main validation inherited; this slice not yet validated.
**Validation remaining:** Focused request-envelope regression + parser type-check/tests + exact diff review + exact-head CI.
**Current blocker:** Live authenticated smoke reaches Gemini but returns `400 INVALID_ARGUMENT` with `providerErrorField=schema` while the JSON Schema object is sent through deprecated/openapi-style `responseSchema`.
**Open review finding IDs:** None.
**Next exact action:** Replace only `responseSchema` with `responseJsonSchema` in Gemini request construction and update its regression test.

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

- [ ] Replace only `responseSchema` with `responseJsonSchema`.
- [ ] Update request-envelope test to assert JSON-Schema field present and legacy fields absent.
- [ ] Confirm `interpretation_schema.ts` is unchanged.
- [ ] Audit exact main-to-branch delta.
- [ ] Open Draft PR and run Supabase Functions CI.
- [ ] Final review and Ready for Review; stop before merge/deploy.

## 6. Quality Review

### Validation Run

`Not run yet.`

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Pending.

### Known Limitations

Passing CI proves request construction, not live Gemini acceptance. Separate owner-authorized merge, deploy and one authenticated smoke remain required.

### Final Status

`REVIEW`
