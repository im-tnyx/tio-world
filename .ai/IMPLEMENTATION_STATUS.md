# Implementation Status

Document Status: Dynamic Current-State Snapshot
Last Verified: 2026-09-27
Owner: repository execution context
Truth Boundary: High-level implementation orientation only; source/runtime proves shipped behavior, canonical docs define intended architecture, and Linear plus linked GitHub own current work status.

## Verification baseline

Refreshed against `main@0a534984793714ad46e23f40b366f7ca8c82c2f3` after PR #423 merged. Live work status must still be re-queried before implementation because PR, issue, CI, and Linear state can change after this checkpoint.

## Status model

Use these terms only after checking the relevant source and evidence:

- **Planned/Future** — approved direction exists but the implementation is not current runtime.
- **Implemented** — intended source exists; do not infer full acceptance without evidence.
- **Validated** — applicable validation evidence is recorded for an exact source state.
- **Live** — deployed/persisted infrastructure has been verified where that distinction matters.
- **Open tracker** — work exists in GitHub/Linear; it does not by itself authorize implementation.

## Current capability snapshot

| Capability | Current state | Authority / boundary |
|---|---|---|
| Flutter mobile application | Active runtime | Source under `apps/` proves behavior; canonical mobile/architecture docs define intended boundaries. |
| Supabase Auth/session | Active runtime | Supabase is the current identity/session boundary; verify source and security docs before auth changes. |
| Supabase public data model | Live, canonical inventory available | `docs/data/SUPABASE_SCHEMA.md` records the readable verified inventory; migrations plus verified live schema remain executable truth. |
| Product Onboarding O1–O11 | Validated / complete historical lane | GitHub #40 is complete/frozen and #54 cleanup is complete; historical per-slice CI remains evidence, not current sequencing. |
| Product Onboarding implementation PR #50 | Merged / closed | Not an active PR and must not be used as a current blocker. |
| Product Onboarding execution handoff | Superseded / archived | PR #423 removed the stale handoff from active tasks; its archived checkpoint is historical only. |
| Health Connections in completed onboarding | Validated availability/connect-later boundary | Completed onboarding does not authorize broad Health Connect/HealthKit record access. Future consuming features must define least-privilege scope. |
| Canonical account/profile/preferences/health ownership | Follow-up umbrella open | GitHub #44 remains open; re-read live issue/source before changes rather than inferring unfinished runtime from the tracker alone. |
| App/router organization | Open tracker work | Live GitHub work exists; query current issue/PR state before any slice. |
| Nutrition loading/calendar behavior | Open tracker work | Live GitHub work exists; query current issue/PR state before any slice. |
| Onboarding package architecture cleanup | Open tracker work | Live GitHub work exists; tracker presence is not implementation authorization. |
| Auth hardening | Open tracker work | Auth remains security-sensitive; reconcile current source and live tracker before changes. |
| Nutrition/workout settings/runtime preferences | Open tracker work | Multiple independent live tracker lanes exist; do not collapse them into one implementation scope. |
| N5D meal/provider routing | Open tracker work | Live planning/PR work exists; re-query before implementation. |
| Future protected API | Planned/Future | Canonical path is `services/api/`; no speculative service implementation should be inferred. |
| Future async worker | Planned/Future | `services/worker/` only when an approved real async workload requires it. |
| Wear OS / Apple Watch | Planned/Future | Companion surfaces remain separately planned/gated; inspect wearable docs and trackers before work. |
| Documentation governance | In progress | GitHub #250 / Linear TNYX-193; P1–P8 complete, pre-P9 reconciliation active, P9 separately gated and Not started. |

## Current execution rules

- A fresh GitHub query at this checkpoint returned open PRs; never assume the repository has no open PRs without querying live state.
- Open GitHub issues/PRs are not a priority queue. Use Linear + linked GitHub reconciliation to determine the authorized slice.
- Before meaningful work, read the applicable `AGENTS.md`, inspect source/runtime, then reconcile canonical docs, Linear, GitHub, CI, and the relevant `.ai/tasks/` handoff.
- A historical exact CI checkpoint proves only the source state it validated; it does not make an old task brief current.
- Applied Supabase migrations are immutable; new database changes must be forward-only and owner-approved where the canonical gate applies.
- Health, Auth/OAuth, connectors, secrets, privileged APIs, RLS, and AI providers are security-sensitive boundaries. Use least privilege and keep privileged credentials/operations server-side.
- UI changes require the repository's owner/design approval rules; internal docs work does not authorize visual redesign.
- Do not create `services/api/`, `services/worker/`, web, watch, connector, or other future infrastructure merely because it is documented as planned.

## Known documentation follow-up outside this refresh

`.ai/tasks/README.md` still contains a historical Product Onboarding execution-order block that marks O1 as NEXT even though GitHub #40 is complete/frozen. PR #423 removed the stale canonical execution handoff and its active index row, but this remaining block needs a separately bounded index-lifecycle cleanup.

Do not use that block as current Product Onboarding sequencing truth. For any new onboarding work, reconcile current source, canonical onboarding docs, and live trackers.
