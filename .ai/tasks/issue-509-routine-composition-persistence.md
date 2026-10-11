# GitHub #509 — Program-owned Routine composition persistence

**Status:** In progress — database foundation deployed; Flutter composition adapter implemented and CI-reviewed; PR merge gate pending
**Primary owner:** Workout persistence (`supabase/`, `apps/features/workout`)
**Affected platforms:** Flutter data/domain boundary and Supabase schema/RLS/RPC; no visible UI

## Owner Approval and Scope Boundary

**Trigger:** Separately bounded Flutter persistence adapter slice; no database shape change.
**Approval status:** Owner explicitly granted `GO — Tio-world Routine Composition Adapter Slice` on 2026-10-11 after the architecture audit. Earlier database/deployment approvals remain historical evidence below.
**Approval evidence:** Direct owner instruction authorizes Audit → Implement → Validate → Open PR → Codex Review Gate; STOP before merge.
**Approved boundaries:** Feature-owned identified entry/set envelopes projecting existing shared models, complete owner-scoped reads with revision validation, atomic existing-RPC save, frozen mutation/revision retry and reconciliation, strict mapping/errors, focused Dart/Flutter tests, bounded documentation, one implementation PR and review.
**Explicit non-changes:** No shared canonical model redesign, provider/controller activation, UI/navigation/tokens, default My Program, Favorites/Folders, TrainingPlan/WorkoutSession/performed sets, offline queue, Supabase schema/migrations/RLS/RPC changes, production data writes, release, backend/AI/connectors, PR merge or branch deletion.

## Active Handoff

