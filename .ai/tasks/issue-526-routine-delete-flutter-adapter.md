# GitHub #526 — Flutter Routine Delete RPC adapter (Slice A)

**Status:** Implementation in progress; CI/review not yet run.
**Implementation owner:** This GitHub-connected implementation session.
**Branch:** `tnyx/issue-526-routine-delete-flutter-adapter` from live `main@6cb353eaf492f178c707a94178e5d34f19c8ea04` (2026-10-17).
**Scope approval:** Owner's `Go` following the read-only #526 audit and explicit proposal to start **Slice A** only. No authority to deploy, merge, activate UI Delete, or modify Supabase schema.

## Reconciled evidence

- Repo and feature `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, canonical Workout screens, ADR-0015, core design usage, GitHub #526/#564/#569, Linear TNYX-81 reviewed. Live main was advanced by four docs-only merges after PR #581. No open PRs at slice start.
- PR #581 merged the shared Routine action sheet into `main`, with optional hidden `onDelete` capability. `RoutineRepository` still exposes only list/create/rename. `ProgramDetailPage`, expanded Library, and shell do not wire Delete.
- Tio Supabase live project `oykupyiitspujzpwwvuj`: 62 migrations applied, including `20261016183000` and `20261016220000`; `delete_user_workout_routine(uuid,uuid,bigint)` exists with execute to authenticated only; table DELETE is denied; private retired-ID ledger, insert guards and FK child cascades are present. No need for new DDL.
- `docs/data/SUPABASE_STRATEGY.md` had older count/deploy claims before docs-only PR #585; this branch starts from the corrected docs. Other historical `.ai/tasks` status lines remain stale; do not treat them as runtime truth.
- Local Windows repo was previously reported clean on main `633dbf38`; this GitHub session cannot read the current Windows working tree. No local machine files touched.

## Product and architecture contract

Slice A is an **inert capability provider** behind Workout's domain/data boundary: a narrow owner-scoped Delete RPC transport, frozen Routine+Program+expectedRevision target and sanitized outcome classes, explicit owner/login-cycle binding, and focused mocked-SDK tests. Confirm a fresh owner-readable target before the future Flutter confirmation; Delete itself sends one CAS RPC with its frozen revision. No broad `RoutineRepository` interface mutation or direct table DELETE.

Delete RPC success boolean `true` is confirmed. Definite SQL/Auth/CAS failures are typed failures (not masked by auth changes). Transport/timeout/5xx/malformed success may have committed: do **not** retry a write; re-read by Routine UUID under the same owner to distinguish a still-existing or moved Routine from absence. Read failures or account/login-cycle changes remain unconfirmed. An absent row after uncertainty is only authoritative absence, **not** evidence this exact request caused it. Never reveal raw Postgres diagnostics.

### In scope

1. New narrow Workout domain Delete contract and Supabase adapter/gateway with dependency-injected current user ID **and** login-cycle marker for exact session binding; no fallback to an in-memory implementation.
2. Owner-filtered lightweight Routine snapshot read (name, Program, revision), used for explicit target preparation and unknown-outcome reconciliation; distinguish wrong Program/move.
3. Tests for exact RPC parameters, cancel/preparation no write, definite typed rejections, cross-account and same-owner relogin, concurrent requests/unknown outcomes, 2xx malformed, read failure and no automatic retries. Add narrower tests where justified.

### Explicit non-goals

- No Delete row activation in Program Detail or expanded Library; no confirmation UI, navigation, app-shell provider, or success toast. Those are **Slice B**, independently gated.
- No Program Delete #567, Routine Move #569, media/Play, RLS/DDL/grant changes, account deletion, AI, or future `services/api`.
- No automatic rebase/retry or destructive test against live data.

## Review gates / next steps

- [ ] Focused Flutter/Dart analysis and adapter tests at exact PR HEAD (GitHub CI).
- [ ] Independent code/security review of owner and auth-cycle switch, SQL error classification and outcome reconciliation.
- [ ] Source/no-secret diff audit; PR remains Draft before explicit future merge gate.
- [ ] After Slice A reviewed/merged, separately approve/implement Slice B confirmation and app wiring; emulator/physical QA before enabling Delete.

**Handoff:** Work in progress. Do not represent backend deployment evidence as Flutter client completion or mark GitHub #526 / Linear TNYX-81 Done.
