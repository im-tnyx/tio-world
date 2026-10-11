# GitHub #509 — Program-owned Routine composition persistence

**Status:** In progress — database foundation deployed and hosted-verified; client adapter pending
**Primary owner:** Workout persistence (`supabase/`, `apps/features/workout`)
**Affected platforms:** Flutter data/domain boundary and Supabase schema/RLS/RPC; no visible UI

## Owner Approval and Scope Boundary

**Trigger:** Bounded persistence slice + Supabase table/column shape change
**Approval status:** Exact physical contract approved in GitHub #509 on 2026-10-10; exact production deployment separately approved on 2026-10-11.
**Approval evidence:** Original owner response `go with follow agent.md`; subsequent `GO APPLY MIGRATION` names only `20261010061809_create_user_workout_routine_composition.sql`, project `oykupyiitspujzpwwvuj`, merged PR #511 and expected `main@f974559084bbf47472e91b2a6c424f6d663a4e3c`.
**Approved boundaries:** Two Routine composition columns, owner-safe unique key, two relational child tables, owner RLS/read-only child Data API, narrow authenticated atomic save RPC, SQL security/concurrency tests; exact deployment, read-only production verification, tracker updates and bounded documentation PR.
**Explicit non-changes:** No other migration, production user-data writes, schema redesign, application release, Flutter composition adapter, builder/Program detail UI, default My Program identity, Favorites/Folders, TrainingPlan/WorkoutSession, source/adoption, media/Storage or new service/API. No source-branch deletion or documentation PR merge authorized.

## Active Handoff

