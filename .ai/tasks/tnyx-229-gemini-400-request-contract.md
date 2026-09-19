# TNYX-229 Gemini HTTP 400 request-contract fix

**Status:** In progress
**Primary owner:** ChatGPT
**Affected platforms:** Supabase Edge Function only

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Approved
**Approval evidence:** Owner said `go` after the bounded Gemini 400 fix was proposed.
**Approved product/UI/data-shape boundaries:** Gemini interpreter request-contract correction and focused tests only.
**Explicit non-changes:** No Flutter/UI, Edamam, FatSecret, OpenAI behavior, schema/RLS/RPC/migration, secrets, deployment, merge, or TNYX-226.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub current `main` source inspected with TNYX-229 In Progress.
**Branch:** `tnyx/tnyx-229-gemini-400-request-contract`
**HEAD SHA:** branch created from current `main`
**Observed working-tree state:** Connector branch, no local working tree.
**Observed uncommitted/dirty files:** Not applicable
**PR / tracker:** TNYX-229
**Current implementation state:** Gemini request uses legacy `responseMimeType` + `responseSchema`; live diagnostics repeatedly show Gemini HTTP 400.
**Relevant execution surface:** `supabase/functions/nutrition-meal-text-parse/gemini_client.ts`
**Validation completed at SHA:** Not yet
**Validation remaining:** focused tests, CI, diff review
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Change only Gemini structured-output request envelope to the current Gemini 3.8 generateContent `responseFormat.text` contract and assert request shape.

## 1. Discovery

### User Outcome
Remove the concrete Gemini HTTP 400 request-contract mismatch without widening TNYX-229.

### Success Criteria
Gemini request uses the current documented Gemini 3.8 Flash generateContent structured-output shape; focused tests assert the envelope and existing parser behavior remains unchanged.

### Scope
Gemini client request body, focused Gemini tests, this handoff.

### Non-Goals
Provider redesign, Interactions API migration, model change, prompt/schema business-rule change, deployment, UI activation.

## 2. Codebase Exploration

### Verified Evidence
- Source/config inspected: `gemini_client.ts`, `interpretation_schema.ts`, `composition.ts`, TNYX-229.
- Existing pattern to follow: direct REST generateContent with server-side API key and provider-neutral parser.
- Tests or validation already present: `gemini_client_test.ts`.
- Current Google Gemini 3.8 legacy generateContent docs show structured output under `generationConfig.responseFormat.text` while migration docs confirm generateContent remains supported.

## 3. Clarification

### Decisions Required or Made
Use the current generateContent request shape rather than migrating the whole adapter to Interactions API. This is the smallest change that addresses the observed 400 contract risk.

## 4. Architecture Design

### Chosen Approach
Preserve endpoint, model, prompt, schema and response parsing. Change only the structured-output envelope.

### Ownership and Data Flow
`GeminiMealInterpreter -> Gemini generateContent -> parseInterpretationJson`

### Alternative Rejected
Interactions API migration: broader transport/response change than required for this live defect.

### Failure and Accessibility States
Existing sanitized `unavailable` behavior remains unchanged.

## 5. Implementation Plan
- [ ] Update Gemini request envelope.
- [ ] Add request-shape regression test.
- [ ] Run focused validation/CI and review diff.

## 6. Quality Review

### Validation Run
Not run yet.

## 7. Final Handoff

### Changed Files
Pending.

### Actual Behavior
Pending.

### Known Limitations
Edamam 401 and provider entitlement/storage gates are separate and remain open.

### Final Status
`REVIEW`
