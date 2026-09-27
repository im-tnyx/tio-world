# Current State

Document Status: Dynamic Current-State Snapshot
Last Verified: 2026-09-27
Owner: repository execution context
Truth Boundary: Orientation only; runtime/source proves behavior, canonical docs own approved architecture/policy, and Linear plus linked GitHub own live task/phase status.

## Verification baseline

This snapshot was reconstructed for TNYX-193 P7 from `main@0248fab407201bf5b8debd71262c871a4beb98a4`, current canonical docs, and live GitHub/Linear tracker state.

Do not treat this file as a backlog, release record, architecture authority, or substitute for source inspection.

## Read order

1. Applicable `AGENTS.md`.
2. Runtime/source/config for the surface being changed.
3. `docs/README.md` for documentation authority and conflict rules.
4. Relevant canonical docs/ADRs.
5. Linear issue/project plus linked GitHub issue/PR/CI for current execution state.
6. Relevant active `.ai/tasks/` brief only after confirming it is current.

## Current platform boundary

- Flutter mobile is the active application surface.
- Supabase is active infrastructure for Auth and repository-owned persisted data.
- The readable current public-schema inventory is `docs/data/SUPABASE_SCHEMA.md`; executable database truth remains checked-in migrations plus verified live schema.
- Future protected server work belongs under `services/api/` only when an approved need exists. Do not create speculative backend/service scaffolding.
- `services/worker/` remains future-only and requires a real approved asynchronous workload.
- Wear OS and Apple Watch are planned/future native companion surfaces; verify their canonical wearable docs and trackers before implementation.
- AI/connectors and external integrations remain security-sensitive boundaries; verify their current approved scope before adding credentials, scopes, privileged APIs, or data access.

## Product Onboarding status

The historical Product Onboarding O1–O11 execution is complete/frozen in GitHub #40.

- O1–O10 implementation/acceptance is complete.
- O11 canonical schema cleanup is complete in GitHub #54.
- Health Connections onboarding remains availability/connect-later only for the completed onboarding scope; future health-data authorization belongs to a separately approved consuming feature.
- PR #50 is merged/closed. It is not an active implementation PR.
- GitHub #44 remains open as the broader canonical-ownership umbrella for post-onboarding Account/Settings/runtime lanes.

The old `.ai/tasks/product-onboarding-canonical-execution.md` and related task-index wording still describe an earlier O7-blocked execution checkpoint. They are not current sequencing authority. Their lifecycle cleanup is a separate bounded follow-up, not P7 scope.

## Live work context

At verification time there are no open pull requests. The open issue set includes multiple independent lanes; examples relevant to architecture/execution routing include:

- #357 and #260 — app router/composition organization;
- #356 — Daily Nutrition loading-state behavior;
- #261 — onboarding package architecture/public API/responsibility cleanup;
- #34 — auth hardening;
- #44 — canonical account/profile/preferences/health ownership umbrella;
- #46/#47/#48 — mode-aware nutrition/workout settings and runtime preferences;
- #157 — proposed health-data JSONB consolidation;
- #269/#284 — N5D meal-text processing and country/region provider routing;
- #250 / Linear TNYX-193 — documentation governance, including this P7 reconstruction.

This list is orientation, not priority ordering and not a complete planning source. Re-read the live trackers before starting any slice.

## Documentation-governance status

GitHub #250 / Linear TNYX-193 is the active governance tracker.

- P1–P6 and P8 are completed.
- P7 is the current authorized docs-only reconstruction slice.
- P9 remains separately gated and should not be inferred from P7.
- Supplemental GitHub AI code-scanning has a known unsupported-model infrastructure outage tracked separately by TNYX-256; do not represent that failure as a security pass or repository finding.

## Guardrails

- Audit before implementation and work slice-by-slice.
- Do not infer authorization from tracker existence.
- Reconcile source/runtime, canonical docs, Linear, and GitHub when they disagree.
- Do not revive historical `.ai/tasks/` state as current truth without live verification.
- Keep secrets and privileged credentials server-side and apply least privilege at Auth/OAuth/connectors/health/AI boundaries.
- No speculative services, schema, permissions, or broad health-data scopes.
