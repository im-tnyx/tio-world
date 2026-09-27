# Implementation Status

Document Status: Dynamic Current-State Snapshot
Last Verified: 2026-09-27
Owner: repository execution context
Truth Boundary: High-level implementation orientation only; source/runtime proves shipped behavior, canonical docs define intended architecture, and Linear plus linked GitHub own current work status.

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
| Supabase public data model | Live, canonical inventory available | `docs/data/SUPABASE_SCHEMA.md` records the verified readable inventory; migrations plus verified live schema remain executable truth. |
| Product Onboarding O1–O11 | Validated / complete | GitHub #40 is complete/frozen; O11 cleanup #54 is complete. Historical per-slice CI remains evidence, not current work. |
| Product Onboarding implementation PR #50 | Merged / closed | Not an active PR and must not be used as a current blocker. |
| Health Connections in onboarding | Validated availability/connect-later boundary | Completed onboarding does not authorize broad Health Connect/HealthKit record access. Future consuming features must define least-privilege data scope first. |
| Canonical account/profile/preferences/health ownership | Live baseline with follow-up umbrella open | GitHub #44 remains open for post-onboarding ownership/runtime lanes; re-read current issue scope before changes. |
| App/router composition cleanup | Open tracker work | #260 and #357 are live planning/execution references; tracker existence is not implementation authorization. |
| Nutrition loading-state fix | Open tracker work | #356 owns the Daily Nutrition loading-card issue. |
| Onboarding package architecture cleanup | Open tracker work | #261 owns package/public-API/responsibility cleanup. |
| Auth hardening | Open tracker work | #34 is the live auth-hardening tracker; Auth remains security-sensitive. |
| Nutrition/workout settings/runtime preferences | Open tracker work | #46/#47/#48 own separate settings/runtime-preference lanes. |
| N5D meal text/provider routing | Open tracker work | #269/#284 own the current N5D planning slices. |
| Future protected API | Planned/Future | Canonical path is `services/api/`; no speculative service implementation should be inferred. |
| Future async worker | Planned/Future | `services/worker/` only when an approved real async workload requires it. |
| Wear OS / Apple Watch | Planned/Future | Native companion surfaces remain separately planned/gated; inspect wearable docs and trackers before work. |
| Documentation governance | In progress | GitHub #250 / Linear TNYX-193; P1–P6 and P8 complete, P7 current, P9 separately gated. |

## Current execution rules

- There are no open pull requests at this verification checkpoint.
- Open GitHub issues are not a priority queue. Use Linear + linked GitHub reconciliation to determine the authorized slice.
- Before meaningful work, read the applicable `AGENTS.md`, inspect source/runtime, then reconcile canonical docs, Linear, GitHub, CI, and the relevant `.ai/tasks/` handoff.
- A historical exact CI checkpoint proves only the source state it validated; it does not make an old task brief current.
- Applied Supabase migrations are immutable; new database changes must be forward-only and owner-approved where the canonical gate applies.
- Health, Auth/OAuth, connectors, secrets, privileged APIs, RLS, and AI providers are security-sensitive boundaries. Use least privilege and keep privileged credentials/operations server-side.
- UI changes require the repository's owner/design approval rules; internal docs work does not authorize visual redesign.
- Do not create `services/api/`, `services/worker/`, web, watch, connector, or other future infrastructure merely because it is documented as planned.

## Known documentation follow-up outside P7

`.ai/tasks/product-onboarding-canonical-execution.md` and related rows in `.ai/tasks/README.md` still describe the old O7-blocked / PR #50 draft-open checkpoint. P7 deliberately does not widen into that lifecycle cleanup.

Until that separate cleanup is authorized, do not use those stale task entries as current sequencing truth; use source, canonical docs, and live trackers.
