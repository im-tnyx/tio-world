# GitHub #568 — first-Routine activation security / release preflight (review-only)

**Status:** In progress — review/merge gate only; first-Routine production release remains OFF.
**Primary owner:** #568 / Linear TNYX-78; documentation preflight implementation owner is this GitHub-connected session (`im-tnyx`). Independent review owner: requested separately.
**Affected platforms:** Flutter Android/iOS and Supabase are audited; only this `.ai/tasks` brief and its task-index entry change.

## Owner Approval and Scope Boundary

**Trigger:** None beyond an implementation/security-readiness subtask of already owner-approved GitHub #568.
**Approval evidence:** 2026-10-21 owner instruction: start `#568` first-Routine activation preflight and proceed to merge gate. This does not authorize merging, granting RPC EXECUTE, activating a feature flag, deploying, or mutating hosted data.
**In scope:** Reconcile source/trackers/hosted SQL, document least-privilege grant and rollback prerequisites, negative/security and real-device acceptance matrix, open a docs-only PR and request independent review. **Out of scope:** SQL migration, schema/table/column change, Flutter source/UI, Supabase permission/grant change, database writes, product release, Move #569, real Undo, service/API scaffolding, or merge.

## Active Handoff

- **Planning owner:** [GitHub #568](https://github.com/im-tnyx/tio-world/issues/568) and [Linear TNYX-78](https://linear.app/tnyx/issue/TNYX-78); downstream [#569](https://github.com/im-tnyx/tio-world/issues/569) / TNYX-81 remain separately gated.
- **Implementation owner:** `im-tnyx` GitHub-connected session, this docs-only preflight; **review owner:** independent `im-tio` requested at PR gate. No Flutter or Supabase implementation ownership transfer.
- **Repository baseline (read via GitHub API 2026-10-21):** protected `main@c18ca760b22bc7ac0a6423eff40bed9457216e4a` after merged PR #646. Branch: `tnyx/issue-568-first-routine-activation-preflight-20261021`. Windows `G:\\projects\\Tio-World` checkout/dirty state was **not** inspected or modified by this connector.
- **Trackers:** #568 OPEN; TNYX-78 In Progress; TNYX-81 Backlog blocked by TNYX-78/TNYX-80. GitHub #568's original planning-era last paragraph is stale as a *current source status*: merged #620/#637/#638/#639/#642/#644/#645/#646 and deployed W1 migration supersede it. Preserve the original approved product contract.
- **Current blocker:** independently approved release-specific permission boundary/rollback, current-head validation and Android/iOS real-write QA are absent. The preflight PR itself cannot clear those release gates.
- **Next exact action:** PR-head scope/attribution/review + owner Windows native `git diff --check` receipt for this documentation change; independently review a **new, separately scoped** minimal-grant security/rollback implementation before any actual activation.

## 1. Discovery and executable source

- Root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, PR/push templates, README/architecture/ownership/roadmap, ADR-0015, `docs/screens/routine-library.md`, `docs/data/SUPABASE_SCHEMA.md` and current #568/#569/W1/W4 trackers were reconciled. Source, not old handoff prose, is runtime truth.
- `apps/app/lib/app/composition/workout_providers.dart`: `myProgramRoutineCreateReleaseEnabledProvider = Provider<bool>((ref) => false)` on `main`. `routineMoveReleaseEnabledProvider` also remains `false`.
- `apps/app/lib/app/routing/shell/shell_route.dart` wires a release-gated direct Library Create entry to Workout-owned composer/repositories. `apps/features/workout/lib/src/presentation/library/routines/create_routine_page.dart`, `routine_create_controller.dart`, `routine_pending_create_gate.dart`, `apps/features/workout/lib/src/data/repositories/supabase_my_program_routine_create_repository.dart` implement guarded owner/login-cycle Create, pending preservation, positive UNKNOWN readback, a single atomic RPC call, no blind retry and no separate Program INSERT.
- `supabase/migrations/20261019162535_w1_my_program_atomic_default_create.sql` installs `is_default boolean not null default false`, `idx_user_workout_programs_owner_default`, and protected `create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)`. Transaction locks owner account, resolves or lazily creates one default, invokes the canonical Routine composition writer; failed transaction rolls back its new Program. Migration deliberately revokes client EXECUTE. Prior source regression matrix: `supabase/tests/database/tnyx_568_w1_my_program_atomic_default_create.test.sql` and `..._concurrency.sh` run only in disposable CI.
- **Live read-only Supabase (2026-10-21):** linked Tio-world project `oykupyiitspujzpwwvuj`, 66 applied migrations ending `20261019162535`, Program and Routine RLS enabled. Exact RPC `public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)` is `SECURITY DEFINER`, owned by `postgres`, `search_path=''`; ACL grants EXECUTE only to `postgres`, **not** `PUBLIC`, `anon`, `authenticated` or `service_role`. Both #569 Move RPCs remain similarly dormant. `create_user_workout_routine_with_composition` is separately executable by authenticated users: do not revoke unrelated approved Program-scoped Create. Existing owner-only column-level Program INSERT compatibility remains a separate contract.
- Previous PR #620 database CI and #645 exact-head Flutter CI 5/5 SUCCESS are **historical source validation**. They are not fresh preflight-PR CI, live mutation proof, native Android/iOS QA or authorization to release.

## 2. Exact proposed activation boundary (future, NOT applied)

- **Required independent security decision:** after reviewing SECDEF implementation, protected composition callee, auth admission, owner-row lock, RLS, SQLSTATE mapping, quotas, two-device concurrency, revision/idempotency and account deletion, produce a **separate** tested, additive, exact-signature `GRANT EXECUTE ON FUNCTION public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb) TO authenticated` migration, if that remains the approved minimal contract. `anon`, `PUBLIC`, `service_role` and both Move RPCs remain denied; never grant direct Program default-marker INSERT/UPDATE or Routine `UPDATE(program_id)`. **No grant migration has been created by this preflight.**
- **Required rollback review before grant:** define exact incident response and rehearse revoking that one RPC's authenticated EXECUTE (without dropping it, editing an applied migration, dropping columns or changing the approved Program-scoped composition writer). Keep the Flutter release flag OFF until server-side checks pass; after any future enabling, verify server-side revoke plus separately controlled client rollback behavior, including a safe existing-user error state. A hard-coded build-time flag alone is not a proven instant mobile kill switch.
- **Host environment:** Do not invoke protected RPC with user rows in this preflight, issue `db push`, change RLS/grants, or expose another service-role path. This documentation PR is not the release/grant PR.

## 3. Activation validation matrix (all OPEN unless historical evidence stated)

| Gate | Minimum acceptance evidence | Status |
|---|---|---|
| Schema/ACL baseline | 66/66 ledger, default marker + unique partial index, RLS, exact function owner/search_path/ACL | READ-ONLY VERIFIED 2026-10-21 |
| Server negative security | User A/B isolation, signed-out/anonymous rejection, forged default mutation, legacy column-grant, malformed/empty Exercise+Set, archive and quota behavior, invalid UUID, account deletion, RPC replay | Existing disposable tests inspected; new grant-context coverage/review still REQUIRED |
| Atomicity/concurrency | One My Program per owner across two devices; failed save leaves no empty default; duplicate mutation replay; retry following timeout UNKNOWN without blind redispatch | Historical source tests present; live authorized fixture and activation-head results NOT RUN |
| Flutter UX/auth | Empty Library first Create, cancel leaves zero default, Save shows exactly one real default + saved Routine, later Create reuses renamed default, stale login cycle denies disclosure or write, pending/UNKNOWN cross-navigation readback | Merged dormant source + focused tests inspected; activation-head CI/device QA NOT RUN |
| Legacy compatibility | Old Program Create/Rename and existing Program-scoped Routine Create/Update/Delete remain unaffected; default cannot be deleted and Move #569 remains OFF | Needs independent release security/compatibility review |
| Deployment/rollback | Current-head Database CI, Flutter CI on applicable changed files, independent approval, guarded one-migration deploy plan + rollback drill, Android + iOS real-write QA with safe test identities, owner activation approval | NOT SATISFIED |
| This docs-only PR | Exact-base/head commit/file compare and no whitespace errors, applicable attribution checks, independent diff review, owner native `git diff --check`, owner-controlled merge instruction | PENDING; no runtime checks triggered by docs-only `.ai/tasks/**` paths |

## 4. Release GO / NO-GO

**Production GO = NO.** Do not change `myProgramRoutineCreateReleaseEnabledProvider`, grant EXECUTE, deploy a SQL migration or close #568 until all security, rollback, current-head CI, native Android/iOS actual-write and approval gates are met. This preflight is safe to merge **as documentation only** after its *own* independent review and applicable branch checks; such a merge does not imply permission activation.

## 5. Quality review, handoff, and provenance

- **Performed:** GitHub API read-only current main, source/trackers and prior checks; connected Supabase migration/ACL/RLS read-only inspection; documentation scope review. No local Windows commands, Flutter tests, disposable SQL tests or live writes executed in this session.
- **Preflight PR review:** pending exact-head GitHub checks, independent `im-tio` review and owner-native diff evidence. No self-review or chat-only assessment may be presented as GitHub `APPROVED`.
- **Repository required check caveat:** ruleset list returned empty but branch-protection API responded 403 to this connector; required-vs-supplemental classification is **unverified** here. Do not claim a missing/incomplete check is non-required without authoritative live evidence. Inspect PR merge/check gate independently.
- **Final handoff decision:** `REVIEW` for a docs-only preflight PR once opened, and `BLOCKED/NO-GO` for production activation until the separate security and QA acceptance is complete.
