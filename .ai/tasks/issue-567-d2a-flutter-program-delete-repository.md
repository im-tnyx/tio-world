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
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** Git root `G:/projects/Tio-World`; clean `main` before branch creation; base `main@86fd082515c8cb8cc1ded93fb1a59d360c2f4582`
**Branch:** `tnyx/567-d2a-flutter-program-delete-repository`
**HEAD SHA:** `86fd082515c8cb8cc1ded93fb1a59d360c2f4582`
**Observed working-tree state:** Clean at branch creation, fsmonitor IPC warning only
**Observed uncommitted/dirty files:** None at branch creation
**PR / tracker:** GitHub #567 OPEN; merged D1 PR #678; Linear TNYX-81 and TNYX-267 remain backlog/dependency trackers
**Current implementation state:** Architecture audit complete; D1 brief reconciled as stale; source implementation pending
**Relevant execution surface:** `apps/features/workout` repository contracts, Supabase gateway adapter, focused mock-gateway tests, package exports
**Validation completed at SHA:** Historical D1 SQL/ACL evidence is at merged PR #678 and is not current D2A validation
**Validation remaining:** `dart format`, focused `flutter test`, `flutter analyze`, `git diff --check`
**Current blocker:** None for source-only work; hosted EXECUTE remains intentionally unavailable
**Open review finding IDs:** None yet
**Next exact action:** Implement dormant typed repository and focused security/UNKNOWN tests without production wiring.

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

- [ ] Add typed domain target/result/failure/UNKNOWN contract.
- [ ] Add non-retrying Supabase RPC gateway and owner/login-cycle adapter.
- [ ] Keep capability absent from production composition and feature activation paths.
- [ ] Add focused mock-gateway and SDK-shape tests.
- [ ] Run formatter, analyzer, focused tests, and diff checks.
- [ ] Update this handoff with exact validation SHA and review state.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Provenance

**Review source / link:** Not available yet
**Reviewer / relation to implementer:** Independent review requested through bounded PR handoff
**Diff or commit SHA actually reviewed:** Not available yet
**Independent review?:** Unknown / unavailable
**Limitations and unmet required gates:** Hosted migration/EXECUTE and device/UI gates remain intentionally unmet.

## 7. Final Handoff

### Changed Files

To be populated after implementation.

### Actual Behavior

To be populated after implementation and tests.

### Known Limitations

The repository capability is source-only and dormant. It cannot establish hosted permission or production activation.

### Final Status

`REVIEW`
