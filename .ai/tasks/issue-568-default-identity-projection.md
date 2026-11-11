# GitHub #568 — Canonical My Program identity read projection

**Status:** In Review at [PR #638](https://github.com/im-tnyx/tio-world/pull/638). Original exact-head Flutter CI 5/5 PASS; formal independent `im-tio` CHANGES_REQUESTED P2 docs-precondition correction. This update resolves the cited conflicting index wording; latest-head revalidation/re-review still pending.
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
**Review owner:** `im-tio`, formal independent GitHub CHANGES_REQUESTED on `80f1c737` (P2 documentation consistency, no code-level P1/P2/P3); re-review required after this amendment.
**Implementation ownership state:** Handoff pending; source staged on review branch, no merge authorization
**Ownership transition:** Prior #568 staged RPC adapter PR #637 merged; this is a nonoverlapping next scoped slice.
**Repository state last verified:** remote protected `main@34d69fbe668448a0bc098514c09168647d4140fe`; owner's Windows checkout not accessible in this session.
**Branch:** `tnyx/issue-568-default-identity-projection-20261020`
**HEAD SHA:** source + tests staged at `347058b50b5e847c5b9e1f85279c3933c8912980`; final PR head must be reverified after this handoff-only commit
**Observed working-tree state:** GitHub remote, local owner working-tree UNKNOWN
**Observed uncommitted/dirty files:** Local Windows checkout not accessible; none assumed clean
**PR / tracker:** #568, #569, TNYX-78 In Progress, TNYX-81 Backlog
**Current implementation state:** Source now selects `id,name,is_default` and maps mandatory boolean into immutable `Program.isDefault`. Cross-owner post-await reads are rejected, explicit client creation cannot claim the default marker, and controller rename preserves it. Hosted #568 migration 66/66; client RPC EXECUTE still OFF.
**Relevant execution surface:** `apps/shared/lib/src/workout/program.dart`; `apps/features/workout/lib/src/data/repositories/supabase_program_repository.dart`; `apps/features/workout/lib/src/presentation/library/programs/programs_controller.dart`; focused tests and this task index.
**Validation completed at SHA:** Flutter CI #39451793158 **5/5 PASS** and attribution **PASS** at PR `80f1c737`; hosted read-only 66/66 applied with authenticated `is_default` SELECT true, INSERT false (2026-10-20). Owner Windows receipt on same SHA confirms clean local `main...origin/main` and `git diff --check` with no diagnostics; explicit process exit code not printed. Docs-only reviewer-finding commit still requires fresh exact-head CI/check verification.
**Validation remaining:** Latest-head CI after reviewer-finding docs amendment; independent `im-tio` re-review clearing CHANGES_REQUESTED; explicit owner-local diff exit-code receipt if required by final merge gate; device QA only before future activation.
**Current blocker:** Formal `im-tio` P2 document inconsistency in `.ai/tasks/README.md` raised at `80f1c737`; addressed in current PR branch, awaiting independent verification. Product release blocked separately by #568 pending client gates and RPC grants.
**Open review finding IDs:** P2-DOC-01, `im-tio` review on `80f1c737`: current task index wrongly still listed 65/66 and `is_default` absent in 4 #569 rows. Corrected those four rows with current 66/66 + link to dated #568 hosted deployment receipt; historical pre-deployment snapshots explicitly marked superseded. Awaiting re-review.
**Next exact action:** Verify latest docs-only correction SHA, exact changed paths/CI; request independent `im-tio` re-review and secure formal disposition. No merge or release.

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
- [x] Extend Program model/equality with a default-false marker and tests.
- [x] Map server bool, fail closed on malformed rows and auth owner transition.
- [x] Preserve marker across confirmed rename; tests for renamed default.
- [ ] Audit exact source diff; run exact-head CI and independent PR review.

## 6. Quality Review
**Validation Run:** Flutter CI #39451793158 5/5 PASS on prior `80f1c737` (source behavior). Read-only hosted 66/66 verified and `is_default` authenticated SELECT true/INSERT false. Owner-provided Windows PowerShell `git diff --check` had no diagnostics; `$LASTEXITCODE` not printed. Re-run checks after docs-only change and do not presume new-head success.
**Acceptance Evidence:** Focused tests added for mapped renamed default, malformed marker, cross-owner list read, client default creation prevention and marker-preserving controller Rename. Tests have not yet been reported passing at the latest head.
**Review Provenance:** Independent `im-tio` GitHub formal CHANGES_REQUESTED on `80f1c737`, P2 docs/precondition mismatch in task index. No new code-level P1/P2/P3 identified. Author `im-tnyx` COMMENTED is self-review only. Fix applied in this PR with dated hosted receipt; waiting on independent re-review.
**Review Findings and Resolution:** None submitted.

## 7. Final Handoff
**Changed Files:** Shared Program model + test; Workout Program Supabase repository + test; ProgramsController + test; task brief and `.ai/tasks/README.md`.
**Actual Behavior:** On a successful owner read, a server-provided boolean distinguishes a default Program even after rename. No production user-visible entry or mutation is enabled.
**Known Limitations:** Product activation and complete unknown-outcome Create reconciliation remain separate.
**Final Status:** REVIEW gate. PR #638 open and review requested; no pass/approval/merge claimed.
