# TNYX-229 — Gemini generateContent structured-output compatibility fix

**Status:** Review ready
**Primary owner:** ChatGPT
**Affected platforms:** Supabase Edge Function only

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Owner explicitly said `go` after live v30 smoke reproduced Gemini `400 INVALID_ARGUMENT` with `providerErrorField=response_format`, and an external minimal request isolated rejection to `generation_config.response_format.text.mime_type`.
**Approved product/UI/data-shape boundaries:** Existing TNYX-229 Gemini request compatibility defect only.
**Explicit non-changes:** No Flutter/UI, no model change, no prompt/schema semantic change, no provider-order/fallback change, no diagnostic weakening, no secret/config change, no schema/RLS/RPC/migration, no deploy, no merge, no TNYX-226 work.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** ChatGPT
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub `main@dec0fa275cc531c8c8f412d138962ca5768131dd`; live parser ACTIVE v32, `verify_jwt=true`, bundle SHA `a17d79c84dfd9a17a719641681c33f47dd9cdce201a22d0f42b22db35e2d15ff`.
**Branch:** `tnyx/tnyx-229-gemini-generate-content-compat`
**HEAD SHA:** `dec0fa275cc531c8c8f412d138962ca5768131dd` at branch creation
**Observed working-tree state:** Not applicable through GitHub connector; branch created from exact current main.
**Observed uncommitted/dirty files:** Not observable / not applicable to connector-only execution.
**PR / tracker:** Draft PR #298; TNYX-229 In Progress; TNYX-226 Backlog / blocked.
**Current implementation state:** GenerateContent compatibility envelope implemented; source validation passed.
**Relevant execution surface:** `supabase/functions/nutrition-meal-text-parse`
**Validation completed at SHA:** `3f41f59e770d28aa2df74cee82a5196574c490f3` — Supabase Functions CI #39 PASS.
**Validation remaining:** Exact final-head CI after this docs-only handoff sync.
**Current blocker:** Live acceptance remains unverified until separate merge/deploy/smoke authorization.
**Open review finding IDs:** None.
**Next exact action:** Exact final-head CI, final review, then Ready for Review. Do not merge/deploy without separate owner authorization.

## 1. Discovery

### User Outcome

Remove the reproducible Gemini `response_format` request rejection while preserving all existing parser behavior, diagnostics, privacy boundaries, provider ordering, and fallback behavior.

### Success Criteria

- Request still targets `gemini-3.8-flash` via the same v1beta `:generateContent` endpoint.
- `generationConfig` sends `responseMimeType: "application/json"` and `responseSchema: geminiInterpretationSchema`.
- `generationConfig.responseFormat` is absent.
- Prompt, schema content, timeout, auth header, parser normalization and fallback behavior remain unchanged.
- Existing safe `providerErrorStatus/providerErrorReason/providerErrorField` diagnostics remain unchanged.
- Focused tests prove the exact envelope and absence of the rejected shape.

### Scope

- `gemini_client.ts`: structured-output envelope only.
- `gemini_client_test.ts`: request-envelope regression only.
- this task handoff and PR metadata.

### Non-Goals

- Do not claim this shape is proven live-successful before deployment/smoke.
- Do not change API key or Supabase secrets.
- Do not alter `geminiInterpretationSchema`.
- Do not remove safe diagnostics.
- Do not deploy or merge.
- Do not start TNYX-226.

## 2. Codebase Exploration

### Verified Evidence

- Current runtime sends `generationConfig.responseFormat.text.mimeType/schema`.
- Live authenticated v30 smoke: overall draft succeeded through fallback while Gemini returned `400 INVALID_ARGUMENT`, `providerErrorReason=UNKNOWN`, `providerErrorField=response_format`.
- External minimal request using the current shape reproduced `400 INVALID_ARGUMENT` at `generation_config.response_format.text.mime_type`.
- External legacy-shape test reached `403 PERMISSION_DENIED`; therefore legacy shape is **not yet proven to return 200**.
- Current official Google docs are inconsistent:
  - GenerateContent API reference and migration guide document `responseMimeType/responseSchema` for generateContent structured output.
  - Gemini 3 / structured-output pages also show `responseFormat.text.mimeType/schema`.
- The implementation choice is therefore a bounded compatibility change based on live rejection evidence plus the documented legacy GenerateContent fields, not a claim that all Google docs agree.
- Some older repository docs still mention future `backend/*`; root `AGENTS.md` + current architecture lock future protected work to `services/api`. This slice creates neither.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Blindly call old shape proven-good? | Rejected | Terminal old-shape call returned 403, not 200. | ChatGPT |
| Change model/key/schema together? | Rejected | Would destroy isolation of the request-envelope defect. | ChatGPT |
| Switch only GenerateContent envelope | Chosen | Smallest reversible change matching isolated live failure evidence. | ChatGPT |
| Remove diagnostics after envelope change | Rejected | Diagnostics are still needed for live verification and key/permission separation. | ChatGPT |

## 4. Architecture Design

### Chosen Approach

Keep the same endpoint, model, prompt, schema object and parser. Change only:

```text
generationConfig.responseFormat.text.mimeType/schema
→
generationConfig.responseMimeType/responseSchema
```

No other runtime path changes.

### Ownership and Data Flow

`meal text -> unchanged Gemini interpreter -> same generateContent endpoint -> compatibility request envelope -> unchanged response parser -> unchanged fallback`

### Alternative Rejected

Changing secrets, model, schema keywords or endpoint in the same slice was rejected because it would make the live result non-diagnostic.

### Failure and Accessibility States

No UI/accessibility surface changes. Any remaining Gemini failure still emits bounded diagnostics and falls back exactly as today.

## 5. Implementation Plan

- [x] Change only Gemini structured-output request envelope.
- [x] Update exact request-envelope regression test.
- [x] Preserve safe diagnostics and fallback tests.
- [x] Audit exact main-to-branch delta.
- [x] Open Draft PR and run Supabase Functions CI.
- [ ] Final exact-head CI/review and Ready for Review; stop before merge/deploy.

## 6. Quality Review

### Validation Run

- Supabase Functions CI #39 on source head `3f41f59e770d28aa2df74cee82a5196574c490f3`: PASS.
- Parser entrypoint type-check: PASS.
- Parser source/tests type-check: PASS.
- Parser tests: PASS.
- Complete `main...branch` delta reviewed: exactly 3 owned files.
- Runtime diff is limited to replacing `responseFormat.text.mimeType/schema` with `responseMimeType/responseSchema`.
- Request-envelope regression asserts the compatibility fields and absence of `responseFormat`.
- Safe diagnostics/model/endpoint/prompt/schema/fallback remain unchanged.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-229-gemini-generate-content-compat.md`
- `supabase/functions/nutrition-meal-text-parse/gemini_client.ts`
- `supabase/functions/nutrition-meal-text-parse/gemini_client_test.ts`

### Actual Behavior

The Gemini interpreter now sends GenerateContent structured-output configuration through `generationConfig.responseMimeType` and `responseSchema`. The live-rejected `generationConfig.responseFormat` structure is absent. All other interpreter and fallback behavior is unchanged.

### Known Limitations

Passing CI can prove request construction only, not Google live acceptance. A separate owner-authorized merge/deploy and authenticated smoke is required to determine whether Gemini succeeds, returns a permission/key error, or exposes another bounded provider error.

### Final Status

`REVIEW`
