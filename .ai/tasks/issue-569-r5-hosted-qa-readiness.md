# GitHub #569 R5 — Hosted Move authorization QA readiness and current-gate reconciliation

**Status:** In progress — documentation/readiness PR; hosted HTTP QA NOT performed
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
- [ ] PR change scope and parent ancestry audited using GitHub compare.
- [ ] Docs Hygiene and required commit attribution on exact PR HEAD verified; connector-only work cannot claim local `git diff --check` execution.
- [ ] Manual reviewer findings dispositioned; actual independent human security review deferred per #675, **not** treated as APPROVED.
- [ ] Separate authorized hosted HTTP/JWT negative matrix completed (NOT part of this docs-only PR).
- [ ] Device release-candidate Android/iOS and owner UI/public-release sign-off (NOT part of this PR).

## Active handoff

**Planning / implementation:** Connected assistant, docs-only owner of this slice; no concurrent feature implementation claimed.
**Implementation state:** Preparing one bounded PR against main. No local Windows worktree is mounted in this environment; GitHub API parent/ref/file audit is the available substitute.
**Validation:** Supabase read-only migration/ACL/advisor evidence above; local Flutter and hosted HTTP JWT tests **not run**. PR checks to be read at exact HEAD after creation.
**Next:** Open and audit documentation PR through merge gate, leave UNMERGED. Follow-on actual HTTP/device QA requires controlled accounts/consent and separate evidence and go/no-go.