**Planning owner:** Current repository agent
**Implementation owner:** Root Codex agent; sole source/test editor for this slice.
**Review owner:** Independent read-only agents, then Codex PR review and exact-head CI.
**Implementation ownership state:** Active. Previous deployment/docs handoff reconstructed from merged #511/#512, fresh trackers, Git and live catalogs. No competing open PR or worktree observed; reviewer agents may not edit implementation.
**Repository state last verified:** Clean local `main` and `origin/main` at `3a63c0629ad824fcb423cdf0c50a8e5c63ffca41` after fresh fetch and fast-forward-only pull on 2026-10-11.
**Branch:** `tnyx/routine-composition-adapter`, created from that verified main.
**HEAD SHA:** Base `3a63c0629ad824fcb423cdf0c50a8e5c63ffca41`; adapter/P2-fix source head `f2487c4a9c7c92431b6baced109dfbb97aa5cb53` (2 ahead / 0 behind). This brief-only change advances HEAD; verify fresh exact-head checks/review before merge.
**Observed uncommitted/dirty files:** None before this slice. Owned changes only: Workout repository/data/tests/test dependency plus this brief/index and precise canonical status documentation.
**PR / tracker:** [GitHub #509](https://github.com/im-tnyx/tio-world/issues/509); [merged #511](https://github.com/im-tnyx/tio-world/pull/511); Linear TNYX-78 In Progress; TNYX-81 remains blocked by TNYX-78 and TNYX-80.
**Current implementation state:** Approved adapter and focused tests implemented and locally validated. Database foundation remains deployed; #512 documentation reconciliation is merged. Provider/controller and visible builder remain outside scope.
**Relevant execution surface:** `apps/features/workout/lib/src/{domain,data}`, focused repository tests and export barrels. No `supabase/` changes.
**Validation completed at SHA:** Reviewed source head `142e01608ca5635b73049ee1bbeeaacf91372a7d` has passing Supabase Database CI `38034796318` and clean Codex review `6095180973`. The merged main has identical `supabase/` and database-CI source. Hosted verification below ran against production on 2026-10-11.
**Fresh contract evidence:** 55 hosted migrations; current RPC body equals checked-in source, exact signature/security configuration and owner-only child SELECT verified read-only. Live user rows were not read or written. Metadata repository remains unchanged.
**Validation remaining:** This brief-only commit needs fresh exact-head required CI/Codex disposition; the separately owner-authorized merge and broader W1 acceptance remain pending.
**Current blocker:** No deployment blocker. Default My Program and remaining W1/W3 dependencies still gate TNYX-81; this deployment does not clear them.
**Open review finding IDs:** Original #511 P2 threads resolved. PR #513 Codex P2 JWT mapping finding `PRRT_kwDOTOXwB86rKk25` / comment `4240365425` (on `76d0358`) was fixed in `f2487c4` (`PGRST301/302/303` map to unauthorized), covered by SDK mock-HTTP read/save tests, replied at `4240453866` and resolved (0 unresolved threads). Independent exact-source-head COMMENT review `5482096317` found no new blockers. Codex rolling activity says `f2487c4` completed; earlier formal COMMENTED review is at `76d0358`, not exact-head APPROVED.
**Next exact action:** PR #513 is OPEN. Verify fresh exact-head CI/Codex after this brief-only commit, reconcile findings and STOP for explicit owner merge authorization.

## 1. Discovery

Durably store ordered Routine Exercise references and prescribed sets inside exactly one user-owned Program/Routine, preserving metadata behavior and ownership isolation. This approved adapter consumes the deployed database foundation; broader W1 and builder acceptance remain pending.

## 2. Codebase Exploration

- `RoutineComposition`, `RoutineExercise`, `SetPrescription` and `ExerciseRef` are immutable `apps/shared` contracts.
- `RoutineRepository` / `SupabaseRoutineRepository` remain unchanged metadata-only `list/create/rename`. The new feature-owned composition repository is separate and projects existing shared contracts.
- PR #511 merged the reviewed migration and transactional authorization/revision/idempotency/350-Set matrix plus actual two-session Routine race test.
- Original six Routine columns and Program owner FK are preserved. Live Routine now has eight columns; Custom Exercise retains twelve and unique `(id, user_id)`.

## 3. Clarification

| Decision | Status | Owner |
|---|---|---|
| Two ordered relational child tables with stable UUID identities | Approved and deployed | Owner via #509 |
| RPC transaction instead of direct child writes | Approved and deployed | Owner via #509 |
| Exact one-migration production apply | Authorized and verified | Owner on 2026-10-11 |
| Feature-owned client adapter | Approved on 2026-10-11; implementation locally validated; review/merge pending | Owner |
| Default My Program, builder, provider activation and session execution | Separate gates; excluded from adapter | Owner |

## 4. Architecture Design

Feature-owned immutable entry/set envelopes preserve persisted UUIDs and project existing `RoutineComposition`/`RoutineExercise`/`SetPrescription` values. Metadata `RoutineRepository` stays unchanged. Reads drain UUID-ascending pages until EMPTY (including a hosted cap smaller than the requested size), then validate the ending parent revision/token and authenticated owner before mapping. Three whole-read attempts bound contention; multiple HTTP requests are not a database transaction. Ordinary composition writes must use the existing RPC.

Save submits one frozen command to the existing owner-checked RPC. A valid RPC revision is authoritative, including its same-token branch before expected-revision comparison. Ambiguous responses trigger read-only reconciliation; only the expected committed revision, same token and exact ordered identified content confirm success. An intervening writer can leave the original outcome unknown. Never automatically rebase, allocate replacement IDs/tokens or loop writes. Unknown bundled catalog references and archived owned Custom Exercise references remain valid identities.

## 5. Implementation Plan

- [x] Approved migration/RPC and SQL security/concurrency tests merged in #511.
- [x] Exact source-head CI and Codex review verified; merged source parity confirmed.
- [x] Fresh main/link/ledger/schema/dependency preflight and CLI dry-run passed.
- [x] Exact migration applied once; independent hosted schema/security/ledger verification passed.
- [x] Documentation reconciliation merged in #512; source branches subsequently cleaned up under separate owner authorization.
- [x] Fresh adapter Owner Approval, main/tracker/ownership reconciliation and hosted contract inspection.
- [x] Feature-owned composition adapter and identified envelopes.
- [x] Focused mapping/pagination/auth/RPC/retry tests and existing metadata regressions.
- [x] Source head `f2487c4`: Flutter CI `38115247700` and required attribution guard PASS; independent review complete, Codex P2 fixed and resolved.
- [ ] Fresh brief-only commit exact-head CI/Codex disposition and owner merge gate.
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

At source head `f2487c4`, required **Commit attribution guard** PASS and Flutter **Analyze and test** PASS (run `38115247700`, full workspace Flutter/Dart analysis and tests). Current main protection requires attribution guard; effective rulesets add no checks. PR #513's supplemental GHAS run `38115248917` failed **before analysis** with external-model monthly HTTP 402 quota (TNYX-256): neither security PASS nor product-code finding. This brief-only commit must receive fresh exact-head checks; do not call old-head evidence current. No SQL changed and database CI does not trigger.

### Adapter Validation — 2026-10-11

- `flutter pub get` passed. Existing `http` 1.6.0 became a direct dev dependency for real SDK HTTP tests; no dependency version upgraded.
- `dart format` on the six new source/test files passed; `flutter analyze` in `apps/features/workout` passed with no issues.
- `flutter test --no-pub --reporter expanded test/domain/routine_composition_repository_test.dart test/data/supabase_routine_composition_repository_test.dart test/data/supabase_routine_composition_gateway_test.dart test/data/supabase_routine_repository_test.dart test/data/supabase_program_repository_test.dart` passed **84 tests**.
- Coverage includes immutable identified projections/repeated refs; ordered complete reads beyond 1,000 entries/sets and lower hosted page caps; revision retries; malformed/null/owner/join/position validation; exact RPC payload; definitive errors; same-token replay; uncertain, superseded, timeout and auth-switch outcomes; actual SDK query serialization and malformed HTTP 200 reconciliation; unchanged metadata regressions.
- Initial analysis/test failures were corrected (generic inference/braces, test cascade precedence, mocked response request linkage and SDK order serialization expectation). Independent read-only source/security reviewers re-reviewed clean after the HTTP 2xx uncertainty fix.
- Existing `tio_core` material-icons test-harness warning remains; no UI/pubspec icon behavior change is part of this slice. Mocked tests do not prove hosted authenticated behavioral writes. No production user rows read or written during the adapter task.

## 7. Final Handoff

### Changed Files — Approved Adapter Slice

- `apps/features/workout/lib/src/domain/repositories/routine_composition_repository.dart` and export barrel — identified immutable values, repository contract and sanitized failures.
- `apps/features/workout/lib/src/data/repositories/supabase_routine_composition_{gateway,repository}.dart` and export barrel — owner-scoped queries, mapping, revision validation and atomic RPC/reconciliation.
- Three focused composition test files under `apps/features/workout/test/{domain,data}`; `pubspec.yaml` / `pubspec.lock` — existing HTTP package exposed for tests only.
- This brief, `.ai/tasks/README.md`, `.ai/IMPLEMENTATION_STATUS.md`, `docs/data/SUPABASE_STRATEGY.md`, `docs/screens/routine-library.md` — precise implementation/review boundary.

### Actual Behavior and Limits

Adapter source/focused tests and exact-source-head Flutter PR CI **PASS** at `f2487c4`; Codex P2 resolved, independent read-only review found no new blocker. This brief-only commit requires fresh exact-head CI/Codex gate. Merge remains owner-gated. Parent revision/token brackets validate independent complete requests under the existing atomic-RPC-only write contract; they do not create an HTTP-spanning database transaction. Ambiguous saves never silently start a replacement mutation. No provider/controller/UI activation, application release, executable SQL, migration or production write in this slice. No branch deletion authorized or performed by this implementation task.

### Final Status

`REVIEW` — approved adapter implemented, source-head CI passed and P2 resolved. Task-governance handoff reconciled; confirm checks/review on final brief-only head, then STOP before owner-authorized merge. TNYX-78 stays In Progress; TNYX-81 stays blocked by TNYX-78/TNYX-80.
