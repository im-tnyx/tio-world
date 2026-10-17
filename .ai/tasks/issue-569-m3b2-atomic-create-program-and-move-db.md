# #569 M3B2 — Atomic Create Program and Move Routine (DB only)

**Status:** [PR #599](https://github.com/im-tnyx/tio-world/pull/599) is the single canonical review surface. Live GitHub determines Draft/Ready/review status; exact-head disposable database CI and merge gate require verified completion. **Do not merge**.
**Primary owner:** Supabase/Postgres; follow-on Flutter selector is a separate bounded slice.
**Affected surface:** `supabase/migrations/`, `supabase/tests/database/`, `.github/workflows/supabase-db-ci.yml`, this handoff and task index.
**Owner approval:** Existing GitHub #569 owner-approved 2026-10-17 `+ New Program → canonical Create Program name editor → Create & Move` flow; no new independent feature. No new table/column shape or unapproved visible UX proposed.
**Source of truth:** root `AGENTS.md`, `.ai/FEATURE_DEVELOPMENT.md`, ADR-0015, `docs/screens/programs.md`, `docs/screens/routine-library.md`, `supabase/migrations/20261017100000_move_user_workout_routine_between_owned_programs.sql`, GitHub #569/#568, Linear TNYX-81/TNYX-267.

## Preflight / actual runtime

- Protected `main@0898fadf7d5e7bac5ed84c8b3f0dfd4000108fcf`; #597 controller and #598 dormant selector squash-MERGED. Post-merge main Flutter CI #39064167585 SUCCESS.
- Canonical `ProgramsController.suggestedName()` supplies generated editable `Program N`, and `_CreateProgramSheet` persists with `ProgramRepository.create`, a **separate** Program INSERT. Calling existing Move RPC afterwards is **not atomic** and may strand an empty Program on failure/unknown.
- `user_workout_programs` has only `id/user_id/name/created_at/updated_at`, Program INSERT/owner policy currently available to authenticated; no canonical default Program marker is present (#568 is separate). Routine has stable owner/source/UUID, composition revision/token/hash and children keyed by Routine UUID. Protected existing-Program Move RPC already defines lock order, CAS, replay and direct UPDATE denial.
- Hosted Supabase has 64 migrations and no atomic `Create+Move` RPC at audit. Current existing Program Move `EXECUTE` and authenticated direct Routine `UPDATE(program_id)` are denied. No direct hosted mutation or release in this slice.

## Chosen architecture

Add **one dormant SECDEF RPC** `public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid) returns bigint`.

- Client supplies **stable** new ProgramId and mutation UUID, source Routine/Program identity, owner-edited Program name and frozen expected revision. The later Flutter adapter must hold these across uncertain outcomes, never allocate a second Program ID/token automatically, and verify current login-cycle before dispatch.
- Server validates `auth.uid()`, non-null UUIDs, nonblank Unicode-trimmed name, different source/new Program IDs, supported READ COMMITTED isolation, owner account/source Program/Routine locks (consistent account → source Program → UUID → Routine lock order).
- On fresh attempt, rejects wrong owner, foreign IDs, stale revision and reused Program UUID before a single transaction inserts `user_workout_programs` and updates **the same Routine row** with protected revision+mutation hash. Existing Exercise/Set IDs/prescriptions are unchanged. Any rejection rolls back Program INSERT.
- Exact same-request replay is accepted only while the Routine's latest mutation hash, revision and destination identity still prove the original atomic commit. Later Routine Edit/Move invalidates the replay. Destination's later display-name rename does not revoke a genuine immutable request proof.
- Canonical migration: `20261018100000_atomic_create_program_and_move_routine.sql`. A parallel duplicate SQL function/migration was detected on the same branch and is removed before PR to preserve one backend authority. No new table, column, Program identity model, separate service, direct client `UPDATE(program_id)`, or schema-wide grant. The function explicitly revokes `EXECUTE` from PUBLIC/anon/authenticated/service_role and remains **dormant** after merge.
- **Rejected:** create Program via `ProgramRepository.create()` and call the existing Move RPC in a second network transaction; this cannot guarantee no empty Program/unknown-result duplication.

## Validation / review gates

1. Disposable GitHub Supabase Database CI must replay all migrations from scratch, execute `tnyx_569_atomic_create_program_move.test.sql`, `tnyx_569_atomic_create_program_move_concurrency.sh` (restricted to exact CI Postgres), and existing owner Move/Delete/Create matrices and lint/privilege guards.
2. SQL cases include successful atomic create+reparent, stable Routine/Exercise/Set identity, denied/null/blank/foreign request, old revision, Program UUID collision, a deliberately rejected Routine UPDATE **after** Program INSERT with rollback and unchanged children, failed-request zero new Programs, exact idempotent replay, changed mutation name and after-later-Move invalidation. Two-session CI harness asserts one winning Create+Move, losing stale Create+Move, an observed lock wait, and zero orphan destination; review may require additional Delete/duplicate-id races.
3. Security review checks routine/account ownership, RLS / FK integrity, lock order and race outcomes, no public function EXECUTE, correct empty `search_path`, no role capability broadening. Existing Supabase Security Advisor warnings separately baseline, not automatically cleared.
4. GitHub exact-head CI and required attribution checks PASS, independent review / inline P1-P2 findings resolved. Merge requires explicit owner `Go merge`. **Current user instruction: DO NOT MERGE**.
5. After independently gated merge, any live migration rollout still requires owner-controlled Supabase CLI dry-run and hosted ledger verification. Flutter `+ New Program`, canonical editor reuse, Create & Move confirmation, empty destinations, auth/unknown/list refresh, #568 My Program, app-shell wiring, client EXECUTE grant and physical device QA remain separate activation gates.

**Execution context:** GitHub connector remote branch; owner Windows checkout not accessible. No `git status`, local Postgres/Docker/Flutter invocation, migration CLI generation or database replay claimed. Hosted Supabase read-only inspection only.

**Next exact action:** continue **existing Draft PR #599**, avoid competing branches/migrations, run disposable DB CI and review threaded findings, reconcile source/SQL/test/handoff on exact HEAD, then advance to owner merge gate **without merging**. No hosted deployment or grant. A parallel duplicate migration with the same version was detected and removed in the branch; source of truth is the single `20261018100000_atomic_create_program_and_move_routine.sql`.
