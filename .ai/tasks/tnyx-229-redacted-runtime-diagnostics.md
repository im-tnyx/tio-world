# TNYX-229 — Redacted parser runtime diagnostics

**Status:** Reconciled; validation pending
**Branch:** `tnyx/tnyx-229-redacted-runtime-diagnostics`

## Purpose

Add bounded server-only diagnostic events so the existing safe `unavailable` result can be attributed to auth/profile, interpreter, factual resolver, or request deadline stages.

## Safety

Diagnostic output is limited to static stage/provider/reason identifiers and numeric HTTP status. Do not record request content, identity/session material, credentials, provider response bodies, URLs, profile values, or stack traces.

## Scope

- Preserve the client response contract.
- Add focused tests for redacted diagnostic behavior.
- For Edamam non-2xx responses, classify only an allowlisted provider error category derived from a bounded JSON error envelope. Never log the raw response body/message, URL, query parameters, credentials, or meal text. This is diagnostic-only and must not change resolver outcomes.
- No Flutter/UI or TNYX-226 work.
- No schema/RLS/RPC/migration.
- No provider/model selection change.
- No live deployment in this slice without separate owner authorization.

## Validation

Run focused parser tests and source-safety checks, including Edamam 401 classification/redaction tests, then review the complete branch delta before deployment handoff.


## Edamam 401 refinement — 2026-09-20

Fresh authenticated v21 production smoke:
- `200 g plain yogurt`
- controller status: `failed`
- elapsed: 5381 ms
- sanitized message: `Couldn't resolve enough meal details. Try adding amounts or serving sizes.`
- no draft fields
- correlated redacted diagnostic: `resolver_unavailable / edamam / http_error / 401 / authentication`
- no Gemini HTTP 400 diagnostic observed in the smoke window

Interpretation boundary:
- absence of a Gemini failure diagnostic plus reachability of Edamam strongly indicates interpretation advanced to factual resolution, but there is no separate interpreter-success event and no provider-success event; do not overstate which interpreter supplied the recognized candidate.
- the current live diagnostic classifies any otherwise-unclassified HTTP 401 as `authentication`. Therefore the observed category alone does not prove the app_id/app_key pair itself was rejected.

Current official Edamam guidance says:
- credentials are API-specific and must belong to the exact API application;
- a 401 can also occur when account/API usage limits are reached;
- Food Database v2 parser remains `/api/food-database/v2/parser`.

Bounded diagnostic refinement on this branch:
- inspect only bounded JSON `code`, `error`, and `message` strings in memory;
- map quota/limit/rate signals to `rate_limit`;
- map known unauthorized/wrong-API/auth/credential signals to `authentication`;
- preserve plan/subscription/entitlement/access as `authorization_or_entitlement`;
- unclassified/non-JSON 401 now maps to `unknown` rather than overclaiming authentication;
- never log the raw strings/body, URL/query params, app credentials, meal text, or identity.

This changes diagnostics only. Resolver outcome remains `unavailable`. No config/secret/provider selection/schema/UI change and no deployment is authorized by this source refinement.

Next gate after CI/review is separate deployment authorization for only this diagnostic refinement, followed by one authenticated v21 smoke. If the result is:
- `authentication`: owner verifies the Food Database application credential pair;
- `rate_limit`: owner checks Edamam application usage/quota/plan;
- `authorization_or_entitlement`: owner checks the application's plan/access;
- `unknown`: use Edamam dashboard/support evidence rather than expanding logs or exposing raw provider text.


## Post-#292 branch reconciliation — 2026-09-20

PR #292 merged to current `main` as `16cb3696e2b296cc3dbe122511f54ac5ee3e841e`. This diagnostic branch is reconciled without history rewrite or force-push.

Reconciliation rule:
- current `main` is the tree baseline;
- preserve the merged Gemini `generationConfig.responseFormat.text` request contract and its focused regression test;
- overlay only this PR's reviewed redacted diagnostic changes;
- preserve current-main files not owned by this diagnostic slice;
- no live deployment, secret/config change, schema/RLS/RPC, Flutter UI, or TNYX-226 work.

Expected post-reconciliation PR delta remains diagnostic-only:
- this task brief
- `diagnostics.ts` and focused diagnostic tests
- redacted diagnostic hooks in `index.ts`, `gemini_client.ts`, `openai_client.ts`, and `edamam_client.ts`

The current live v25 bundle already contains the older diagnostic implementation plus the merged Gemini runtime fix. This PR's refined Edamam classification remains source-of-truth work until separately authorized for deployment.

Next gate: current-head Supabase Functions CI + complete diff review. Do not merge or deploy without separate owner authorization.
