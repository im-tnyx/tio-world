# TNYX-229 Gemini HTTP 400 request-contract fix

**Status:** Review ready  
**Primary owner:** ChatGPT  
**Affected platforms:** Supabase Edge Function only

## Owner Approval and Scope Boundary

**Approval status:** Approved  
**Approval evidence:** Owner said `go` after the bounded Gemini 400 correction was proposed, and later `go next` for final handoff/review readiness.  
**Approved boundary:** Gemini interpreter structured-output request-contract correction, focused regression test, and task/review handoff only.  
**Explicit non-changes:** No Flutter/UI, OpenAI routing, FatSecret/Edamam routing, schema/RLS/RPC/migration, secret mutation, new deployment, merge, or TNYX-226 implementation.

## Active Handoff

**Planning owner:** ChatGPT  
**Implementation owner:** ChatGPT  
**Review owner:** ChatGPT  
**Implementation ownership state:** Complete for this bounded slice  
**Branch:** `tnyx/tnyx-229-gemini-400-request-contract`  
**Base:** `main@4d552e685e2928dd77a1c5e5a2ba31e8281e43e4`  
**Source/test validation head:** `bc472820d0e4338b094117e3671365746666f774`  
**PR:** #292  
**Tracker:** TNYX-229 remains In Progress until source-of-truth reconciliation and separate product-activation gates are resolved.  
**Current blocker:** None for this PR's bounded source fix.  
**Open review finding IDs:** None.  
**Next exact action:** Mark PR #292 Ready for Review after this docs-only handoff sync and current-head review. Do not merge without separate explicit owner instruction.

## 1. Discovery

### User Outcome
Remove the concrete Gemini HTTP 400 request-contract mismatch without widening TNYX-229.

### Verified Evidence
- Historical live diagnostics showed Gemini HTTP 400 with the previous structured-output request envelope.
- The bounded correction changes only the request envelope while preserving endpoint, model, prompt, schema, parsing and sanitized failure behavior.
- Live `nutrition-meal-text-parse` now runs as ACTIVE v25 with `verify_jwt=true`.
- Live bundle SHA-256 remains `ac1dbdd45de10311e370cc8b7c2f16fee091445262e4a4400b3d16a01a8e9553`.
- After the Edamam credential issue was separately corrected, authenticated production smoke no longer reproduced the Gemini HTTP 400.

## 2. Codebase Exploration

### In-scope files
- `supabase/functions/nutrition-meal-text-parse/gemini_client.ts`
- `supabase/functions/nutrition-meal-text-parse/gemini_client_test.ts`
- `.ai/tasks/tnyx-229-gemini-400-request-contract.md`

### Ownership
The change remains entirely inside the current Supabase protected parser boundary plus its focused task handoff.

## 3. Clarification

Use the current `generateContent` request shape rather than migrating the whole adapter to a different Gemini transport/API. This is the smallest correction for the observed request-contract defect.

## 4. Architecture Design

### Chosen Approach
Preserve the existing flow:

`GeminiMealInterpreter -> Gemini generateContent -> parseInterpretationJson`

Only the structured-output portion of `generationConfig` changes from the legacy flat fields to `responseFormat.text`.

### Rejected Alternative
Broader Gemini transport/provider redesign was rejected because it would widen the live defect slice without evidence that it is required.

## 5. Implementation

- [x] Replace legacy `responseMimeType` / `responseSchema` request fields with `generationConfig.responseFormat.text.mimeType/schema`.
- [x] Add focused regression coverage asserting the outgoing request envelope.
- [x] Preserve endpoint/model/prompt/parser/failure behavior.
- [x] Keep all unrelated providers, Flutter, schema and product UI untouched.

## 6. Quality Review

### Stack and scope audit
- base: `main@4d552e685e2928dd77a1c5e5a2ba31e8281e43e4`
- source/test validation head: `bc472820d0e4338b094117e3671365746666f774`
- merge-base equals current `main`
- ahead / behind before this docs-only sync: `3 / 0`
- changed files before this docs-only sync: exactly 3, all owned by this slice
- unresolved GitHub review threads: 0

### Validation
- Supabase Functions CI run #22 on source/test head `bc472820d0e4338b094117e3671365746666f774`: **PASS**
- Live authenticated matrix on current deployed parser:
  - `200 g plain yogurt` -> success, 1 provider-neutral draft item, `captureSource=text`
  - `qwerty asdf` -> expected `unrecognized`
  - `dal` -> expected `incomplete`
  - `unavailable` -> prior live evidence plus deterministic focused tests
- Prior Gemini HTTP 400 was not observed in the successful current live matrix.
- Connector-only review cannot run local `git diff --check`; do not claim that command was run. The final handoff change is docs-only and source/test validation remains anchored to the CI-passed source head above.

### Review finding
No blocking source, scope, auth, secret-exposure, or response-contract regression was identified in the PR diff.

## 7. Final Handoff

### Actual Behavior
The Gemini interpreter sends the corrected structured-output request envelope while retaining the existing provider-neutral parser contract and sanitized failure behavior.

### Known Limitations / Separate Gates
- This PR does not prove which interpreter handled a successful live request because success-provider diagnostics are intentionally absent.
- Edamam credentials, country-aware provider entitlement/commercial coverage, durable nutrition-storage permission, and provider privacy/retention are separate TNYX-229/TNYX-226 activation concerns.
- PR #290 diagnostic refinement remains separate and is not part of this source fix.
- TNYX-226 remains blocked until TNYX-229 is explicitly reconciled and the separate product-activation gates are decided.

### Final Status
`READY_FOR_REVIEW`

Do not merge without explicit owner instruction.
