# GitHub #567 D2A — Flutter protected Program Delete repository

**Status:** In progress
**Primary owner:** Codex
**Affected platforms:** Flutter `apps/features/workout` data/domain boundary only

## Owner Approval and Scope Boundary

**Trigger:** None — internal implementation subtask of the approved #567 lifecycle slice
**Approval status:** Not required
**Approval evidence:** D1 protected SQL RPC is merged in PR #678; this slice is source-only and remains dormant.
**Approved product/UI/data-shape boundaries:** Add a typed, owner/login-cycle-bound Flutter repository capability for the already-defined D1 RPC.
**Explicit non-changes:** No Program UI, controller/provider wiring, public feature flag activation, hosted migration, GRANT, direct table DELETE, schema change, #569 QA, or production caller.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** Independent reviewer after PR creation
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** Git root `G:/projects/Tio-World`; clean `main` before branch creation; base `main@86fd082515c8cb8cc1ded93fb1a59d360c2f4582`
**Branch:** `tnyx/567-d2a-flutter-program-delete-repository`
**HEAD SHA:** `88ecbd0065cd26d53eeb1758c27135c45a567cd8`
**Observed working-tree state:** Task handoff update pending; fsmonitor IPC warning only
**Observed uncommitted/dirty files:** This task handoff file only
**PR / tracker:** GitHub #567 OPEN; D1 PR #678 merged; D2A PR #681 OPEN; Linear TNYX-81 and TNYX-267 remain backlog/dependency trackers
**Current implementation state:** Dormant typed repository; the two requested PR #681 P2 fixes plus the same-gate follow-up are implemented in `88ecbd0065cd26d53eeb1758c27135c45a567cd8`; no production caller or activation path added
**Relevant execution surface:** `apps/features/workout` repository contracts, Supabase gateway adapter, focused mock-gateway tests, package exports
**Validation completed at SHA:** Dart formatting, Flutter package analyzer, focused 17-test suite, changed-area `test/data` suite (404 tests), and `git diff --check` passed for the lifecycle follow-up at `88ecbd0065cd26d53eeb1758c27135c45a567cd8`
**Validation remaining:** Final-head GitHub Flutter CI will be inspected after push; independent re-review remains pending; hosted migration/EXECUTE and production/UI gates remain intentionally out of scope
**Current blocker:** None for source-only work; hosted EXECUTE remains intentionally unavailable
**Open review finding IDs:** `4369947937`, `4369947940`, and follow-up `4369975166` — fixes pushed; keep all related threads open pending independent re-review
**Next exact action:** Push this bounded lifecycle follow-up and handoff, inspect exact-head CI, reply to all open related threads with evidence, and request independent re-review; do not merge or activate production capability.

## 1. Discovery

### User Outcome

Provide the smallest client-side protected repository boundary for the merged D1 RPC while preserving owner/session safety and keeping the capability dormant.

### Success Criteria

- Exact RPC name and parameters are sent once with a complete explicit Routine-ID snapshot and mutation UUID.
- Only the validated JSONB success shape is confirmed.
- Wrong owner, logout/login-cycle change, ACL rejection, stale membership, default protection, malformed response, repeated request, and ambiguous outcomes are typed and tested.
- No UI or production caller can dispatch the capability.

### Scope

Domain contract, Supabase gateway/adapter, exports, focused unit/mock tests, and this task handoff only.

### Non-Goals

No hosted deployment, permission grant, schema/migration edit, Program UI, confirmation flow, controller wiring, feature flag, direct table mutation, or #569 QA.

## 2. Codebase Exploration

### Verified Evidence

- Existing `SupabaseRoutineMoveRepository` and `SupabaseRoutineDeleteRepository` bind frozen owner/login-cycle state, use injected gateways, disable SDK retry for writes, consume one-use targets, and distinguish definite failures from `UNKNOWN` outcomes.
- Existing `ProgramRepository` remains the metadata list/create/rename source; D2A will not extend it with destructive lifecycle semantics.
- `ProgramId` and `RoutineId` validate canonical UUIDs and normalize to lowercase.
- Merged D1 RPC accepts `p_source_program_id`, `p_expected_routine_ids`, `p_client_mutation_id` and returns `deleted_program_id`, nullable `destination_program_id`, and nonnegative `moved_routine_count`.
- D1 migration revokes all client `EXECUTE`; source merge is not hosted activation.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Use a separate Program Delete repository capability | Made | Avoids creating a second Program metadata source of truth or widening `ProgramRepository` | Codex |
| Require an immutable complete Routine-ID snapshot | Made | Matches D1 exact-membership CAS and prevents name-based authority | Codex |
| Treat missing/ambiguous source state as `UNKNOWN` | Made | D1 has no durable client receipt; absence cannot prove this request committed | Codex |
| Keep adapter un-wired and dormant | Made | Hosted migration and client EXECUTE grant are absent | Codex |

