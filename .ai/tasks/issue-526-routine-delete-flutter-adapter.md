# GitHub #526 — Flutter Routine Delete RPC adapter (Slice A)

**Status:** In Review — 2026-10-17 `im-tio` formal CHANGES_REQUESTED on two P2 lifecycle findings (instance recreation + failed/negative inspect leaving target armed). Targeted shared-gate/data-only corrections and focused regressions committed; new exact-head CI and independent approval remain pending. Previous head `9bc7b5d1` had 7/7 checks PASS.
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

Delete RPC success boolean `true` is confirmed. Definite SQL/Auth/CAS failures are typed failures (not masked by auth changes). Transport/timeout/5xx/malformed success may have committed: do **not** retry a write; re-read by Routine UUID under the same owner to distinguish a still-existing or moved Routine from absence. Read failures or account/login-cycle changes remain unconfirmed. A successful owner read at the SAME (or older) revision cannot clear an unresolved timed-out Delete, since the underlying server request can still commit later. The unresolved guard is keyed to owner+Routine across login cycles (while target authorization remains login-cycle-scoped). It is released only when a current-owner read proves a strictly NEWER composition revision (old revision-CAS can no longer succeed). Each inspected Delete target is a single-use capability consumed before the first dispatched RPC, including after a definitive rejection; a new confirmation requires a new inspect even when the revision is unchanged. An absent row after uncertainty is only an observation of owner-filtered Data API invisibility (which can also reflect RLS or a still-in-flight RPC); it is **always an unknown outcome**, never a confirmed Delete. The future UI must refresh its owner-scoped list while communicating the uncertainty. Never reveal raw Postgres diagnostics.

### In scope

1. New narrow Workout domain Delete contract and Supabase adapter/gateway with dependency-injected current user ID **and** login-cycle marker for exact session binding; no fallback to an in-memory implementation.
2. Owner-filtered lightweight Routine snapshot read (name, Program, revision), used for explicit target preparation and unknown-outcome reconciliation; distinguish wrong Program/move.
3. Tests for exact RPC parameters, cancel/preparation no write, definite typed rejections, cross-account and same-owner relogin, concurrent requests/unknown outcomes, 2xx malformed, read failure and no automatic retries. Add narrower tests where justified.


- A further manual P2 finding exposed an inspection race: an owner read started before an RPC could return a stale header after successful Delete, or inspection could begin while a Delete was in-flight. The repository now checks owner+Routine in-flight before and after read and verifies no RPC dispatch generation changed during the read. A Completer regression asserts an overlapped read cannot mint a new Delete target; this change also awaits exact-head CI.

- PR reviewer `im-tio` requires the unresolved-RPC safety guard to survive repository recreation. Slice A now exposes a REQUIRED caller-owned `RoutineDeleteAttemptGate` injectable into `SupabaseRoutineDeleteRepository` and `fromClient()`; it carries owner/Routine unresolved revision, in-flight and inspection/dispatch generation state across instances. No implicit gate fallback may be created inside the repository. Future Slice B app composition MUST retain one gate across route/provider/re-login recreation and both UI surfaces. This is an **in-process lifecycle guarantee only**; OS process restart clears in-memory state and no stronger durability claim is made without a separately approved persistent operation contract.
- Every `inspect()` invalidates a prior one-use target at its start, including absent/wrong-Program/read failure; a generation check prevents a slow earlier inspection from rearming an older target after a newer inspection. Tests now cover adapter recreation following an unresolved Delete and negative/moved reinspection, as well as RPC overlap.

### Explicit non-goals

- No Delete row activation in Program Detail or expanded Library; no confirmation UI, navigation, app-shell provider, or success toast. Those are **Slice B**, independently gated.
- No Program Delete #567, Routine Move #569, media/Play, RLS/DDL/grant changes, account deletion, AI, or future `services/api`.
- No automatic rebase/retry or destructive test against live data.

## Review gates / next steps

- [x] Source-head `9840aca6` Flutter CI run `39003322361` all 7 checks PASS, including full app-workout shard (new adapter tests), Analyze/Dart, core-wear, nutrition-onboarding, aggregate and attribution. Initial source head `e534de94` exposed 3 numeric SQLSTATE-vs-HTTP status regressions; fixed on `bf9288bb`. Later pure handoff commit requires its own exact-head recheck.
- [ ] Independent code/security review of owner and auth-cycle switch, SQL error classification and outcome reconciliation. The 2026-10-17 manual implementation-owner COMMENTED review (ID `5556312364`) opened two active threads: unresolved-write reinspection/guard lifecycle and SQLSTATE rollback classification. Original two findings were corrected and all 7 checks passed at `ef632b3b`. A second manual review at that head identified two more active P2 findings: cross-login-cycle unknown guard and frozen-target replay after definite rejection. New corrections/tests are on this branch; exact-head CI and review disposition pending.
- [x] Source/no-secret diff scope audited: 7 paths in Workout domain/data/tests and `.ai` task/index, no app shell, UI, RLS or migration change. PR #586 is Ready for independent review but still unmerged.
- [ ] After Slice A reviewed/merged, separately approve/implement Slice B confirmation and app wiring; emulator/physical QA before enabling Delete.

**Handoff:** Earlier data-only implementation passed 7/7 at `578f66c5`, but reviewer findings required corrections; new code adds delayed-ACK/same-revision guard tests and SDK `23502`/`40P01`/`40001` decoding. Independent reviewer `im-tio` still requested; await fresh exact-head CI and review disposition and explicit owner `Go merge`. There is no Flutter Delete UI and no local Windows/device validation claim. Do not mark GitHub #526 or Linear TNYX-81 Done.
