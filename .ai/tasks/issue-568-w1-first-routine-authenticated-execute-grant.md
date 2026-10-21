# GitHub #568 / TNYX-78 — W1 first-Routine authenticated EXECUTE grant (source-only)

**Status:** In Progress — source PR merge gate only; hosted activation NOT AUTHORIZED.
**Primary owner:** W1 Supabase/Postgres. Implementation owner: this GitHub-connected `im-tnyx` session for this exact repository branch. Review owner: independent `im-tio` + current CI gate.
**Affected platforms:** Supabase database and CI tests only; no Flutter/Wear/watchOS presentation or app-shell change.

## Owner Approval and Scope Boundary

**Trigger:** None. This is the next *internal RPC/RLS/security engineering subtask* under owner-approved GitHub #568 and merged [PR #647 preflight](https://github.com/im-tnyx/tio-world/pull/647); no new product-visible UI/UX or table/column shape.
**Owner instruction:** 2026-10-21, `अगला चरण: merge gate tak le kar jaye follow agent.md`, following post-merge local sync PASS for #647. Allows preparing/reviewing a bounded source PR, **not** merging, hosted `GRANT EXECUTE` deployment, production Flutter activation, physical-device QA or broader #569 Move/Undo.
**Scope:** One additive exact-signature migration granting only `authenticated` EXECUTE on already-deployed first-Routine SECDEF RPC, its rollback runbook and disposable SQL/CI regression adapted to that new ACL.
**Non-goals:** No table/column, RLS policy or RPC body change; no direct user tables `INSERT(is_default)`/`UPDATE` or `UPDATE(program_id)`; no change to existing Program-scoped Create or Move RPC permissions; no user data writes on hosted, no `db push`, no new backend service, no Flutter/UI/flag change, no merge or branch deletion.

## Active Handoff

