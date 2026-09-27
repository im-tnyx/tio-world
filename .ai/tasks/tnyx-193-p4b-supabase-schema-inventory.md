# TNYX-193 P4B — Supabase Public Schema Inventory

**Status:** In progress
**Primary owner:** repository documentation governance + Supabase data ownership
**Affected platforms:** documentation only

## Owner Approval and Scope Boundary

**Trigger:** None — docs-only execution inside the separately gated TNYX-193 P4B phase
**Approval status:** Approved
**Approval evidence:** Owner said `Go` after the P4B read-only audit.
**Approved product/UI/data-shape boundaries:** Create the canonical readable current `public` schema inventory at `docs/data/SUPABASE_SCHEMA.md` from checked-in migrations plus verified live Supabase metadata.
**Explicit non-changes:** No Supabase DDL/DML, migration, RLS/policy, grant, Storage, Auth, Edge Function, runtime, UI, CI workflow, lockfile, P5/P6 header rollout, P7 `.ai/CURRENT.md` refresh, or unrelated stale-doc correction.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** independent exact-head reviewer after implementation
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main@5faa41472be7fc2ad1fda88b637e566fb3ef7465`; GitHub #250 open; Linear TNYX-193 `In Progress`; P4B tracker state `Not started` before activation.
**Branch:** `tnyx/tnyx-193-p4b-supabase-schema-inventory`
**HEAD SHA:** source-validation checkpoint `bd6283b48e221eb518ec8100cd7859fa2172213b`; this handoff refresh creates one final docs-only metadata commit that must be revalidated
**Observed working-tree state:** Connector/API execution only; no local worktree claim.
**Observed uncommitted/dirty files:** Not applicable through connector/API.
**PR / tracker:** GitHub #250 / Linear TNYX-193
**Current implementation state:** P4B source implementation complete: canonical schema inventory added and `docs/README.md` catalog updated; exact-head PR/review gates remain.
**Relevant execution surface:** `docs/data/SUPABASE_SCHEMA.md`, `docs/README.md`, focused `.ai/tasks` handoff/index.
**Validation completed at SHA:** source-validation checkpoint `bd6283b48e221eb518ec8100cd7859fa2172213b`: 4 ahead / 0 behind from `main@5faa41472be7fc2ad1fda88b637e566fb3ef7465`; exactly 4 docs/governance paths; 49 live migrations = 49 checked-in by version/name; inventory covers 14/14 tables, 147/147 columns, 88/88 live constraints and 39/39 indexes; 14/14 RLS enabled; 65 local Markdown refs checked with 0 missing; no row-count payload; patch scan 0 trailing whitespace / 0 conflict markers / 0 missing-final-newline markers; no `apps/**`, `services/**`, `supabase/**`, `.github/workflows/**`, or lockfile diff.
**Validation remaining:** revalidate the resulting handoff-only head, open bounded PR, inspect repository checks, obtain independent Codex exact-head review.
**Current blocker:** none
**Open review finding IDs:** none
**Next exact action:** revalidate the final handoff-only head, open the P4B PR, then request exact-head Codex review.

## 1. Discovery

### User Outcome

Provide one canonical, readable snapshot of the current Tio-world Supabase `public` schema so future agents and maintainers can understand the active database structure without reconstructing every migration, while keeping executable truth in migrations plus verified live schema.

### Success Criteria

- `docs/data/SUPABASE_SCHEMA.md` exists at the P4A-approved final location.
- It inventories every active `public` table and its columns/type/nullability/defaults.
- It records PK/FK/other constraints, indexes, and table RLS status.
- It includes no row counts, production/user data, secrets, or sample personal records.
- It explicitly states that checked-in `supabase/migrations/` plus verified live Supabase schema are executable/current truth.
- It states the inventory must be refreshed when schema migrations change the documented structure.
- No database/runtime behavior changes.

### Scope

- `docs/data/SUPABASE_SCHEMA.md`
- minimal `docs/README.md` catalog/reference update
- focused P4B task brief/index
- GitHub #250 / Linear TNYX-193 phase-state reconciliation

### Non-Goals

- no schema/RLS/policy/grant/function changes;
- no policy-by-policy security documentation beyond requested table RLS status;
- no row counts or user data;
- no unrelated correction of stale counts/prose in other docs;
- no P5/P6 governance-header rollout;
- no P7 execution-pointer refresh.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `docs/README.md`, `docs/data/SUPABASE_STRATEGY.md`, `docs/data/SUPABASE_SERVER_ACCESS.md`, `docs/data/DATABASE_BACKUP_RECOVERY.md`, GitHub #250, Linear TNYX-193, repository migration tree, and verified live Supabase structural metadata.
- Supabase project: `tio-world` / `oykupyiitspujzpwwvuj`, ACTIVE_HEALTHY.
- Migration parity: 49 live / 49 checked-in; no live-only or repo-only migration version+name.
- Current `public`: 14 ordinary tables, 147 columns, no partitioned tables/views/materialized views.
- All 14 active `public` tables report RLS enabled.
- Existing pattern: canonical Supabase/data docs live under `docs/data/`; P4A locked `docs/data/SUPABASE_SCHEMA.md`.
- Validation baseline: docs-only change requires exact patch/reference/scope validation rather than app build unless unexpected runtime scope appears.

### Audit Findings

- No existing canonical schema inventory or duplicate `SUPABASE_SCHEMA.md`.
- `docs/data/DATABASE_BACKUP_RECOVERY.md` contains a stale "24 applied migrations" statement while current verified migration count is 49.
- `docs/data/SUPABASE_STRATEGY.md` status prose still names older owner-table wording that is not the current 14-table schema.
- Those adjacent drift findings are not part of P4B and must not be silently bundled.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Inventory path is `docs/data/SUPABASE_SCHEMA.md` | Approved | Locked by P4A and current tracker. | TNYX-193 P4A |
| Derive from live metadata + checked-in migrations | Approved | Tracker explicitly requires both; Markdown is readable inventory, not executable truth. | TNYX-193 P4B |
| Include row counts or sample records | Rejected | Explicit P4B privacy/non-scope boundary. | Tracker |
| Document every RLS policy body | Rejected | P4B requires RLS status only; policy redesign/detail would widen scope. | P4B |
| Fix stale adjacent docs in same PR | Deferred | Separate factual-drift concern; preserve slice scope. | Follow-up |

## 4. Architecture Design

### Chosen Approach

Generate one human-readable structural snapshot organized table-by-table. Each table section records columns and structural database metadata while the document-level truth boundary explains how to resolve drift.

### Ownership and Data Flow

```text
supabase/migrations/ + verified live public schema
  -> structural metadata verification
  -> docs/data/SUPABASE_SCHEMA.md readable inventory
  -> future schema migration requires inventory refresh
```

### Alternative Rejected

Treating the Markdown inventory as database truth was rejected because it can drift; executable migration history and verified live schema remain authoritative.

### Failure and Accessibility States

Not applicable to runtime/UI. If live metadata and checked-in migrations disagree, implementation must stop and reconcile the discrepancy rather than publishing an averaged inventory.

## 5. Implementation Plan

- [x] query only live structural metadata required by P4B;
- [x] create `docs/data/SUPABASE_SCHEMA.md`;
- [x] add minimal catalog/reference entry in `docs/README.md`;
- [x] verify all 14 active tables and 147 columns are represented;
- [x] verify constraints, indexes and RLS status against live metadata;
- [x] verify no row counts/user data/secrets are present;
- [x] run exact docs-only diff/reference/scope validation;
- [ ] open bounded P4B PR and obtain independent exact-head review.

## 6. Quality Review

### Validation Run

```text
Source validation complete at `bd6283b48e221eb518ec8100cd7859fa2172213b`; final handoff-only head revalidation still required before review.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| P4B-AUDIT-01 | Follow-up | Deferred | DATABASE_BACKUP_RECOVERY.md says 24 applied migrations; verified current count is 49. | `5faa41472be7fc2ad1fda88b637e566fb3ef7465` | Separate bounded factual-drift cleanup; do not mix into schema inventory. |
| P4B-AUDIT-02 | Follow-up | Deferred | SUPABASE_STRATEGY.md status prose names older owner-table wording that is not the current schema. | `5faa41472be7fc2ad1fda88b637e566fb3ef7465` | Separate bounded factual-drift cleanup; inventory uses live schema + migrations instead. |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-193-p4b-supabase-schema-inventory.md`
- `docs/README.md`
- `docs/data/SUPABASE_SCHEMA.md`

### Actual Behavior

A canonical readable current `public` schema inventory now exists at `docs/data/SUPABASE_SCHEMA.md`, derived from verified live structural metadata and checked-in migration history. Runtime/database behavior is unchanged.

### Known Limitations

The inventory is a verified snapshot and must be refreshed after structural schema migrations.

### Final Status

`REVIEW`
