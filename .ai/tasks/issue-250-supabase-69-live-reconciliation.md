# GitHub #250: Hosted Supabase 69/69 Canonical Doc Reconciliation

**Status:** In progress
**Primary owner:** `im-tnyx`
**Affected platforms:** Documentation only; Supabase metadata verification is read-only.

## Owner Approval and Scope Boundary

**Trigger:** None, bounded documentation follow-up under #250.
**Approval status:** Approved by user request on 2026-10-24 to start the next slice through PR review/merge gate, **not to merge**.
**Approved boundaries:** Correct `docs/data/SUPABASE_SCHEMA.md`, `docs/data/SUPABASE_STRATEGY.md` and this focused handoff/index using current GitHub checked-in migration source and hosted read-only metadata.
**Explicit non-changes:** No SQL/migration/RLS/RPC/ACL mutation; no Auth, Flutter, Wear, source code, CI, lockfile or release flag change; no P9 work; no closure of parent GitHub #250 or Linear TNYX-193.

## Active Handoff

**Planning owner:** GitHub #250 / Linear TNYX-193
**Implementation owner:** `im-tnyx` (GitHub-connected branch, one bounded implementation slice)
**Review owner:** `im-tio` requested GitHub review; separate connected account is not an independent human reviewer.
**Implementation ownership state:** Active; stop at merge gate.
**Ownership transition:** Not applicable.
**Repository state last verified:** Protected `main@0541735248964c72618ac081f2316119d7949a53` via GitHub API on 2026-10-24.
**Branch:** `docs/issue-250-supabase-69-live-reconciliation`
**HEAD SHA:** See live PR exact head.
**Observed working-tree state:** Local Windows working tree unavailable; do not claim clean local git.
**PR / tracker:** GitHub #250 Open; Linear TNYX-193 In Progress; #569 previous overlapping PR #662 already merged.
**Current implementation state:** Canonical docs correction based on independently read-only hosted metadata.
**Validation completed:** 69/69 exact migration version/name comparison, structural count and key RPC ACL checks from live linked project; source provider hard-false inspected. PR-native checks to be verified at exact head.
**Validation remaining:** Exact-head GitHub Docs Hygiene CI, required App-pinned attribution guard, complete patch/refs audit, independent review disposition.
**Current blocker:** Local `git diff --check` cannot run via connected GitHub-only session; use exact-head hosted Docs Hygiene CI, explicitly record distinction. Linear `get_agent_context` endpoint returned Tool not found; issue itself is readable.
**Open review finding IDs:** None at branch creation; reconcile live PR.
**Next exact action:** Review PR on exact head, resolve real findings in scope, verify CI, and stop before merge.

## Evidence

- Checked-in `supabase/migrations/` and linked hosted applied ledger: 69/69 exact version/name parity through `20261024090000_m5b_atomic_create_move_full_undo`.
- Hosted `pg_catalog`: 19 public ordinary tables, RLS 19/19, 194 columns, 130 constraints, 55 indexes.
- Program table has 3 new nullable UUID provenance columns and the coherent-provenance CHECK.
- `create_user_workout_program_and_move_routine`, `move_user_workout_routine`, and `undo_create_user_workout_program_and_move_routine` are present with `SECURITY DEFINER` and empty `search_path`, but EXECUTE=false for `PUBLIC`/`anon`/`authenticated`/`service_role`. The #568 first-Routine RPC is separately authenticated-executable.
- Flutter source `apps/app/lib/app/composition/workout_providers.dart` keeps `routineMoveReleaseEnabledProvider = false`.
- These observations do not prove production release, body-equivalence audit, real-write QA, or safety of issuing grants.

## Validation and Handoff

**Changed paths:** `docs/data/SUPABASE_SCHEMA.md`; `docs/data/SUPABASE_STRATEGY.md`; `.ai/tasks/README.md`; this task brief.
**Checks:** Host GitHub exact-head CI/review to be populated by live PR; local Windows git checks not available.
**Status boundary:** Stop before merge; parent #250 remains Open, TNYX-193 remains In Progress, P9 separately gated.
