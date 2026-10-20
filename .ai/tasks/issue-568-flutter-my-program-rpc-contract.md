# #568 — Flutter My Program atomic first-Routine RPC contract (bounded adapter slice)

**Status:** Source staged; exact-head Flutter CI and independent review pending (NO product activation)
**Primary owner:** Workout feature data/domain
**Affected platforms:** Flutter Android/iOS Workout package, no production UI activation

## Owner Approval and Scope Boundary

**Trigger:** None beyond existing #568 approved direct Library Create Routine → canonical My Program product scope.
**Approval status:** Approved — user said `Go #568 Flutter implementation to review gate` on 2026-10-20.
**Approved behavior:** New first-Routine command has no speculative existing ProgramId; uses the deployed `create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)` which performs lazy Program resolution and atomic composition save. Transport failure must remain UNKNOWN, never blind retry. Existing explicit Program Create must not change.
**This slice:** Pure typed Workout domain command and returned Program+revision receipt, one Flutter Supabase adapter that invokes this RPC without altering existing Program-scoped Create, and real-SDK mocked transport tests.
**Out of scope:** Library-root UI card/navigation; CreatePage/controller pending-map refactor, ProgramRepository default projection, unknown-outcome read-back flow, RPC grants, hosted DDL, default Program deletion and Move #569, automatic remote deploy. These are required *subsequent* reviewable stages under the same existing approved feature, not silently delivered here.

## Active Handoff

**Planning owner:** #568 / W1 architect
**Implementation owner:** Connected GitHub session, exclusive `tnyx/issue-568-flutter-my-program-rpc-contract-20261020` domain/data/tests slice
**Review owner:** Independent `im-tio` reviewer after implementation
**Implementation ownership state:** Active
**Ownership transition:** Separate from prior completed #568 Supabase migration source owner; no parallel edits to the same files
**Repository state last verified:** remote `main@65af3391f45cf48c79462390a7b6b3ff8da71f06` clean owner Windows checkout on same SHA (owner provided)
**Branch:** `tnyx/issue-568-flutter-my-program-rpc-contract-20261020`
**HEAD SHA:** To be captured after push
**Observed working-tree state:** Remote connected GitHub branch; owner's local main clean, not accessed by this agent
**Observed uncommitted/dirty files:** Not locally inspected, outside current connector
**PR / tracker:** GitHub #568; Linear TNYX-78 In Progress; TNYX-81 Backlog blocked by TNYX-78/TNYX-80
**Relevant execution surface:** `apps/features/workout/lib/src/domain/repositories/**`, `apps/features/workout/lib/src/data/**`, `apps/features/workout/test/data/**`, this brief
**Validation completed at SHA:** GitHub compare scope audit at branch head before final brief edit (7 owned files, 0 behind); manual source review; Flutter CI not yet run
**Validation remaining:** Exact-head Flutter CI, independent security review, owner exact-branch `git diff --check`, real device path later
**Current blocker:** New RPC EXECUTE denied on hosted intentionally; no live UI exposure permitted. Flutter SDK is not available to this connected GitHub session; exact-head GitHub CI is required before code validation can be claimed.
**Next exact action:** Validate the staged typed contract + RPC adapter + tests on the exact PR head through Flutter CI and independent review. Do not merge or release in this session without separate owner merge instruction.

## Audit / architecture

- Existing `RoutineCreateCommand` requires a concrete `Routine(programId)`; `RoutineCreateController`, `CreateRoutinePage`, `RoutinePendingCreateGate` and `shell_route.dart` are ProgramId-bound. They are **not** safe to point to a synthetic default ID.
- Existing `SupabaseRoutineCreateRepository.create` uses `create_user_workout_routine_with_composition` and returns integer revision 1. Preserve that API.
- Hosted `create_user_workout_routine_in_my_program` returns `jsonb {program_id,composition_revision}`; `authenticated` EXECUTE is still **false**, so this adapter is staged only.
- Authenticated owner verification before/after network, frozen Routine/entry/set/mutation IDs, reusable composition payload encoder, known definite SQL rejection versus unknown network/5xx, and no fallback metadata writes remain mandatory.
- New typed command may validate via existing `RoutineCompositionSave`, not a second exercise/set validation implementation. New result must not infer default identity from display name.
- The eventual Library UI will reuse existing Create composer, not add a parallel form; separate owner-bound pending/UNKNOWN resolution and default marker projection must be validated first.

## Acceptance for this slice

- [ ] Valid request invokes only `create_user_workout_routine_in_my_program` once, omits `p_program_id`, uses exactly immutable IDs and existing payload codec; validates result Program UUID and integer revision 1.
- [ ] Empty name/exercise and duplicate composition identities reject before I/O; composition UUID/Set identity validation uses existing RoutineCompositionSave; owner/active Custom type is validated atomically by the existing server composer.
- [ ] Signed-out call fails before I/O; owner transition after ACK produces UNKNOWN, never success; definite SQL/Auth 4xx rejection remains definite even after owner switch.
- [ ] Network timeout/5xx/malformed 2xx remains UNKNOWN with no silent retry or additional write.
- [ ] Existing explicit Program Create API/tests unchanged; no runtime or release path consumes the new adapter in this slice.
- [ ] PR includes exact review gates and truthful validation/QA limitations.

## Non-goals / risks

- No live write fixture, execute grants or schema migrations.
- No Default Program constructed at UI entry or via direct client INSERT.
- Do not claim that adapter PR means direct Library Create feature is done; separate programless command/pending read-back and UI activation remain.