- **Planning owner:** [GitHub #568](https://github.com/im-tnyx/tio-world/issues/568), [TNYX-78](https://linear.app/tnyx/issue/TNYX-78); related #569/TNYX-81 remains separately gated.
- **Parent:** protected `main@01d5287031528f38963819c71069694c779e0bd8` after merged PR #647, owner Windows post-merge fast-forward receipt verified (not run by this connector).
- **Branch:** `tnyx/issue-568-first-routine-minimal-execute-grant-20261021`. Source ownership limited to `supabase/migrations`, relevant `supabase/tests/database`, `.github/workflows/supabase-db-ci.yml`, and this handoff/index. No local `G:\projects\Tio-World` checkout touched.
- **Pre-change hosted baseline (read-only on 2026-10-21):** 66 migrations applied through `20261019162535`; `public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)` is `SECURITY DEFINER`, owned by `postgres`, empty search_path, `proacl={postgres=X/postgres}`; `authenticated`, `anon`, `service_role` EXECUTE **false**. W1 Program/Routine RLS enabled. No data mutation executed. [Security Advisor](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable) has existing authenticated-SECDEF warnings for other reviewed APIs; enabling this one later will need deliberate advisor differential/justification, **not** automatic lint clearance.
- **Current source:** `apps/app/lib/app/composition/workout_providers.dart` first-Routine release and Move release both hard OFF; Flutter adapter/owner-cycle UNKNOWN safeguards already merged. W4/TNYX-81 Backlog blocked by W1/W3. Legacy #568 GitHub description's planning-only paragraph is historical; deployed W1 SQL and merged Flutter source are now actual state.
- **Next exact gate:** GitHub PR exact HEAD database CI on disposable Postgres, commit attribution, owner Windows native `git diff --check`, independent `im-tio` formal review, 0 unresolved findings; owner must separately instruct merge. Hosted DB remains 66 migrations until a separate authorized deployment gate.

## 1. Discovery, security contract, and rejection of alternatives

Existing `supabase/migrations/20261019162535_w1_my_program_atomic_default_create.sql` owns server-generated `is_default`, owner-row serialization and atomic delegation to `create_user_workout_routine_with_composition`. It explicitly denies EXECUTE to Data API client roles. Runtime hosted SQL matches. The same source's original W1 SQL and concurrency tests had test-only `GRANT` and expected dormant ACL, so applying a new permanent *source* grant without repairing both tests would falsely pass or break CI. `.github/workflows/supabase-db-ci.yml` replays all migrations, all SQL matrices, and real two-session races in disposable CI.

**Chosen:** Append `supabase/migrations/20261021120000_grant_my_program_first_routine_execute.sql`. Explicit `REVOKE` from `PUBLIC`, `anon`, `service_role`, then exact four-arg `GRANT EXECUTE ... TO authenticated`; preserve SECDEF owner, `search_path=''`, body, RLS and other grants. Update RPC comment to accurately state grant + separate client hold. Explicitly *do not* change Flutter provider from false. SQL is inactive until an independently authorized hosted deploy.

**Rejected:** Modify an already-applied 20261019 migration; blanket grant to PUBLIC; client-side default Program INSERT, duplicating/rewriting atomic function body, privilege extension to both #569 Move RPCs, or a second forward "rollback" migration that inadvertently disables the grant during normal replay.

**Risk:** PostgREST `authenticated` permission could become available via direct HTTP RPC immediately after later deployment even while Flutter flag is OFF. This is a real privilege expansion; server-side Auth/owner checks and authorized deployment timing/QA are mandatory. A false Flutter flag is **not** a server-side kill switch. Supabase signed-in role alone is not user-ownership authorization; `auth.uid()`, live account row, owner-only Program relation, and canonical writer are the necessary trusted boundary. Anonymous Supabase Auth users may carry the `authenticated` Postgres role: account-admission expectations must be reviewed separately before hosted deployment, not hand-waved.

## 2. Source changes / acceptance

| File | Expected behavior | Disposable CI evidence |
|---|---|---|
| `supabase/migrations/20261021120000_grant_my_program_first_routine_execute.sql` | Only exact first-Routine RPC authenticated grant, no schema/other grants | Fresh full replay + ledger |
| `supabase/tests/database/tnyx_568_first_routine_execute_grant.test.sql` | Verify SECDEF/search_path/ACL, anon/service denial and JWT-less 28000, exact `REVOKE` rollback and isolation from existing Program/Create privileges | New transaction-only SQL matrix |
| `supabase/tests/database/tnyx_568_w1_my_program_atomic_default_create.test.sql` | Existing composition, duplicate idempotency, cross-owner RLS, default identity/rollback tests use the **migration grant** instead of temporary grant | Existing W1 SQL matrix |
| `.github/workflows/supabase-db-ci.yml` | Run new ACL/rollback before W1 tests; W1 concurrent race no temporary grant/revoke; assert migration ACL before and after | Database CI workflow |
| Task handoff/index | Make explicit hosted rollout and security/go/no-go ownership | Documentation review |

## 3. Deployment/rollback gate (not performed in this source PR)

1. Require owner-approved deployment window after exact-head Database CI, independent security review and legacy/owner isolation review; verify fresh hosted migration ledger has the 66 expected versions, exact SECDEF owner/search_path/ACL, and no conflicting pending migrations. **Stop on drift**; never replay applied W1 migration. Independently approve the *specific* deployment after this source merge.
2. Apply **only** the audited, approved new `20261021120000` migration via canonical Supabase CLI migration workflow. No user data writes or migrations through ChatGPT in this source PR. Before/after re-query `pg_proc`, EXECUTE for authenticated/anon/service/PUBLIC, RLS, `is_default` column grants, two Move RPCs and counts. Newly executable SECDEF Advisor warning requires review/acceptance with verified ownership, not suppression.
3. Emergency permission-only rollback, after coordinated incident decision, executes exactly:
   ```sql
   REVOKE EXECUTE ON FUNCTION public.create_user_workout_routine_in_my_program(
     uuid, text, uuid, jsonb
   ) FROM authenticated;
   ```
   Then verify authenticated/anon/service roles cannot execute, and original Program-scoped Create still can; do not drop function/column/records or modify applied migration. **CLI migration ledger remains applied after emergency REVOKE**. Subsequent forward remediation must use a new reviewed migration and reconcile actual ACL; never mark history arbitrarily un-applied. Existing Flutter flag OFF before/after. Device-side support remains required for eventual activation/kill-switch behavior.
4. Even after a granted hosted RPC, **release GO remains NO** until separate actual-write Android/iOS QA, two-device race/replay, UNKNOWN/owner switch, legacy compatibility, guarded user test fixtures and owner UI/activation approval. No exposed QA credential or service-role client.

## 4. Quality Review and Final Handoff

- **Actually observed:** GitHub API source and CI/test workflow; Linear TNYX-78/TNYX-81; connected Supabase 66/66, SECDEF and ACL metadata; Security Advisor read-only. No local PostgreSQL, Supabase CLI or Flutter execution from this connected GitHub session.
- **Required:** GitHub exact-head Supabase Database CI (full replay + migration ledger, W1 SQL tests and concurrency), commit attribution guard, inspect security/scanner findings separately from check requiredness, owner native diff-check, independent security/code review, branch gate and owner merge instruction. Prior PR #620/#647 pass receipts **do not** cover this changed SQL head.
- **Not applicable here:** Flutter CI and native Android/iOS QA cannot validate a SQL-only review slice; they remain **production release gates**, not claimed as done. After source merge 67 repository migrations vs 66 hosted is an **expected pending deployment**, not a 67/67 deployment receipt. Update canonical schema strategy/inventory upon separately approved hosted deployment.
- **Current classification:** `REVIEW` when PR is open and required checks pending, `BLOCKED` if required CI fails or cannot be run; **production feature NO-GO regardless of PR merge**. Do not self-approve or auto-merge.