## 4. Architecture Design

### Chosen Approach

Add a public domain `ProgramDeleteRepository` contract and a data `SupabaseProgramDeleteRepository` backed by an injectable `ProgramDeleteGateway`. A prepared target captures source Program ID, complete Routine snapshot, owner, and login cycle. The gateway sends exactly one non-retrying RPC. Success validates all response fields; definite SQL/Auth/ACL/request rejections map to typed failures; timeout/transport/ambiguous or session-changed outcomes remain `UNKNOWN`.

### Ownership and Data Flow

```text
future approved caller -> ProgramDeleteRepository -> SupabaseProgramDeleteGateway -> dormant D1 RPC
```

No current caller/provider is added in D2A.

### Alternative Rejected

Extending `ProgramRepository` or inferring authority from Program name/list state is rejected because it would blur metadata and destructive lifecycle ownership.

### Failure and Accessibility States

This is a non-UI capability. `unauthorized`, `forbidden`, `notFound`, `defaultProtected`, `staleMembership`, `invalidRequest`, `unavailable`, `malformedData`, `inProgress`, and `UNKNOWN` remain typed for a later approved presentation layer.

## 5. Implementation Plan

- [x] Add typed domain target/result/failure/UNKNOWN contract.
- [x] Add non-retrying Supabase RPC gateway and owner/login-cycle adapter.
- [x] Keep capability absent from production composition and feature activation paths.
- [x] Add focused mock-gateway and SDK-shape tests.
- [x] Run formatter, analyzer, focused tests, and diff checks.
- [x] Update this handoff with exact fix SHA, validation evidence, and open review state.

## 6. Quality Review

### Validation Run

```text
`G:\dev\flutter-sdk\bin\cache\dart-sdk\bin\dart.exe format --output=none --set-exit-if-changed apps/features/workout/lib/src/data/repositories/supabase_program_delete_repository.dart apps/features/workout/test/data/supabase_program_delete_repository_test.dart` — PASS, 0 changed.

Flutter tool `analyze` for `apps/features/workout` — PASS, `No issues found!`.

Focused Flutter test `test/data/supabase_program_delete_repository_test.dart` — PASS, 17/17.

Changed-area Flutter tests `test/data` — PASS, `All tests passed!` (404 tests reported by the runner).

`git diff --check` — PASS before commit.

Parent-to-head audit — pending final push; `origin/main` remains an ancestor and only the existing D2A branch is in scope.
```

### Review Provenance

**Review source / link:** [PR #681](https://github.com/im-tnyx/tio-world/pull/681), Codex inline findings `4369947937`, `4369947940`, and follow-up `4369975166`
**Reviewer / relation to implementer:** Codex review findings; independent reviewer re-review requested after `88ecbd0065cd26d53eeb1758c27135c45a567cd8`
**Diff or commit SHA actually reviewed:** Original findings were on prior PR HEAD `41565597`; the follow-up was on `8ae61bf1c4f6a1cc86ec0729002849589e8b4962`; latest fix commit is `88ecbd0065cd26d53eeb1758c27135c45a567cd8`
**Independent review?:** Pending; all related inline threads intentionally remain open
**Limitations and unmet required gates:** Final-head GitHub CI and independent re-review are pending; hosted migration/EXECUTE, device/UI, controller, and merge gates remain intentionally unmet.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/issue-567-d1-atomic-program-delete.md`
- `.ai/tasks/issue-567-d2a-flutter-program-delete-repository.md`
- `apps/features/workout/lib/src/data/data.dart`
- `apps/features/workout/lib/src/data/repositories/supabase_program_delete_repository.dart`
- `apps/features/workout/lib/src/domain/repositories/program_delete_repository.dart`
- `apps/features/workout/lib/src/domain/repositories/repositories.dart`
- `apps/features/workout/test/data/supabase_program_delete_repository_test.dart`

### Actual Behavior

The repository accepts only an explicit owner/login-cycle-bound Program target and complete Routine-ID snapshot, sends the exact D1 RPC once with SDK retry disabled, validates the three-field JSONB receipt, and maps known rejection/permission errors. Empty Programs now accept either a null destination (no default) or a valid existing canonical default destination, while invalid IDs and counts remain rejected as malformed/`UNKNOWN`. A definite server rejection permits only a newly confirmed target and new mutation UUID; every previously rejected target fingerprint and mutation UUID remains consumed, while timeout, lost ACK, malformed response, session change, or any other ambiguous outcome stays `UNKNOWN` and blocks destructive retry. No source read is treated as proof and no automatic retry is issued.

### Known Limitations

The repository capability is source-only and dormant. It cannot establish hosted permission or production activation.

### Final Status

`REVIEW` — source-only PR #681 remains open; all related P2 threads are open pending independent re-review and exact-head GitHub CI. No merge or production activation.
