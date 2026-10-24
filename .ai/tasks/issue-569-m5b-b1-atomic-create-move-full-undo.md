# M5B-B1 Atomic Create & Move Full Undo Backend

**Status:** Validated
**Primary owner:** Supabase/Postgres implementation owner
**Affected platforms:** `supabase/*` database/RPC tests only

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** User-approved `GO M5B-B1` in the active task; exact three nullable provenance columns, existing Create & Move provenance update, protected Undo RPC, minimum constraints/indexes, focused security/concurrency/idempotency tests, disposable QA and focused PR.
**Approved product/UI/data-shape boundaries:** Add only `create_move_mutation_id`, `create_move_routine_id`, and `create_move_source_program_id` to `public.user_workout_programs`; update the existing atomic Create & Move RPC; add `undo_create_user_workout_program_and_move_routine(...) returns bigint`; keep all Move/Undo client EXECUTE grants revoked.
**Explicit non-changes:** No new receipt table or additional column unless correctness proves it indispensable; no hosted migration/grant/deploy; no Flutter M5B UI/adapter; no general Program Delete; no M5A redesign; no feature-flag activation; no merge.

## Active Handoff

**Planning owner:** Tio-world owner approval
**Implementation owner:** Supabase/Postgres implementation owner
**Review owner:** Pending focused PR review
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `2026-10-24`; local `main` and `origin/main` at `9811086ed05db877ffc619fddea4fde284299f42`; `git fetch origin --prune` blocked by `.git/FETCH_HEAD` permission denied; live GitHub main independently matched.
**Branch:** `codex/issue-569-m5b-b1-backend`
**Base/main SHA at branch creation:** `9811086ed05db877ffc619fddea4fde284299f42`
**Feature-branch verification checkpoint:** `357aae2ec4215b82dd2aee6a4c956eb9352123cb` (handoff metadata checkpoint; current live PR head is authoritative)
**Current live PR head authority:** GitHub PR #664 `headRefOid`; do not treat this handoff field as a self-referential immutable `HEAD` claim.
**Observed working-tree state:** Clean at feature verification checkpoint `357aae2ec4215b82dd2aee6a4c956eb9352123cb`; later documentation corrections require fresh exact-head verification.
**Observed uncommitted/dirty files:** None at the recorded checkpoint; this P3 correction is the only approved documentation change.
**PR / tracker:** GitHub #569, PR #664; Linear `TNYX-81`, `TNYX-267`, `TNYX-78`
**Current implementation state:** Approved M5B-B1 backend implemented; hosted deployment and client activation remain disabled
**Relevant execution surface:** `supabase/migrations`, `supabase/tests/database`
**Implementation validation checkpoint:** `e0733baa6138fb2beddba685b3d929daae529f6a`; disposable GitHub Supabase DB CI run `40050837446` passed migration replay, M5B SQL/RLS/idempotency matrix, two-session Undo race and lint workflow.
**Handoff validation checkpoint:** `357aae2ec4215b82dd2aee6a4c956eb9352123cb`; CI run `40051140062` passed the then-current handoff content. Neither run is evidence for commits made afterward; current live PR head and its CI are authoritative.
**Validation remaining:** Fresh current-head Codex review; hosted deployment is not permitted in this slice.
**Current blocker:** Branch-protection required-check policy could not be independently read because GitHub returned HTTP 403; Cursor/Copilot review services were skipped or quota-limited.
**Open review finding IDs:** None; P1/P2/P3 threads were replied to with evidence and resolved at the verified checkpoint.
**Next exact action:** Obtain current-head Codex/independent review after the final handoff checkpoint, then stop before merge/deploy/grant activation.

## 1. Discovery

### User Outcome

Undo a successful atomic Create & Move by restoring the same Routine to its original Program and deleting only the exact newly-created empty Program, as one protected transaction.

### Success Criteria

- Provenance is stamped atomically on the created Program.
- Undo is owner-scoped, CAS-protected, fail-closed and idempotent for the exact token.
- Routine/Exercise/Set identities and composition remain unchanged.
- B deletion is limited to the exact operation-created, unmodified, empty non-default Program.
- Ordinary hosted clients cannot execute the privileged functions or direct parent mutation/delete.

### Scope

One forward migration, one protected Undo RPC, the existing Create & Move RPC provenance update, and focused disposable SQL/concurrency/security tests.

### Non-Goals

Flutter wiring, hosted deployment, grant activation, release flag changes, general Program deletion, new infrastructure or unrelated refactors.

## 2. Codebase Exploration

### Verified Evidence

- Current live hosted catalog has 68 applied migrations, no M5B provenance columns, and no current Program/Routine history or TrainingPlan FK references beyond Routine composition children.
- Existing permanent-owner Move and Create & Move RPCs are `SECURITY DEFINER`, `SET search_path = ''`, owner/CAS guarded, and revoked from ordinary roles.
- Existing M5A reverses existing-Program moves through the Flutter repository; M5B backend must use a separate atomic transaction because B must be deleted.
- `routineMoveReleaseEnabledProvider` remains `false` and Flutter is out of scope.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Add a persistent receipt/tombstone table? | Rejected | Existing Routine revision, last mutation token and deterministic hash prove exact post-delete replay; adding a table exceeds approval. | Implementation owner |
| Add a provenance partial-coherence CHECK? | Chosen | Prevents server-managed provenance from being partially populated. | Implementation owner |
| Enable hosted EXECUTE/deploy? | Rejected | Explicitly out of scope and separate release approval. | Owner |

## 4. Architecture Design

### Chosen Approach

Add three nullable provenance UUIDs and a coherence CHECK. Stamp them in the existing atomic Create & Move insert. The Undo RPC locks account, Programs in sorted UUID order, Routine identity and Routine row; validates permanent auth owner, exact provenance, immutable Create & Move hash/name, expected revision, empty B and eligible A; updates Routine to A and deletes B in one transaction. It writes an Undo hash on the Routine for exact replay after B deletion.

### Failure and Idempotency

Exact replay succeeds only when B is absent, Routine is at A, revision is `p_expected_revision + 1` (`p_expected_revision` is the existing post-Move receipt revision), and the stored mutation/hash exactly matches the same Undo token and parameters. Any different token, later write, stale revision, renamed/reused B, additional Routine, missing/ineligible A, ownership mismatch, or unknown state fails without a partial commit.

## 5. Implementation Plan

- [x] Add approved migration and protected RPC.
- [x] Add focused SQL/RLS/idempotency/rollback tests.
- [x] Run disposable CI database validation and lint; local execution unavailable.
- [ ] Complete current-head independent review; stop before merge/deploy.

## 6. Quality Review

### Validation Run

```text
`git diff --check` passed. Implementation checkpoint `e0733baa6138fb2beddba685b3d929daae529f6a` passed disposable Supabase Database CI run `40050837446`; handoff checkpoint `357aae2ec4215b82dd2aee6a4c956eb9352123cb` passed run `40051140062`. Exact feature checkpoint `7c57ab18799179bd175d8dca1deaff1e1631126d` passed Supabase Database CI run `40052108838` and Docs Hygiene CI run `40052108797`; the three review threads were replied to and resolved with those results. Local Supabase/psql not run due environment limitations. Any later commit requires fresh exact-head verification.
```

### Final Status

`REVIEW`
