# GitHub #568 — programless Create positive read-back identity guard

**Status:** In Review at [PR #639](https://github.com/im-tnyx/tio-world/pull/639). Source HEAD `b4deb0c3` Flutter CI [#39459381934](https://github.com/im-tnyx/tio-world/actions/runs/39459381934) 5/5 PASS; later docs-only HEAD `5db0630a` Flutter CI [#39461042893](https://github.com/im-tnyx/tio-world/actions/runs/39461042893) 5/5 PASS. Independent source P2 fixed. Formal independent APPROVED, final-HEAD local diff receipt and owner merge direction remain outstanding. Future-head CI/review must be read live from GitHub, not inferred from this checkpoint.
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
**Review owner:** `im-tio` independent GitHub reviewer. Source P2 verified fixed on `b4deb0c3`; exact-head `5db0630a` re-review found no new source P1/P2/P3 but submitted CHANGES_REQUESTED for stale CI/handoff claims and missing same-HEAD local docs diff receipt. These are review/validation requirements, not new source defects. Await independent APPROVED after this correction and an owner-provided final-head diff receipt.
**Implementation ownership state:** Complete for bounded source/test slice; PR #639 in review; no new implementation owner may overlap without handoff.
**Ownership transition:** Prior #638 merged to main `604ff62a949315654fdd927305308c9a1ebe65c7`; new nonoverlapping #568 subtask.
**Repository state last verified:** GitHub remote protected `main@604ff62a949315654fdd927305308c9a1ebe65c7`.
**Branch:** `tnyx/issue-568-programless-positive-readback-20261020`
**HEAD SHA:** Audited source checkpoint `b4deb0c3af555fcc386fa8c3917f5a0fb956a861`; docs-only CI-verified checkpoint `5db0630a54c7710043bb277d13758a7d7e02b95a`. These are evidence-specific commit IDs, not a claim that either is the live HEAD after subsequent commits; retrieve the live PR head at validation/merge time.
**Observed working-tree state:** Connected session can inspect GitHub refs, not the owner's Windows filesystem. Owner-supplied Windows PowerShell transcript on 2026-10-20 verified `origin/main=604ff62a` and PR branch=`b4deb0c3` and printed `PR #639 DIFF CHECK PASS` after exit-code guards; local working-tree cleanliness was not part of that transcript.
**Observed uncommitted/dirty files:** Not inspected locally; no claim.
**PR / tracker:** [PR #639](https://github.com/im-tnyx/tio-world/pull/639), #568, #569, TNYX-78 In Progress, TNYX-81 Backlog.
**Current implementation state:** Dormant My Program RPC adapter and `Program.isDefault` projection already merged; this slice adds only the positive proof boundary needed for future UNKNOWN reconciliation.
**Relevant execution surface:** `apps/features/workout/lib/src/domain/repositories/my_program_routine_create_repository.dart` and focused existing repository test, plus this handoff/index.
**Validation completed at SHA:** GitHub protected `main@604ff62a`; four expected owned paths, compare 11 ahead/0 behind at docs-only checkpoint `5db0630a`. Source-head `b4deb0c3` Flutter CI [#39459381934](https://github.com/im-tnyx/tio-world/actions/runs/39459381934) **5/5 SUCCESS** and docs-only `5db0630a` Flutter CI [#39461042893](https://github.com/im-tnyx/tio-world/actions/runs/39461042893) **5/5 SUCCESS**, exact-head attribution guard PASS. Independent `im-tio` verified source `snapshot.name` P2 fix and null/mismatch tests. Owner-provided Windows PowerShell `git diff --check` PASS was **specifically on source head `b4deb0c3` only**, not `5db0630a` or later. Hosted 66/66 migrations were verified earlier; first-Routine and both Move RPCs remain gated and no privileged runtime mutation was made. Live HEAD and check results are intentionally verified from GitHub at final review instead of treating this checkpoint as dynamically up-to-date.
**Validation remaining:** Owner-local guarded `git diff --check origin/main...<PR branch>` receipt for the **final live HEAD**, because previous transcript only covered `b4deb0c3`; independently recheck latest PR HEAD, ancestry, changed files, required live CI, review disposition and branch protection immediately before merge. Obtain `im-tio` formal APPROVED clearing stale-handoff P2s. Existing source and docs checkpoint CI results are PASS as stated above; no contradictory pending claim. Device QA remains a later runtime activation gate, not a dormant-helper PR gate.
**Current blocker:** First-Routine grant/UI and full owner-cycle pending controller remain gated. This helper must not be mistaken for a complete user-visible Create flow.
**Review finding IDs / disposition:** `P2-SNAPSHOT-NAME` **FIXED** (`d372d870`, `56c2e9db`), independently verified source; earlier Codex stale handoff P2 FIXED, thread resolved. `im-tio` later `P2-HANDOFF-CI-INDEX`/`P2-HANDOFF-VALIDATION` corrections committed as `2735896c`/`5db0630a` and threads resolved. At `5db0630a`, independent re-review found two **new documentation-truth P2 threads**: stale statement that run `39461042893` remained pending, and absence of current-head *owner-local* diff check. First fixed by this checkpoint correction; the second remains openly gated until an owner transcript for the actual final HEAD. No source-level P1/P2/P3 open at reviewed `5db0630a`. Formal CHANGES_REQUESTED persists until independent disposition.
**Next exact action:** Confirm the final live PR head/required CI through GitHub, collect a guarded owner-local `git diff --check` receipt for exactly that head, and request `im-tio` formal approval. Record volatile final-head receipt in the PR review conversation instead of making another commit just to say CI passed, as that would change HEAD and invalidate that receipt. Do not merge without owner direction and clean gates. After an authorized merge and post-merge sync, continue separately bounded #568 programless pending/UNKNOWN controller.

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
- [x] Verify docs-only checkpoint `5db0630a` Flutter CI `39461042893` 5/5 PASS and source P2 fixed.
- [ ] Final live-head owner-local guarded `git diff --check` receipt, updated-head CI/ancestry check and independent formal APPROVED.

## 6. Quality Review

**Validation Run:** Source HEAD `b4deb0c3` Flutter CI [#39459381934](https://github.com/im-tnyx/tio-world/actions/runs/39459381934) **5/5 SUCCESS**; docs-only `5db0630a` Flutter CI [#39461042893](https://github.com/im-tnyx/tio-world/actions/runs/39461042893) **5/5 SUCCESS**, attribution guard PASS at both checkpoints. Owner-provided guarded Windows `git diff --check` **PASS** only at `b4deb0c3`; exact live HEAD local diff check must still be supplied. No owner filesystem was accessed and no local Git or Flutter command was run in this connected session. Subsequent commits require live CI/review checks as a separate gate; do not mark validated results retroactively pending.
**Acceptance evidence:** Source helper and null/conflicting-header-name regressions reviewed by independent `im-tio` at `b4deb0c3`; exact source-head CI `39459381934` passed all five jobs. This helper remains opt-in/unwired, so runtime Create flow, RPC grants and device QA are not covered by these tests.
**Review provenance:** Independent `im-tio` verified source P2 fixed at `b4deb0c3`, and reviewed docs-only `5db0630a` after its five CI jobs passed; no source P1/P2/P3. Independent CHANGES_REQUESTED at `5db0630a` concerns incorrect handoff claiming CI still pending and missing exact-head local diff evidence. The former is corrected here and the latter is explicitly still outstanding. Earlier handoff P2 threads are resolved. **No independent APPROVED review** yet; this is not a merge approval.

## 7. Final Handoff

**Changed files:** `apps/features/workout/lib/src/domain/repositories/my_program_routine_create_repository.dart`, `apps/features/workout/test/data/supabase_my_program_routine_create_repository_test.dart`, task brief, task index.
**Actual behavior:** New opt-in pure predicate accepts only verified canonical default identity plus matching Routine and composition. Existing runtime does not call this helper yet.
**Known limitations:** This safe helper does not activate the client operation; authenticated EXECUTE remains denied and later controller/app-shell integration is mandatory.
**Final status:** REVIEW. Flutter CI and attribution PASS at both audited checkpoints `b4deb0c3` and `5db0630a`, and initial owner-local diff PASS at `b4deb0c3`. The **final live HEAD** still requires current checks and a matching owner-local diff receipt; independent APPROVED and separate merge authorization are not established. The current live HEAD is intentionally not encoded as a fixed self-referential validation claim in this document.
