# GitHub #538 + #539 — Routine Set metadata DB compatibility (DB-only)

**Status:** In progress, OWNER APPROVED 2026-10-13; Draft DB-only implementation planned; NO production deploy/merge.
**Implementation owner:** This connected GitHub session, exclusively on `tnyx/issues-538-539-routine-set-metadata-db`; unrelated Draft #533 Edit, #536 atomic Create, and #537 Create UI retain their existing owners. No local worktree available; remote GitHub source state must be verified.
**Planning owner:** Tio-world architecture; **review:** separate independent reviewer.
**Branch origin:** `main@ee5ed4cc67bfb6c8d3eb867129578201b60703bc`; main must be refreshed before merge. Issues [#538](https://github.com/im-tnyx/tio-world/issues/538), [#539](https://github.com/im-tnyx/tio-world/issues/539). Broad Linear TNYX-81 stays Backlog and blocked by TNYX-78/80.

## Approval and exact scope
- Owner explicitly replied **Go** to the question approving *both* proposed Supabase column changes and related Create/Edit persistence changes. Production Supabase deployment and merge require separate explicit authorization.
- **Approved physical shape:** one additive `public.user_workout_routine_sets.set_type text NOT NULL DEFAULT 'normal'` with CHECK `normal|warm_up|failure|drop`; one `reps_max integer NULL` with CHECK `reps_max IS NULL OR (reps_max >= reps AND reps_max > 0)`.
- Range: existing positive `reps` is Min if `reps_max` is present, otherwise exact Reps. Normal type is historical default. No extra mode/table/source; mode derives from Set rows and must be uniform per Routine Exercise.
- **DB-only current slice:** one additive migration upgrading the existing `save_user_workout_routine_composition(uuid,bigint,uuid,jsonb)` RPC with strict JSON validation, ordered deterministic normalized + persisted mutation replay, authorized owner access and legacy-client write guard. No changes to grants/RLS, existing Routine metadata-only create rights, or custom Exercise lifecycle. Add focused disposable SQL test matrix to workflow; DO NOT apply to hosted project.
- **Compatibility contract:** old clients sending sets without new keys may continue to save plain normal/fixed Routines. If a Routine already has enriched rows (non-normal type or ranged reps), reject unversioned old Edit snapshot writes rather than silently wiping metadata. Explicit newer clients include both new keys per Set; legacy empty composition replacing enriched data must reject fail-closed. Existing same-token replay remains stable. New Create RPC in separate PR #536 calls the existing Save function and remains compatible after deployment.
- **Post-DB separate slice:** Flutter canonical `SetPrescription`, serialization/readback and Create UI bottom sheets in a branch stacked after its dependencies. Do not change Draft #533/#536/#537 while their owners/reviews are active. No Wear/Watch/Workout performance/AI work.

## Audited truth
- Read root `AGENTS.md`, `apps/features/AGENTS.md`, Core theme README, active task index, canonical Supabase strategy, ADR-0015, current PRs/Issues/Linear, source migration `20261010061809_create_user_workout_routine_composition.sql` and SQL test `tnyx_509_routine_composition.test.sql`.
- Live project `oykupyiitspujzpwwvuj` ends at migration `20261010061809`; last hosted read confirms set table has `reps`, `load_kg`, `rest_seconds`, not the two requested columns. PR #536 migration `20261013080000` is not hosted.
- Under current full replacement RPC, old clients could otherwise erase ranged/type-specific saved values. Preserve locks, revision/token checks, RLS & no direct authenticated mutation privileges.
- This connector session has no Flutter/Dart/psql/Supabase CLI and no local repo worktree; use GitHub Actions CI for disposable DB replay, no unverified PASS claims.

## Required quality gates
- [ ] migration + SQL tests committed on dedicated branch
- [ ] exact-head `Supabase Database CI` migration replay, existing #509 test/concurrency and new enriched-set test PASS
- [ ] review successful SQL shape, RLS/no extra grants, old/new Create/Edit payloads, mutation replay/conflict and legacy write block
- [ ] independent GitHub review / Codex or human review
- [ ] merge gate separately approved
- [ ] hosted Supabase deployment separately approved (after dependency sequencing and mobile compatibility check)
- [ ] client domain/read/create/edit/UI implementation in follow-up owner slice, no premature client release

**Known limitation:** Replacing a rich Routine with a zero-Set snapshot is rejected because the current RPC has no explicit caller capability-version field; allowing it would let old clients wipe enriched data. A later dedicated operation may handle deliberate clearing. This is an intentional fail-closed compatibility policy, not a hidden data loss.

## Next action
Complete narrow migration + SQL regression, trigger/review CI, then reconcile issue/Linear handoff. Never call `db push` on production for this task without an explicit new owner instruction.
