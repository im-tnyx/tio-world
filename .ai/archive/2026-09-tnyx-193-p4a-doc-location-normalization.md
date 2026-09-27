# TNYX-193 P4A — Documentation Location Normalization

**Status:** Validated
**Primary owner:** repository documentation governance
**Affected platforms:** documentation only
**Completed:** 2026-09-27
**Tracker:** GitHub #250 / Linear TNYX-193

## Outcome

P4A normalized Tio-world canonical documentation by durable ownership.

- Canonical docs now use ownership folders under `docs/architecture/`, `docs/planning/`, `docs/mobile/`, `docs/wearables/`, `docs/data/`, `docs/backend/`, `docs/security/`, and `docs/development/`.
- Existing `docs/adr/` and `docs/screens/` ownership remains unchanged.
- Repository workflow/process docs moved from `docs/` to `.github/POST_MERGE_SYNC.md` and `.github/PUSH_TEMPLATE.md`.
- `docs/README.md` now documents the location/ownership taxonomy.
- No `docs/status/` was created; live task/phase status remains owned by Linear plus linked GitHub.
- `docs/integrations/` remains a future destination and was not materialized as an empty speculative folder.
- P4B's future readable schema inventory location is fixed at `docs/data/SUPABASE_SCHEMA.md`.
- Stale `.ai` orientation content remains a separately bounded follow-up rather than being promoted into canonical docs.

## Scope Boundary

Owner authorized P4A after the read-only location audit and taxonomy decision.

P4A changed documentation/governance surfaces only. It did not change runtime/UI/routing/state, Supabase schema/migrations/RLS/Storage/functions/Auth, CI workflows, lockfiles, future services, P4B schema inventory content, P5/P6 governance headers, P7 `.ai/CURRENT.md`, or connector implementation.

One old documentation path string remains inside `supabase/migrations/20260903052101_reconcile_legacy_lineage_state.sql`. The historical migration remained byte-identical and had zero net diff; P4A intentionally did not rewrite applied migration history.

## Final Evidence

- source base: `main@1e22f623454b85b432aa2ea0dedcc6d31a90d9ba`
- final reviewed source head: `bc601768f903337611d35d4c1eec4e03909944ad`
- source PR: #412
- squash merge: `aa42e7f5c59e1dcea7fc331572626ff004d6be70`
- source net paths: 111
- approved renames: 29
- approved final paths present: 29/29
- old canonical paths remaining: 0
- changed Markdown link refs: 279
- unique changed Markdown targets: 74
- missing changed Markdown targets: 0
- exact patch scan: trailing whitespace 0; conflict markers 0; missing-final-newline markers 0
- net `apps/**`: 0
- net `services/**`: 0
- net `supabase/**`: 0
- net `.github/workflows/**`: 0
- lockfiles: 0
- Codex exact-head review: no major issues
- unresolved review threads before merge: 0
- Commit attribution guard: PASS
- Attribution guard runner: PASS
- supplemental `github-advanced-security`: FAILURE before meaningful analysis with `400 The requested model is not supported`; tracked separately under TNYX-256 and not represented as a security pass or concrete repository finding
- remote `main` verified at `aa42e7f5c59e1dcea7fc331572626ff004d6be70` after merge

## Tracker Reconciliation

After merge automation temporarily completed the umbrella Linear issue:

- GitHub #250 remains open because P4B/P5/P6/P7/P9 remain separately gated;
- Linear TNYX-193 was restored to `In Progress`;
- P4A is marked completed in both trackers;
- no later phase is authorized by the P4A merge.

## Deferred Follow-up

P4A confirmed factual drift in `.ai/architecture-summary.md`, `.ai/project-context.md`, and `.ai/supabase-rules.md`. Their location is correct; content reconciliation remains a separate P7-adjacent/follow-up governance slice.

## Final Status

`VALIDATED — MERGED VIA PR #412 (aa42e7f5)`

No P4B/P5/P6/P7/P9 implementation is authorized by this archived handoff.
