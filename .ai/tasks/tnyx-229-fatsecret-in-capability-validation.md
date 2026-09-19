# TNYX-229 — FatSecret IN capability validation

**Status:** In progress
**Branch:** `tnyx/tnyx-229-fatsecret-in-capability-validation`

## Purpose

Validate the existing FatSecret credentials/Basic integration against a synthetic India (`IN`) provider request without changing production routing. Current runtime intentionally returns `incomplete` before any FatSecret network call for non-US country codes, so existing India smoke evidence does not prove whether FatSecret itself accepts or rejects India.

## Scope

- Add a test/diagnostic-only FatSecret capability probe owned by the server parser package.
- Expose it only through a separately deployed temporary authenticated diagnostic Edge Function; do not add a route/mode to the production meal parser.
- Reuse the existing server-side FatSecret credential names.
- Probe only synthetic, non-personal food text.
- Distinguish bounded stages: OAuth token, India-region search, food detail.
- Report only safe status/category metadata.
- Never print tokens, credentials, Authorization headers, provider response bodies, URLs/query strings, or user data.
- Keep `fatSecretRegionForCountry` production behavior unchanged.
- No Flutter/UI, schema/RLS/RPC/migration, provider entitlement purchase/trial, secret mutation, deployment, or TNYX-226 work.

## Architecture

The probe is not part of the production request path. It exists only to answer whether the current FatSecret account/API credentials can complete the existing provider operations with `region=IN`. Production remains fail-closed for non-US until evidence supports a separately reviewed source change.

## Validation

- Type-check the diagnostic source.
- Run synthetic tests with mocked provider responses for success and safe failure classification.
- Source-safety review confirms no credential/token/body leakage.
- A live provider probe, if needed, must run only in an approved server-side environment with existing secrets and synthetic input; no production routing change.

## Handoff

Record whether OAuth, `IN` search, and detail are accepted or rejected. Do not infer commercial entitlement from a successful technical call alone.
