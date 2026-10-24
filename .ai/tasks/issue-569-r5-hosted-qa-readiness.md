# GitHub #569 R5 — Hosted Move authorization QA readiness and current-gate reconciliation

**Status:** In review — [PR #677](https://github.com/im-tnyx/tio-world/pull/677) at merge gate; hosted HTTP QA NOT performed, DO NOT MERGE
**Owner:** Workout release QA / developer experience (documentation only)
**Tracking:** [#569](https://github.com/im-tnyx/tio-world/issues/569), [TNYX-81](https://linear.app/tnyx/issue/TNYX-81/w4-programs-and-routines-canonical-content-composition-and-builders), [#675](https://github.com/im-tnyx/tio-world/issues/675)
**Base:** protected `main@74f3ebd42a0a388eb817d86de75a1db8b518f335` (R4 PR #676 merged)

## Approval and scope

**Trigger:** Existing owner-approved #569 release QA and authorization verification follow-up. Owner directed the next bounded slice through PR merge gate, explicitly **not merge**.
**Owner Approval:** Existing scope continuation, no new product-visible task, UI/UX change or table/column shape change.
**In scope:** Record current hosted grant exposure with read-only evidence; add a safe, executable-by-authorized-testers hosted HTTP/JWT negative-path QA matrix and evidence/stop rules to the existing Move development runbook; reconcile the active task pointer.
**Out of scope:** No hosted mutation/HTTP test execution using user accounts in this PR, no test-account creation, no auth token retrieval/storage, no Flutter, migration, grant, RLS, CI, deployment, visual or public-activation change; no #567 general Delete Program implementation. No comprehensive #250 schema/strategy documentation takeover.

## Discovery / current truth (2026-10-24)

- GitHub protected main: R4 PR #676 squash merged at `74f3ebd4`; `apps/app/lib/app/composition/workout_providers.dart` exposes `TIO_MOVE_ROUTINE_RELEASE` only when explicitly build-opted-in; normal builds remain `false`. App flag is not RPC authorization or a remote kill switch.
- Connected Supabase project `oykupyiitspujzpwwvuj` is `ACTIVE_HEALTHY`, with 70 applied migrations through `20261024120000_grant_move_routine_rpc_execute_to_authenticated`.
- Live **read-only** `pg_proc` showed all exact three functions `postgres`-owned, `SECURITY DEFINER`, empty `search_path`, ACL `{postgres=X/postgres,authenticated=X/postgres}`. `authenticated=true`, `anon=false`, `service_role=false`. Catalog metadata is **not** evidence that JWT/HTTP owner or guest negatives were exercised.
- Additional hosted read-only table/column ACL verification: RLS enabled for both `public.user_workout_programs` and `public.user_workout_routines`; `authenticated` table `DELETE` denied on both, and `authenticated UPDATE(user_workout_routines.program_id)` denied. No live test mutation occurred.
- Security Advisor currently reports `authenticated_security_definer_function_executable` WARN; intended authenticated access is not a reason to suppress the warning or treat it as proven safe. See [Supabase linter](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).
- Source/CI R2/R3 tests and owner-reported earlier isolated Android 5/5 are distinct from new live hosted JWT/cross-owner API and iOS/Android release-candidate acceptance. GitHub #569 OPEN, TNYX-81/TNYX-267 broad W4 Backlog, #675 is independent human-review debt before public launch.
- `docs/development/DEVELOPMENT_SETUP.md` carries dated isolated Option A statements that describe hosted 69/denied permissions as if current; preserve historical lab instructions but explicitly distinguish current 70/authenticated ACL and require environment verification before any QA.

## Chosen approach and alternative rejected

**Chosen:** One existing developer-runbook update plus this small `.ai` handoff/index; inspect only catalog and track unexecuted HTTP matrix with token hygiene. The later authorized tester must record distinct per-case response/row-state evidence in restricted QA storage, not in public GitHub.
**Rejected:** Automatically calling production Move RPCs from the connector, generating/retrieving JWTs for real users, introducing paid staging infrastructure, changing RPC grants to "fix" QA, or pretending a SQL `has_function_privilege` read validates ownership.
**Safety:** An actual Move/Undo/Save & Move POST can commit data; only with separately authorized disposable test users/programs, scoped environment and cleanup/rollback. Abort if unexpected write or cross-owner success occurs, triage immediately.

## Acceptance / review checklist

- [x] Main, R4 source, #569/Linear state, runbook, hosted migration and three ACLs examined through connected tools.
- [x] Current hosted warning and least-privilege exposure distinguished from source-only activation.
- [x] GitHub compare showed 6 task-only commits, 0 behind, exact 3 approved docs/task paths against base `74f3ebd4` before this handoff refresh; recheck final head.
- [x] Docs Hygiene / required Commit attribution / Attribution runner SUCCESS on reviewed head `9b0cdbda` (runs `40115053244` / `40115051369`); recheck final handoff-commit HEAD CI. Connector-only work cannot claim local `git diff --check` execution.
- [x] Assistant-operated self-review on PR #677 identified one P2 Option A historical/current ACL contradiction; corrected at `9b0cdbda`, replied and resolved GitHub inline thread `PRRT_kwDOTOXwB86v6FVT`. **Not independent review**. Human security review remains deferred via #675, not APPROVED.
- [ ] Separate authorized hosted HTTP/JWT negative matrix completed (NOT part of this docs-only PR).
- [ ] Device release-candidate Android/iOS and owner UI/public-release sign-off (NOT part of this PR).

## Active handoff

**Planning / implementation:** Connected assistant, docs-only owner of this slice; no concurrent feature implementation claimed.
**Implementation state:** Draft PR #677 opened from `tnyx/569-r5-hosted-qa-readiness` against `main@74f3ebd4`, docs-only 3-path scope; reviewed P2 fixed. No local Windows worktree is mounted; GitHub API parent/ref/file audit is the available substitute.
**Validation:** Supabase read-only migration/ACL/advisor evidence above; local Flutter and hosted HTTP JWT tests **not run**. PR checks to be read at exact HEAD after creation.
**Next:** Verify final exact-head checks and review state, leave PR #677 **UNMERGED** for explicit owner instruction. Separate hosted HTTP/device QA requires controlled accounts/consent, evidence and release go/no-go.
