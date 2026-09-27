# Pre-P9 — Supabase foundation task supersession

**Status:** In progress
**Implementation owner:** ChatGPT
**Base:** `main@df617c4709e96c2a16aed0ea20ea3560bcd7039f`
**Scope:** docs/AI handoff lifecycle only

## Discovery

The active `.ai/tasks/supabase-foundation.md` is a historical foundation plan whose runtime statements now contradict current executable and canonical truth. Current evidence verifies an active root `supabase/` workspace, Supabase Auth/data ownership, 49 applied/repository-aligned migrations, 14 public tables with RLS, and Supabase-backed authenticated App Mode preferences.

Linear reconciliation was attempted before implementation on 2026-09-27 but the connector returned `502 upstream_unavailable`. No Linear state is inferred or changed in this slice.

## In scope

- Preserve the old foundation brief as a `Superseded` archive record.
- Remove the stale active task copy from `.ai/tasks/`.
- Update `.ai/archive/README.md` with the supersession record.
- Remove the retired brief from `.ai/tasks/README.md` Current Tasks.
- Replace the canonical `SUPABASE_STRATEGY.md` link that currently points readers back to the stale active task with current canonical/runtime references.

## Out of scope

- Runtime, Flutter, Auth, session, routing, App Mode, or repository behavior.
- Supabase schema, migration, RLS, RPC, Storage, Edge Function, Auth configuration, or live data mutation.
- Future `services/api` implementation.
- Re-scoping existing Linear/GitHub feature issues.
- GitHub #250 phase acceptance or P9 start/decision.

## Verified evidence

- Root `AGENTS.md` identifies `supabase/*` as active current Auth/Postgres/RLS/Storage/migration ownership.
- `docs/data/SUPABASE_STRATEGY.md` is canonical and records active Supabase foundation.
- `docs/data/SUPABASE_SCHEMA.md` records 49/49 migrations, 14 public tables, and 14/14 RLS at its verified snapshot.
- Live Supabase project `tio-world` was read-only verified healthy during audit; live migration list reaches `20260918184442_add_user_profile_country_code`.
- The stale task still claims no `supabase/`, UI-only login, device-local-first App Mode persistence, and final `BLOCKED` state.

## Decision

Do not rewrite the historical task into a second current Supabase source of truth. Archive it as superseded and route readers to canonical docs/runtime. Existing future work remains owned by its dedicated tracker issues.

## Validation

- [x] Exact changed paths reviewed: one historical task rename/archive, archive index, canonical strategy Related links, ADR-0003 Related link, and this handoff.
- [x] Repository default-branch code search found two canonical references to the retired active-task path (`SUPABASE_STRATEGY.md`, ADR-0003); both are reconciled in this branch. Codex exact-head review additionally identified the `.ai/tasks/README.md` Current Tasks index entry; that stale/broken row is removed.
- [ ] `git diff --check` cannot be executed through the connected GitHub API; no local-check pass is claimed. Hosted review/check evidence will be recorded from the PR.
- [ ] Exact-head re-review required after resolving Codex P2: retired task remained listed in `.ai/tasks/README.md` Current Tasks.

## Handoff

Current verdict: **REVIEW** — implementation scope is complete; exact-head review remains.
