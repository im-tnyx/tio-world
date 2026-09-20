# TNYX-229 — Gemini HTTP error-status diagnostic refinement

**Status:** In progress
**Primary owner:** ChatGPT
**Affected platforms:** Supabase Edge Function only

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Owner explicitly said `go` after two identical v26/v27 authenticated success smokes reproducibly emitted Gemini HTTP 400.
**Approved product/UI/data-shape boundaries:** Existing TNYX-229 runtime-validation defect correction only.
**Explicit non-changes:** No Flutter/UI, no request-envelope change, no provider/model/routing change, no secret/config change, no schema/RLS/RPC/migration, no deployment, no merge, no TNYX-226 work.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned until implementation completes
**Implementation ownership state:** Active
**Repository state last verified:** GitHub `main@5e4091a45e9b9327f48be3c7658c764c0bb72d00`; connector execution has no local working-tree surface to inspect.
**Branch:** `tnyx/tnyx-229-gemini-http-error-status-diagnostic`
**HEAD SHA:** `5e4091a45e9b9327f48be3c7658c764c0bb72d00` at branch creation
**Observed working-tree state:** Not applicable through GitHub connector; branch created from exact current main.
**Observed uncommitted/dirty files:** Not observable / not applicable to connector-only execution.
**PR / tracker:** TNYX-229 In Progress; no PR yet.
**Current implementation state:** Task brief created before source mutation.
**Relevant execution surface:** `supabase/functions/nutrition-meal-text-parse`
**Validation completed at SHA:** Existing current-main CI inherited; new slice not validated yet.
**Validation remaining:** Focused type-check/tests + complete diff review + current-head CI.
**Current blocker:** Reproducible Gemini HTTP 400 lacks safe provider status detail.
**Open review finding IDs:** None.
**Next exact action:** Add allowlisted Gemini `error.status` diagnostic extraction and focused redaction tests without changing runtime outcome/request contract.

## 1. Discovery

### User Outcome

Identify the reproducible Gemini HTTP 400 category safely enough to diagnose root cause without logging provider messages, bodies, URLs, API keys, meal text, identity, or session material.

### Success Criteria

- HTTP non-2xx behavior remains `unavailable`, preserving OpenAI fallback.
- For Gemini error JSON, only an exact allowlisted `error.status` value is emitted.
- Unknown/malformed status never becomes arbitrary log text.
- Raw `error.message`, provider body, request URL, credentials and meal text never appear in diagnostics.
- Existing Gemini structured-output request body remains byte-semantically unchanged by this slice.

### Scope

- `diagnostics.ts`: bounded provider status field/type.
- `gemini_client.ts`: inspect cloned HTTP error JSON in memory and emit allowlisted status.
- focused tests for allowed, unknown, malformed and redaction behavior.
- task/PR handoff.

### Non-Goals

- Do not fix/revert the Gemini request contract in this slice.
- Do not change `gemini-3.8-flash`, provider order, timeouts or fallback behavior.
- Do not deploy or merge.
- Do not alter client-visible response contract.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: current-main `gemini_client.ts`, `diagnostics.ts`, `gemini_client_test.ts`.
- Existing pattern to follow: Edamam clones provider response, derives bounded metadata in memory, and never logs raw provider content.
- Tests or validation already present: request-envelope regression test preserves `generationConfig.responseFormat.text`.
- Live evidence: two consecutive authenticated success smokes on bundle `900c96de…` emitted `interpreter_unavailable / gemini / http_error / 400` while fallback still produced a draft.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Log raw Gemini message/body? | Rejected | Sensitive/unbounded provider text may include request detail; not needed. | ChatGPT |
| Revert request envelope now? | Rejected | Official contract currently supports the used shape; diagnose first. | ChatGPT |
| Add allowlisted `error.status` only | Chosen | Gives actionable provider category with bounded leakage surface. | ChatGPT |

## 4. Architecture Design

### Chosen Approach

On Gemini non-2xx:
1. clone response;
2. parse only JSON `error.status`;
3. map exact known Google RPC status names to an internal allowlist, otherwise `UNKNOWN`;
4. emit static diagnostic metadata plus numeric HTTP status;
5. return unchanged `unavailable`.

### Ownership and Data Flow

`Gemini HTTP response -> in-memory bounded status classifier -> mealParserDiagnostic -> existing unavailable -> existing fallback`

### Alternative Rejected

Logging `error.message` or raw provider body was rejected because it increases sensitive-data leakage risk and is unnecessary for the first root-cause discriminator.

### Failure and Accessibility States

No product-visible/UI change. Malformed/non-JSON provider errors safely map to `UNKNOWN`.

## 5. Implementation Plan

- [ ] Add bounded provider-error-status type/field to diagnostics.
- [ ] Add Gemini HTTP error status classifier.
- [ ] Add focused redaction/classification tests.
- [ ] Preserve request-envelope regression test.
- [ ] Run CI/review and create Draft PR.

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

This slice identifies a safe provider status category; it does not itself correct the underlying Gemini 400.

### Final Status

`REVIEW`
