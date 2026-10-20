# GitHub #568 — Canonical My Program identity read projection

**Status:** In progress, review not yet validated.
**Primary owner:** Workout shared domain + feature Program repository
**Affected platforms:** Flutter pure Dart shared model and Workout repository/controller, no visible UI change

## Owner Approval and Scope Boundary

**Trigger:** None. Required internal read-model implementation subtask of the existing owner-approved #568 canonical default Program feature. User requested audit and continuation on 2026-10-20.
**Approval status:** Within existing #568 scope; no new product-visible change.
**Approval evidence:** GitHub #568 direct Library Create contract; ADR-0015; staged PR #637 merged at `main@34d69fbe`.
**Approved product/UI/data-shape boundaries:** Read already-hosted `user_workout_programs.is_default` as server-authoritative boolean; preserve it in immutable Program projections, including a confirmed rename; protect owner-switch read acknowledgments.
**Explicit non-changes:** No Library entry, new Create flow/controller, Create & Move, Undo, deletion policy, RPC grants, schema migration, hosted write, Move release flag or visual/layout change.

## Active Handoff

**Planning owner:** GitHub #568 / Linear TNYX-78; downstream #569 / TNYX-81
**Implementation owner:** Connected GitHub session for this bounded read-projection slice
**Review owner:** Independent PR reviewer not yet assigned
**Implementation ownership state:** Active
**Ownership transition:** Prior #568 staged RPC adapter PR #637 merged; this is a nonoverlapping next scoped slice.
**Repository state last verified:** remote protected `main@34d69fbe668448a0bc098514c09168647d4140fe`; owner's Windows checkout not accessible in this session.
**Branch:** `tnyx/issue-568-default-identity-projection-20261020`
**HEAD SHA:** To be verified after implementation
**Observed working-tree state:** GitHub remote, local owner working-tree UNKNOWN
**Observed uncommitted/dirty files:** Local Windows checkout not accessible; none assumed clean
**PR / tracker:** #568, #569, TNYX-78 In Progress, TNYX-81 Backlog
**Current implementation state:** Hosted #568 migration 66/66. `is_default` authenticated SELECT=true, INSERT=false. Existing `ProgramRepository.list()` selects only id/name; incoming `Program` contains no default marker, so renamed default is indistinguishable from a non-default Program.
**Relevant execution surface:** `apps/shared/lib/src/workout/program.dart`; `apps/features/workout/lib/src/data/repositories/supabase_program_repository.dart`; `apps/features/workout/lib/src/presentation/library/programs/programs_controller.dart`; focused tests and this task index.
**Validation completed at SHA:** Preflight source, GitHub PR #637 and read-only hosted metadata only. No code changes validated yet.
**Validation remaining:** Actual exact-head Flutter/Dart CI, independent review, owner-local diff whitespace validation and cross-session/device QA later.
**Current blocker:** None for dormant read projection; real UI release stays blocked by separate #568 client gates and RPC grants.
**Open review finding IDs:** None yet.
**Next exact action:** Add typed default marker and fail-closed mapping, owner-switch guard and tests; open PR for independent review, do not merge or enable release.

## 1. Discovery

### User Outcome
Recognize the stable canonical default Program even after its display name is renamed, without inventing a default by string matching.

### Success Criteria
- Owner-only `id,name,is_default` query preserves true/false and fails closed for absent/malformed markers.
- `Program` identity distinguishes actual default metadata; user-created Programs start false.
- A verified Program Rename keeps `isDefault` unchanged in controller state; rename writes only `name`.
- A cross-owner change during an awaited Program list must not emit the previous owner's Programs.
- Unchanged production Library UI and no new backend privileges.

### Scope
Shared Program contract, Supabase Program repository read projection, controller rename preservation, focused unit tests and task handoff.

### Non-Goals
Do not activate real My Program Create, Move/Undo, or change database shape, tenant policy, UI or provider flags.

## 2. Codebase Exploration
- Root `AGENTS.md`, feature `AGENTS.md`, ADR-0015, relevant Program source and tests, GitHub issues #568/#569, Linear TNYX-78/TNYX-81, hosted Supabase migration ledger checked.
- Existing `Program` is immutable with id/name equality; the repository's list query currently omits the stable default flag.
- Hosted RLS is enabled for `user_workout_programs`, 66 migrations applied, authenticated `is_default` SELECT allowed and INSERT denied.

## 3. Clarification
- Decision: use the already-authorized boolean in the canonical `Program` model, not a second name-based identity map or another database migration.
- New explicit Program creation defaults false. A server read must supply a real bool and never silently infer one.
- Owner after-await guard is necessary to avoid displaying cross-owner data after auth changes. A same-owner new login-cycle guard is a separate future integration constraint, not claimed by this repository boundary.

## 4. Architecture Design
`SupabaseProgramTableGateway -> SupabaseProgramRepository -> immutable Program(isDefault) -> ProgramsController`.
Keep server-only default creation; no direct client marker writes. Reuse existing Program constructors and controller.

## 5. Implementation Plan
- [ ] Extend Program model/equality with a default-false marker and tests.
- [ ] Map server bool, fail closed on malformed rows and auth owner transition.
- [ ] Preserve marker across confirmed rename; tests for renamed default.
- [ ] Audit exact source diff; run exact-head CI and independent PR review.

## 6. Quality Review
**Validation Run:** Not yet. Flutter SDK/local owner checkout unavailable to connected GitHub session; require GitHub exact-head CI.
**Acceptance Evidence:** Pending exact-head validation and formal review.
**Review Provenance:** Not yet requested; self inspection is not independent review.
**Review Findings and Resolution:** None submitted.

## 7. Final Handoff
**Changed Files:** Pending.
**Actual Behavior:** Pending.
**Known Limitations:** Product activation and complete unknown-outcome Create reconciliation remain separate.
**Final Status:** REVIEW only after source PR opened; no merge claimed.