**Planning owner:** Current repository agent
**Implementation owner:** Current repository agent — deployment verification/documentation only
**Review owner:** Independent read-only review; documentation PR review and exact-head required CI
**Implementation ownership state:** Active for this bounded handoff; prior source implementation is merged. Ownership reconstructed from #511, current trackers, local Git and live catalogs before takeover; no competing implementation owner observed.
**Repository state last verified:** Clean local `main` and `origin/main` at `f974559084bbf47472e91b2a6c424f6d663a4e3c` on 2026-10-11 after fetch and `git pull --ff-only origin main`.
**Branch:** `tnyx/routine-composition-deployment-evidence` from that verified main; refresh HEAD/checks before each push.
**HEAD SHA:** `f974559084bbf47472e91b2a6c424f6d663a4e3c` before the documentation commit; the PR records the resulting documentation HEAD rather than a self-referential SHA here.
**Observed uncommitted/dirty files:** None before this documentation slice; only the five owned documentation files below are intended.
**PR / tracker:** [GitHub #509](https://github.com/im-tnyx/tio-world/issues/509); [merged #511](https://github.com/im-tnyx/tio-world/pull/511); Linear TNYX-78 In Progress; TNYX-81 remains blocked by TNYX-78 and TNYX-80.
**Current implementation state:** Production database foundation applied and independently verified. Flutter composition adapter/provider/controller and visible builder remain unimplemented.
**Relevant execution surface:** Existing `supabase/migrations` and database tests; this change edits only `.ai/tasks/` and canonical `docs/`.
**Validation completed at SHA:** Reviewed source head `142e01608ca5635b73049ee1bbeeaacf91372a7d` has passing Supabase Database CI `38034796318` and clean Codex review `6095180973`. The merged main has identical `supabase/` and database-CI source. Hosted verification below ran against production on 2026-10-11.
**Documentation validation:** Five-file diff/scope audit and `git diff --check` PASS; independent read-only review CLEAN with no actionable findings. No `supabase/`, `apps/` or workflow changes.
**Validation remaining:** New documentation PR exact-head required CI and review/merge. Broader W1 client acceptance remains incomplete.
**Current blocker:** No deployment blocker. Default My Program and remaining W1/W3 dependencies still gate TNYX-81; this deployment does not clear them.
**Open review finding IDs:** All three original #511 Codex P2 threads resolved; final source review clean. No unresolved deployment finding.
**Next exact action:** Review/merge the bounded documentation PR through required gates, then separately authorize the feature-owned composition adapter slice. Do not start adapter or UI from this deployment handoff.

## 1. Discovery

Durably store ordered Routine Exercise references and prescribed sets inside exactly one user-owned Program/Routine, preserving metadata behavior and ownership isolation. This deployment closes only the approved database foundation gate, not broader W1 or builder acceptance.

## 2. Codebase Exploration

- `RoutineComposition`, `RoutineExercise`, `SetPrescription` and `ExerciseRef` are immutable `apps/shared` contracts.
- `RoutineRepository` / `SupabaseRoutineRepository` remain metadata-only `list/create/rename`; no composition adapter is claimed.
- PR #511 merged the reviewed migration and transactional authorization/revision/idempotency/350-Set matrix plus actual two-session Routine race test.
- Original six Routine columns and Program owner FK are preserved. Live Routine now has eight columns; Custom Exercise retains twelve and unique `(id, user_id)`.

## 3. Clarification

| Decision | Status | Owner |
|---|---|---|
| Two ordered relational child tables with stable UUID identities | Approved and deployed | Owner via #509 |
| RPC transaction instead of direct child writes | Approved and deployed | Owner via #509 |
| Exact one-migration production apply | Authorized and verified | Owner on 2026-10-11 |
| Client adapter, default My Program, builder and session execution | Separate gates; not part of deployment | Owner |

## 4. Architecture Design

Future feature repository calls the owner-checked atomic save RPC and owner-scoped reads. The RPC uses an owner Routine lock, revision comparison and mutation-token/payload equality for safe retries. Children retain stable UUIDs and ordered positions; composite FKs enforce Routine/Custom Exercise ownership. No architecture redesign was made during deployment.

## 5. Implementation Plan

- [x] Approved migration/RPC and SQL security/concurrency tests merged in #511.
- [x] Exact source-head CI and Codex review verified; merged source parity confirmed.
- [x] Fresh main/link/ledger/schema/dependency preflight and CLI dry-run passed.
- [x] Exact migration applied once; independent hosted schema/security/ledger verification passed.
- [ ] Documentation PR review/CI and merge.
- [ ] Separately scoped feature-owned composition adapter with Dart mapping/retry tests.
- [ ] Remaining W1 acceptance; TNYX-81 dependency reconciliation before builder work.

## 6. Quality Review

### Deployment and Hosted Evidence — 2026-10-11

- Linked Supabase CLI `2.116.0` targeted `oykupyiitspujzpwwvuj`. Repository had 55 migrations; production had 54. Version/name comparison and `db push --dry-run --linked --skip-vault` identified only `20261010061809_create_user_workout_routine_composition.sql`; no seeds/roles or competing DDL were observed.
- `db push --linked --skip-vault` exited **0**, listed only that migration and returned `Finished supabase db push.` No interactive prompt appeared. No retry, repair, reset, force, manual ledger edit or MCP migration apply was used.
- Independent read-only live ledger is **55 / 55**, exact version/name match, no repository-only/live-only entries. CLI `migration list --linked` agrees; post-apply dry-run exits 0 with `upToDate: true` and `migrations: []`.
- Catalogs verify Routine's two added columns, both child tables, UUID identities, checks, unique ordering, owner-safe FKs and all supporting indexes valid/ready. All 19 public tables have RLS enabled. All inspected constraints are validated.
- Effective table/column privileges and policies verify child owner-only authenticated SELECT, no direct child writes, original six-column Routine INSERT and name-only UPDATE. Revision/token INSERT/UPDATE are denied. No anon/PUBLIC table or column grants were introduced.
- Exactly one `public.save_user_workout_routine_composition(uuid, bigint, uuid, jsonb)` returns bigint; owner postgres, SECURITY DEFINER, empty `search_path`. EXECUTE is limited to postgres/authenticated; anon/PUBLIC have none. Hosted function body equals reviewed migration source after line-ending normalization, including `auth.uid()` ownership, lock, atomic revision and idempotency checks.
- Existing Program/Routine/Custom Exercise aggregate counts and content digests compare unchanged before/after. No user rows or digests are recorded here. No production behavioral writes were run; write/race behavior evidence is the existing disposable CI matrix.

### Advisor Dispositions

| Advisor | Before | After | Disposition |
|---|---|---|---|
| Authenticated SECURITY DEFINER WARN | 5 | 6 | One added warning for the approved save RPC. Investigated owner authorization, exact source parity, safe search path and restricted EXECUTE; intentional reviewed boundary retained. |
| Leaked-password-protection WARN | 1 | 1 | Existing setting warning unchanged; no Auth configuration change authorized. |
| Unindexed FK INFO | 1 | 1 | Existing Routine-to-Program FK notice unchanged. |
| Auth RLS initplan WARN | 18 | 18 | Existing notices unchanged. |
| Unused index INFO | 13 | 14 | Added partial Custom Exercise FK index is currently unused; required supporting index retained. No tuning change authorized. |

No new actionable operational/security defect was identified. Expected new notices have separate dispositions above; no policy or index was weakened to silence them.

### Security Check Requiredness

Current main protection requires **Commit attribution guard**; effective rulesets returned no additional requirements. Required guard passed on reviewed source. GitHub Advanced Security is **supplemental + infrastructure failure**: HTTP 402 monthly external-model quota before meaningful analysis, tracked by TNYX-256. This is neither a security pass nor a product vulnerability. New documentation PR must satisfy its current required checks independently.

## 7. Final Handoff

### Changed Files — This Documentation Slice Only

- `.ai/tasks/issue-509-routine-composition-persistence.md` — deployment evidence, ownership and next gate.
- `.ai/tasks/README.md` — current task deployment boundary.
- `docs/data/SUPABASE_SCHEMA.md` — verified 55-migration/19-table inventory, columns, constraints, indexes and RPC access.
- `docs/data/SUPABASE_STRATEGY.md` — current deployed foundation and client integration boundary.
- `docs/screens/routine-library.md` — planned UI distinguished from deployed database composition.

### Actual Behavior and Limits

Production database migration is **APPLIED**, hosted verification **PASS**. No application release, client adapter or visible builder shipped. No executable SQL or migration file changes in this documentation slice. Existing merged source branch retained.

### Final Status

`PARTIAL` — database deployment complete; documentation review/merge and broader W1/client acceptance remain separate gates. Keep TNYX-78 In Progress and TNYX-81 blocked.
