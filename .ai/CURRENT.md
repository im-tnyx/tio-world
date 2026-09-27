# Current State

Document Status: Dynamic Current-State Snapshot
Last Verified: 2026-09-27
Owner: repository execution context
Truth Boundary: Orientation only; runtime/source proves behavior, canonical docs own approved architecture/policy, and Linear plus linked GitHub own live task/phase status.

## Verification baseline

This snapshot was refreshed from `main@7a243122a58baa2cf1e03fa785669339e89940c5` after the pre-P9 Product Onboarding task-index reconciliation and its archive lifecycle completed via PRs #426 and #427, with GitHub #250 and Linear TNYX-193 re-queried.

Do not treat this file as a backlog, release record, architecture authority, or substitute for source inspection. Live tracker state can change immediately after this checkpoint.

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
- Wear OS and Apple Watch remain separately planned/gated companion surfaces; verify their canonical wearable docs and live trackers before implementation.
- AI/connectors and external integrations remain security-sensitive boundaries; verify current approved scope before adding credentials, scopes, privileged APIs, or data access.

## Product Onboarding status

The historical Product Onboarding O1–O11 execution lane is complete/frozen in GitHub #40.

- O11 canonical schema cleanup #54 is complete.
- PR #50 is merged/closed and is not an active implementation PR.
- The former `.ai/tasks/product-onboarding-canonical-execution.md` handoff was retired by PR #423 and is preserved only as a Superseded/Historical archive record.
- GitHub #44 remains the broader open canonical-ownership umbrella; its current live scope must be re-read before new work.
- Completed onboarding does not itself authorize broad Health Connect/HealthKit record access; any future consuming feature must establish its own approved least-privilege scope.

- The stale `.ai/tasks/README.md` O1/O1F current-sequencing wording was reconciled by PR #426; its validated handoff was archived by PR #427. The historical O1–O11 lane remains reference-only, not current sequencing truth.

## Live work context

A fresh GitHub query at this checkpoint returned open pull requests, so the previous P7 statement that there were no open PRs is no longer current.

Do not copy the full open PR or issue set into this snapshot: it is volatile and is not a priority queue. Before starting or resuming work, query the live Linear issue/project and linked GitHub issue/PR/CI, then reconcile them with source, canonical docs, and the relevant active handoff.

Representative live lanes at this checkpoint include app/router organization, Nutrition loading/calendar behavior, onboarding package cleanup, auth hardening, account/profile/preferences ownership, settings/runtime preferences, N5D meal/provider work, and repository documentation governance. Their presence does not authorize implementation or establish priority.

## Documentation-governance status

GitHub #250 / Linear TNYX-193 remains the active documentation-governance tracker.

- P1–P8 are completed.
- The stale Product Onboarding execution handoff cleanup merged via PR #423; the remaining task-index sequencing drift was reconciled by PR #426 and its handoff archived by PR #427.
- The current work is a bounded post-index snapshot reconciliation before #250 acceptance bookkeeping; it is not P9.
- P9 remains separately gated and Not started; its routing-map decision must be made only after the pre-P9 alignment baseline is clean.
- Supplemental GitHub AI code-scanning has a known unsupported-model infrastructure outage tracked separately by TNYX-256; do not represent that failure as a security pass or repository finding.

## Guardrails

- Audit before implementation and work slice-by-slice.
- Do not infer authorization from tracker existence.
- Reconcile source/runtime, canonical docs, Linear, and GitHub when they disagree.
- Do not revive historical `.ai/tasks/` state as current truth without live verification.
- Keep secrets and privileged credentials server-side and apply least privilege at Auth/OAuth/connectors/health/AI boundaries.
- No speculative services, schema, permissions, or broad health-data scopes.
