# GitHub #568 — programless Create positive read-back identity guard

**Status:** In Review at [PR #639](https://github.com/im-tnyx/tio-world/pull/639). Flutter CI 5/5 PASS at source HEAD `b4deb0c3`; independent reviewer confirmed source P2 fixed. Docs-only handoff correction, refreshed exact-head CI/re-review and merge authorization are separate remaining gates.
**Primary owner:** Workout domain verification contract
**Affected platforms:** Flutter Workout pure-domain contract and unit tests; no visible UI or hosted writes

## Owner Approval and Scope Boundary

**Trigger:** None. This is an internal verification subtask of owner-approved GitHub #568 direct Library Create Routine → canonical default My Program.
**Approval status:** Within existing #568 scope; user authorized continuation on 2026-10-20.
**Approved behavior:** A lost RPC ACK may only become confirmed through authenticated owner/login-cycle-scoped positive reads of the server-owned `is_default` Program, the same persisted Routine belonging to that Program, and exact mutation/ordered composition.
**Explicit non-changes:** No new Library entry, UI geometry, composer refactor, app-shell provider, RPC grant, Supabase DDL, live writes, Move/Undo activation, automatic replay, or release flag.

## Active Handoff

**Planning owner:** GitHub #568 / Linear TNYX-78. Downstream #569 / TNYX-81.
**Implementation owner:** Connected GitHub session, this read-back contract + tests only.
**Review owner:** `im-tio` independent GitHub reviewer. On source HEAD `b4deb0c3`, the source P2 was verified fixed; formal CHANGES_REQUESTED on this same HEAD identified stale active task documentation and has not yet been cleared by an APPROVED review.
**Implementation ownership state:** Complete for bounded source/test slice; PR #639 in review; no new implementation owner may overlap without handoff.
**Ownership transition:** Prior #638 merged to main `604ff62a949315654fdd927305308c9a1ebe65c7`; new nonoverlapping #568 subtask.
**Repository state last verified:** GitHub remote protected `main@604ff62a949315654fdd927305308c9a1ebe65c7`.
**Branch:** `tnyx/issue-568-programless-positive-readback-20261020`
**HEAD SHA:** Source/review checkpoint `b4deb0c3af555fcc386fa8c3917f5a0fb956a861`; this docs-only update advances the PR head, which must be re-read from GitHub before further gate claims.
**Observed working-tree state:** Connected session can inspect GitHub refs, not the owner's Windows filesystem. Owner-supplied Windows PowerShell transcript on 2026-10-20 verified `origin/main=604ff62a` and PR branch=`b4deb0c3` and printed `PR #639 DIFF CHECK PASS` after exit-code guards; local working-tree cleanliness was not part of that transcript.
**Observed uncommitted/dirty files:** Not inspected locally; no claim.
**PR / tracker:** [PR #639](https://github.com/im-tnyx/tio-world/pull/639), #568, #569, TNYX-78 In Progress, TNYX-81 Backlog.
**Current implementation state:** Dormant My Program RPC adapter and `Program.isDefault` projection already merged; this slice adds only the positive proof boundary needed for future UNKNOWN reconciliation.
**Relevant execution surface:** `apps/features/workout/lib/src/domain/repositories/my_program_routine_create_repository.dart` and focused existing repository test, plus this handoff/index.
**Validation completed at SHA:** GitHub protected `main@604ff62a`, four scoped changed paths, nine commits ahead/zero behind at source `b4deb0c3`. Exact source-head Flutter CI [#39459381934](https://github.com/im-tnyx/tio-world/actions/runs/39459381934) **5/5 SUCCESS**, required Commit attribution guard SUCCESS; independent `im-tio` review verified `snapshot.name` P2 code fix at `b4deb0c3`. Owner-provided PowerShell at matching source refs printed `PR #639 DIFF CHECK PASS` following guarded `git diff --check origin/main...origin/tnyx/issue-568-programless-positive-readback-20261020` with no diagnostics. Hosted 66/66 migrations; first-Routine and both Move RPCs remain authenticated EXECUTE denied. These proofs apply to stated source HEAD, not automatically to this later docs-only amendment.
**Validation remaining:** Recheck ancestry/files and rerun exact-new-head CI after this docs-only handoff update; request `im-tio` formal APPROVED clearing the CHANGES_REQUESTED docs findings. Owner-local diff PASS already evidenced on unchanged source head; capture fresh diff receipt only if required by final updated-head merge policy. Physical-device QA remains for later runtime activation, not the dormant helper.
**Current blocker:** First-Routine grant/UI and full owner-cycle pending controller remain gated. This helper must not be mistaken for a complete user-visible Create flow.
**Review finding IDs / disposition:** `P2-SNAPSHOT-NAME` **FIXED** by `d372d870` (predicate) and `56c2e9db` (negative tests), independently verified on source HEAD `b4deb0c3`; Codex prior stale-handoff P2 FIXED and its thread resolved. The latest independent CHANGES_REQUESTED identified `P2-HANDOFF-CI-INDEX` and `P2-HANDOFF-VALIDATION` (task/index falsely saying CI pending and P2 open); corrected by this documentation-only follow-up, awaiting reviewer recheck. No unresolved *source-level* P1/P2/P3 identified at `b4deb0c3`.
**Next exact action:** Recheck the new docs-only PR head and exact-head CI, then obtain `im-tio` formal disposition/APPROVED for documentation correction; retain no-merge until separately authorized. After merge and post-merge sync, start separately bounded #568 programless pending/UNKNOWN controller integration.

## 1. Discovery

### User Outcome
Prevent the programless first Routine Create from being reported successful based only on a matching Program display name or unrelated/superseded composition.

### Success Criteria
- Require persisted Program with `isDefault=true`, same `RoutineId`, owner Program relation and submitted Routine name.
- Also require bracketed `RoutineCompositionSnapshot.name == submitted name`, exact revision-one mutation and ordered Exercise/Set content via existing `confirmsPersistedRoutine` check.
- A renamed canonical default is accepted; ordinary Program named `My Program` is rejected.
- Other Program, other Routine, renamed/superseded Routine, absent/mismatched bracketed snapshot name, changed mutation or composition fail closed.
- This helper is positive evidence only. Caller still must enforce owner/login-cycle-authenticated reads.

### Non-Goals
No asynchronous pending state/controller or UI navigation in this subtask; no server/privilege changes.

## 2. Codebase Exploration

- Read root and `apps/features/AGENTS.md`, ADR-0015, `.ai/FEATURE_DEVELOPMENT.md`, `.github/PUSH_TEMPLATE.md` and PR template, #568/#569, Linear TNYX-78/TNYX-81.
- Current `MyProgramRoutineCreateCommand.confirmsPersistedRoutine` checks revision/mutation/composition but explicitly does not prove default Program ownership.
- Current canonical `Program` has server-derived `isDefault`; `Routine` holds `programId`.
- Reuse these immutable entities. No duplicate reconciliation model or read service.
- Linear `get_agent_context` returned Tool not found in this session; direct Linear issue retrieval succeeded.

## 3. Clarification

Existing approved identity contract suffices; no additional Owner Approval trigger. Choose a pure predicate, not a new network adapter or UI-specific object.

## 4. Architecture Design

Caller performs owner/login-cycle-verified `ProgramRepository.list`, `RoutineRepository.list` and `RoutineCompositionRepository.read`, then invokes command's positive proof predicate. Negative read does **not** prove rollback; preserve frozen mutation IDs and UNKNOWN state.

## 5. Implementation Plan

- [x] Add pure positive verification predicate using `Program.isDefault`, `Routine`, and existing composition verification.
- [x] Add focused positive/negative unit regressions.
- [x] Inspect four owned changed paths and source-head Flutter CI `39459381934` 5/5 PASS at `b4deb0c3`.
- [ ] Validate this subsequent documentation-only HEAD and obtain formal independent review clearance.

## 6. Quality Review

**Validation Run:** Flutter CI [run #39459381934](https://github.com/im-tnyx/tio-world/actions/runs/39459381934) **5/5 SUCCESS** at source HEAD `b4deb0c3`; GitHub Commit attribution guard SUCCESS. Owner-provided Windows `git diff --check` guarded transcript **PASS** against exactly `origin/main@604ff62a` and PR source HEAD `b4deb0c3`. No Flutter SDK test or local Git command was executed inside this connected session. New docs-only HEAD requires its own CI verification.
**Acceptance evidence:** Source helper and null/conflicting-header-name regressions reviewed by independent `im-tio` at `b4deb0c3`; exact source-head CI `39459381934` passed all five jobs. This helper remains opt-in/unwired, so runtime Create flow, RPC grants and device QA are not covered by these tests.
**Review provenance:** Independent `im-tio` GitHub review of `b4deb0c3` verified `P2-SNAPSHOT-NAME` fixed and no new source P1/P2/P3; after CI passed it submitted **CHANGES_REQUESTED solely for stale `.ai/tasks` validation and index claims** (two inline P2 threads). This docs-only correction reconciles both. Codex earlier handoff P2 thread is resolved. The reviewer has not yet submitted `APPROVED`, so current review gate remains active.

## 7. Final Handoff

**Changed files:** `apps/features/workout/lib/src/domain/repositories/my_program_routine_create_repository.dart`, `apps/features/workout/test/data/supabase_my_program_routine_create_repository_test.dart`, task brief, task index.
**Actual behavior:** New opt-in pure predicate accepts only verified canonical default identity plus matching Routine and composition. Existing runtime does not call this helper yet.
**Known limitations:** This safe helper does not activate the client operation; authenticated EXECUTE remains denied and later controller/app-shell integration is mandatory.
**Final status:** REVIEW. Source-head `b4deb0c3` CI and owner-provided diff receipt are verified as stated, but updated docs-only HEAD CI/formal independent approval and separate merge authorization are not yet complete.
