# Pre-P9 — Current Supabase public schema inventory reconciliation

**Status:** Validated — bounded docs-only PR #584 squash-merged on 2026-10-17 (`7f5f49eb`); archived 2026-10-20
**Primary owner:** Repository documentation governance / Supabase data documentation
**Affected platforms:** Canonical database inventory only; no app, wearable, web, server or database behavior change

**Archive disposition (2026-10-20):** This is a completed **2026-10-17 documentation snapshot**, not the current implementation handoff. [PR #584](https://github.com/im-tnyx/tio-world/pull/584) is verified merged at `7f5f49ebdd7c699fc1977931e15fad65ee427324`. Historical statements below about Draft PR, pending CI/review, next action or an earlier `main`/migration count belong to the pre-merge checkpoint and **must not be executed**. Current database/runtime and the canonical [docs/data/SUPABASE_SCHEMA.md](../../docs/data/SUPABASE_SCHEMA.md) require new source/live verification; broader GitHub [#250](https://github.com/im-tnyx/tio-world/issues/250) / Linear [TNYX-193](https://linear.app/tnyx/issue/TNYX-193) remain open. This archive does not close new Routine Move or pending migration work.

## Authorization and boundary

**Owner trigger:** `Go next with audit` on 2026-10-17 after GitHub PR #583 merged, continuing the explicitly open canonical-contradiction acceptance of [GitHub #250](https://github.com/im-tnyx/tio-world/issues/250) / Linear TNYX-193. This is one pre-P9 documentation status slice, not a new P4B phase, schema approval or permission to alter database objects.

**Approved scope:** Update [`docs/data/SUPABASE_SCHEMA.md`](../../docs/data/SUPABASE_SCHEMA.md) from verified checked-in migrations and *read-only* live `public` catalog for current columns/constraints/functions and historical snapshot notes. Index this brief in `.ai/tasks/README.md`.

**Out of scope:** SQL migration, data write, RLS/grant/function change, Supabase deployment, Flutter or watch code, `docs/data/SUPABASE_STRATEGY.md` (separately stale current-status prose), other `.ai/tasks/` drift, broad canonical acceptance, P9 routing map, release/device QA and branch cleanup. Do not include production/user rows, row counts, secrets or personal identifiers in the inventory.

## Discovery and verified evidence

- Verified protected GitHub `main@fe065ebd712a9a02b91567ce75aa95214cb0373a`, root `AGENTS.md`, `.ai/workflow.md`, docs authority, GitHub #250 Open with final contradiction criterion unchecked, and Linear TNYX-193 In Progress. No open PR before this isolated branch.
- Checked-in `supabase/migrations/`: **62 SQL migrations**. Connected *tio-world* Supabase's read-only migration ledger: **62 applied**, exact 62/62 alignment by version **and** name, latest `20261016220000_prevent_deleted_routine_resurrection`. Seven new migrations after the former 2026-10-11 55/55 snapshot. No database mutation.
- Read-only `pg_catalog` queries: **19 ordinary `public` tables, 190 columns, 19 primary keys, 21 foreign keys, 10 unique constraints, 77 CHECK constraints, 2 constraint-trigger records, 129 total constraints, 54 indexes and 19/19 RLS-enabled tables**, no public partitioned tables, views or materialized views.
- Matched all 19 documented table names, pre-existing 185 columns, 123 named constraints and 54 index names against live catalog. Exactly five new columns: `user_workout_routines.last_routine_update_request_hash bytea NULL` plus `user_workout_routine_sets.set_type text NOT NULL DEFAULT 'normal'`, `reps_max integer NULL`, `distance_meters double precision NULL`, `duration_seconds integer NULL`. Old `sets.reps integer` changed to nullable. One existing `secondary_muscles` type render (`ARRAY (text[])` vs `text[]`) is formatting, not a semantic database difference.
- Exactly six new CHECK constraints: `user_workout_routines_update_hash_length`; `user_workout_routine_sets_distance_nonnegative_finite`, `duration_nonnegative`, `max_eight_position`, `reps_max_valid`, `set_type_allowed`. **`max_eight_position` remains `NOT VALID` / `convalidated=false`**; the others are validated. Do not describe all six as validated.
- Verified live public Routine Create (five-argument), Save (four-argument), atomic Name+composition Update (seven-argument), Delete (three-argument) RPC signatures. All four use SECURITY DEFINER, empty search_path, `authenticated` EXECUTE only; no `anon` / `PUBLIC` EXECUTE. `authenticated` still has no direct table-level INSERT/UPDATE/DELETE on Routine or child tables; metadata `name` column UPDATE is allowed, direct revision/hash UPDATE forbidden, and Routine children are SELECT-only. This is privilege observation, **not** proof that business-path mutation tests were executed.
- Latest anti-resurrection migration adds a **private** deleted-Routine ID tombstone table (not part of this `public`-only inventory); no public table is added. App-facing Routine Delete and product acceptance/release remain separate from database RPC existence.
- Verified historical 2026-10-11 inventory remains factually valid *for that date* but cannot be labeled the current schema on 2026-10-17.

## Active handoff

**Planning owner:** GitHub #250 / Linear TNYX-193
**Implementation owner:** This isolated GitHub-connected docs-only branch; no local Windows checkout
**Review owner:** Manual exact-head docs/SQL/catalog diff review; independent/Codex review when available, without treating usage limits as approvals
**Base:** Protected `main@fe065ebd712a9a02b91567ce75aa95214cb0373a`
**Branch:** `docs/pre-p9-supabase-schema-inventory`
**Validation completed:** Read-only SQL catalog/migration queries and file-to-live structural diff listed above; no real schema/row mutation.
**Validation remaining:** Exact final-head changed-path/patch/relative-link audit, doc-vs-live column/constraint/index inventory verification, required attribution check, review threads and separate `Go merge`.
**Current blocker:** None in read-only structural audit; merge gate not yet run.
**Next action:** Make the bounded factual inventory correction, run post-change structural comparison and review, open Draft PR; do not merge without owner instruction.
