# TNYX-238 — Open Food Facts capability validation

## Goal
Validate whether Open Food Facts can supply factual calories/protein/carbs/fat for fixed synthetic foods before any production resolver change.

## Base
`4d552e685e2928dd77a1c5e5a2ba31e8281e43e4`

## Scope
- read-only public Open Food Facts capability probe
- fixed synthetic queries only: plain yogurt, dal, roti, dahi
- no user text, identity/profile data, secrets, persistence, Flutter/UI, schema/RLS/RPC
- no production parser routing change
- no deployment without separate owner approval
- bounded output only: query, result category, matched product name, per-100g energy/protein/carbs/fat when all required values are factual and finite

## Safety
- never fabricate missing nutrients
- never combine nutrients across products
- discard raw provider bodies and URLs from output
- send an identifying User-Agent as required by provider guidance

## Validation
- focused unit tests for complete mapping, missing nutrient => incomplete, malformed response => unavailable
- live deployment/execution remains separately authorized

## Handoff
Record each synthetic case as resolved/incomplete/unavailable and assess whether a separate production adapter slice is justified.
