# TNYX-229 — Redacted parser runtime diagnostics

**Status:** In progress
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
