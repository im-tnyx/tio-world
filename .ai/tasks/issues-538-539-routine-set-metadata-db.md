# GitHub #538 + #539 — Routine Set metadata DB compatibility (DB-only)

**Status:** DB-only source CI validated at `b7f33218`; Draft [PR #540](https://github.com/im-tnyx/tio-world/pull/540), independent review pending; NO production deploy/merge.
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
- [x] migration + SQL tests committed on dedicated branch
- [x] exact-source-head [Supabase Database CI #38386554297](https://github.com/im-tnyx/tio-world/actions/runs/38386554297) SUCCESS on `b7f33218`: full replay, existing #509 matrix/concurrency, #538/#539 new matrix, lint, attribution
- [ ] review successful SQL shape, RLS/no extra grants, old/new Create/Edit payloads, mutation replay/conflict and legacy write block
- [ ] independent GitHub review / Codex or human review ([@codex request](https://github.com/im-tnyx/tio-world/pull/540#issuecomment-6144021276) pending)
- [ ] merge gate separately approved
- [ ] hosted Supabase deployment separately approved (after dependency sequencing and mobile compatibility check)
- [ ] client domain/read/create/edit/UI implementation in follow-up owner slice, no premature client release

**Known limitation:** Replacing a rich Routine with a zero-Set snapshot is rejected because the current RPC has no explicit caller capability-version field; allowing it would let old clients wipe enriched data. A later dedicated operation may handle deliberate clearing. This is an intentional fail-closed compatibility policy, not a hidden data loss.

## Next action
Complete narrow migration + SQL regression, trigger/review CI, then reconcile issue/Linear handoff. Never call `db push` on production for this task without an explicit new owner instruction.

## Review handoff (2026-10-13)
- First migration CI run #38386089909 **FAILED** at migration SQL function parse because automated source editing expanded the regex `$'` token into unexpected suffix text. This was an authoring defect, **not** a hosted DB failure. Fixed source commit `b7f33218d7d6109d3f13a58959a1c2086e9e2808` removes duplicated fragment and restores strict metadata validation.
- **Verified exact-source CI** #38386554297 **SUCCESS**: migration replay from clean DB, ledger, old TNYX-509 matrix, new four Set Types and Rep Range SQL test, old-client rich data protection, same-token mutation replay, RLS, two-session concurrency, DB lint, attribution. Flutter/physical-device tests were not run. 
- New documentation-only commits after this checkpoint need their own head/attribution verification. Do not mistake passing DB source checks for approved production deployment, human review or a validated Flutter app.
- **Next owner boundary:** DB implementation complete at CI source SHA, **handoff for independent review**. Implement app domain/read/write and Workout UI only in a distinct child PR/ownership slice; do not alter Draft #533/#536/#537 directly. Merge and Supabase apply both separately gated.

## Owner-approved nullable Routine Set measurements (2026-10-14)

Owner explicitly approved DB shape: existing `reps` becomes nullable positive-if-present, existing `load_kg` stays nullable, new `distance_meters` (nullable finite/nonnegative double precision) and `duration_seconds` (nullable nonnegative int32). No fake targets or extra tables. Work only on existing Draft #540 migration `20261013120000` (not deployed) and its disposable SQL tests. Earlier #536 `20261013080000` enforces >=1 Set per Exercise and keeps its original schema; its Create RPC calls the Save writer and therefore can accept nullable targets after #540. Preserve revision and mutation idempotency, owner/RLS/grants, strict payload validation and old-client guard against silently erasing rich rows. An all-empty Rep Range cannot be inferred from nullable `reps_max` alone; do not invent an unapproved extra mode column or claim this one scenario works until a separate decision.

Current connected session owns only this bounded DB slice on its original PR #540 branch; its earlier review source/CI status is preserved. Exact-head #540 DB CI and separate combined #536 → #540 replay (not implied by two independent CIs) are required before any release. No new PR, forced history rewrite, hosted deployment or merge.


## Owner 8-Set per Exercise policy (2026-10-14)

The owner requested a practical maximum of 6–8 Sets; use **8 Sets per individual identified Routine Exercise** (not 8 per whole Routine). PR #551 owns Flutter Create/Edit button state and controller ID-allocation guards. This PR #540 owns the durable cardinality enforcement because the existing Set table uses zero-based positions and a unique per-exercise position key: append `CHECK (position < 8) NOT VALID`. The combined #535/#540 test proves exactly 8 Saves; 9th Set via Save and atomic Create both fail with SQLSTATE 23514 and transaction rollback; the existing snapshot stays unmodified. `NOT VALID` preserves preexisting >8 Sets without dropping historical rows; an Edit of an old >8-Set snapshot must reduce to <=8 before another full-snapshot Save. No new service, RLS, table/column shape, or privileged grant. Requires exact-head DB CI and independent rollout/security compatibility review; no hosted DB migration or merge is implied.

## Main reconciliation checkpoint — 2026-10-14 (merge validation pending)

PRs #533 and #536 are merged into `main`; #537 merged into its
stack parent, not directly to `main`. Database #540 stays separate.
Reconcile #540 using a non-forced merge commit with current main as an
explicit parent, preserving its schema migration and SQL tests while
taking current main's already-merged #536 migration/tests. The
`.github/workflows/supabase-db-ci.yml` now uses current main's native
atomic Create SQL/race jobs plus always-on #538/#539 and combined #535/#540
SQL jobs. Removed obsolete pinned temporary #536 checkout/staging, so
CI runs consistently on `pull_request` and `workflow_dispatch` after
merge. No hosted Supabase deploy. Exact-head CI, independent security
review, old-client rollout sequencing and live DB compatibility gates
still required before merge/apply.

## Main-replay SQL regression resolved (2026-10-14, CI rerun pending)

After non-forced merge reconciliation with `main`, exact-head Supabase
Database CI #38578625574 failed inside the historical TNYX-509 SQL matrix.
The obsolete baseline test tried to insert 350 newly written Sets into
one Exercise, contrary to the newly approved 8-Set per-Exercise CHECK.
This was a real regression-test contract conflict, **not** proof that the
new constraint should be removed. Preserve payload-size/multi-entry
stress by rewriting that single fixture to 44 Exercise entries with
8 newly written Sets each (352 total), and assert both the full count
and no entry over eight. Dedicated #540 combined tests still assert that
a ninth Set fails transactionally for Save and atomic Create. Keep the
production SQL constraint unchanged; require a new full exact-head
database run to confirm the updated legacy matrix and new matrices.

## Large-snapshot fixture identity correction (2026-10-14; CI pending)

The updated TNYX-509 test failed again on #540 CI #38579448754
(`duplicate_routine_set`): a non-correlated nested SQL aggregation had
reused the same eight `gen_random_uuid()` Set IDs in all 44 entries.
Make each Set ID deterministic and distinct from the outer Exercise
index plus inner Set index, using a v4-shaped test UUID. Keep the 44x8
stress and production 8-Set CHECK unchanged. Re-run full database CI.

## Rich-overwrite guard fixture isolation (2026-10-14, CI pending)

#540 exact-head database CI #38580154770 passed TNYX-509 after the
unique Set ID repair, then failed the new combined SQL matrix at the
eight-Set positive case with `routine_composition_legacy_rich_set_overwrite`.
The matrix had reused its first Routine containing rich KM/TIME Sets for
a new full-snapshot replacement that dropped those measurements. This
is a **correct fail-closed data-integrity guard**, not a schema failure.
Move only the 8/9-Set Save cases into a separate ordinary atomic-created
Routine with distinct stable IDs, leaving the original rich/nullable
Routine and its preservation tests intact. Production RPC, RLS, CHECK,
and legacy-overwrite protection remain untouched. Full exact-head CI
must pass before any merge decision; no hosted DB deployment.
