# TNYX-193 P4A — Documentation Location Normalization

**Status:** In progress
**Primary owner:** repository documentation governance
**Affected platforms:** documentation only

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Approved
**Approval evidence:** Owner said "Go start kare work / Follow agent.md" after the P4A read-only audit and taxonomy discussion.
**Approved product/UI/data-shape boundaries:** Documentation-only ownership/location normalization.
**Explicit non-changes:** No runtime/UI behavior, no Supabase schema/migration/RLS/index/storage/function/Auth mutation, no P4B schema inventory content, no P5/P6 header rollout, no P7 CURRENT refresh, no speculative connector/backend implementation.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** independent exact-head reviewer after implementation
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main@1e22f623454b85b432aa2ea0dedcc6d31a90d9ba`; GitHub #250 open; Linear TNYX-193 In Progress; no open PRs at activation.
**Branch:** `tnyx/tnyx-193-p4a-doc-location-normalization`
**HEAD SHA:** exact validation checkpoint `2519d6f4a2e06328ccc94dbc7d63e48c7df9a101`; this final handoff-metadata update is docs-only, so the resulting head must be revalidated before Codex review
**Observed working-tree state:** Connector/API execution only; no local worktree claim.
**Observed uncommitted/dirty files:** Not applicable through connector/API.
**PR / tracker:** GitHub #250 / PR #412 open / Linear TNYX-193 `In Review`.
**Current implementation state:** P4A relocation implementation complete and PR #412 is open for review: 29 approved moves are present, repository references were updated, `docs/README.md` carries the ownership taxonomy, and no runtime/Supabase/CI/lockfile net diff remains.
**Relevant execution surface:** canonical `docs/`, repository workflow docs, repository references, focused `.ai/tasks` handoff.
**Validation completed at SHA:** `2519d6f4a2e06328ccc94dbc7d63e48c7df9a101`: exact base/merge-base `main@1e22f623454b85b432aa2ea0dedcc6d31a90d9ba`; 111 ahead / 0 behind; 29/29 approved final paths present; 0 old canonical paths; 279 changed Markdown link refs / 74 unique targets with 0 missing; exact patch scan 0 trailing whitespace / 0 conflict markers / 0 missing-final-newline markers; `apps/**`, `services/**`, `supabase/**`, `.github/workflows/**`, and lockfiles all 0 net diff; `docs/status/` and `docs/integrations/` absent.
**Validation remaining:** revalidate only the resulting handoff-metadata head, update PR #412 with that final SHA/evidence, inspect repository checks, and obtain independent Codex exact-head review.
**Current blocker:** none
**Open review finding IDs:** none
**Next exact action:** revalidate the resulting handoff-only head, update PR #412 with that exact SHA/evidence, then request Codex exact-head review.

## 1. Discovery

### User Outcome

Make Tio-world documentation easy to navigate by ownership so architecture, planning, mobile, wearables, data/Supabase, backend, security, development and future integrations do not remain mixed together at one flat `docs/` level.

### Success Criteria

- `docs/` has a stable ownership-based taxonomy.
- Every current top-level canonical document has an explicit final location.
- Clear-location docs are moved without duplicating canonical copies.
- Every affected repository reference resolves after the move.
- Live task/project status remains in Linear + linked GitHub; no `docs/status/`.
- P4B future schema inventory path is fixed at `docs/data/SUPABASE_SCHEMA.md`.
- Stale `.ai/` orientation content is recorded as drift, not promoted into canonical docs.

### Scope

- establish final ownership folders:
  - `docs/architecture/`
  - `docs/planning/`
  - `docs/mobile/`
  - `docs/wearables/`
  - `docs/data/`
  - `docs/backend/`
  - `docs/security/`
  - `docs/development/`
  - retain existing `docs/adr/`
  - retain existing `docs/screens/`
- reserve future `docs/integrations/` in documentation governance without creating an empty directory;
- move repository workflow/process docs to `.github/` where clearly owned there;
- update every affected repository reference atomically;
- update `docs/README.md` catalog for the new paths/taxonomy;
- record the move matrix and drift follow-ups in this handoff.

### Non-Goals

- no `docs/status/`;
- no P4B schema inventory body;
- no database/Supabase mutation;
- no connector implementation or empty integrations directory;
- no P5/P6 governance-header rollout;
- no P7 `.ai/CURRENT.md` refresh;
- no broad rewrite of stale `.ai/` content during relocation.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `apps/features/AGENTS.md`, `docs/README.md`, `.ai/README.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, current docs tree, GitHub #250, Linear TNYX-193.
- Existing pattern to follow: `docs/adr/` and `docs/screens/` already group canonical docs by durable ownership.
- Tests or validation already present: docs-only default is `git diff --check`; connector/API execution will use equivalent exact patch scan plus repository reference-integrity checks.

### Audit Findings

- Flat top-level `docs/` mixes architecture, planning, mobile, wearable, Supabase/data, backend/operations, security and development guides.
- `docs/POST_MERGE_SYNC.md` and `docs/PUSH_TEMPLATE.md` are repository workflow/process docs and belong under `.github/`.
- No dedicated canonical connector/ChatGPT integration doc currently exists in `docs/`; do not create an empty `integrations/` directory.
- `.ai/architecture-summary.md`, `.ai/project-context.md` and `.ai/supabase-rules.md` contain stale/current-boundary drift; relocation is not the correct fix because `.ai/` is already their execution/orientation owner and promoting stale text into `docs/` would duplicate canonical truth.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Use ownership-based folders inside `docs/` | Approved | User explicitly wants planning/mobile/watch/backend/connector-style organization. | Owner |
| Create `docs/status/` | Rejected | Live task/phase/blocker/review state belongs to Linear + linked GitHub; duplicate status docs would drift. | P4 governance |
| Materialize `docs/integrations/` now | Rejected | No real canonical integration doc exists yet; do not scaffold empty speculative folders. | P4A |
| P4B schema inventory path | Approved | Data/Supabase ownership fits `docs/data/SUPABASE_SCHEMA.md`. | P4A |
| Rewrite stale `.ai/` orientation content in P4A | Deferred | Content drift is real but is distinct from document-location normalization. | Follow-up |

## 4. Architecture Design

### Chosen Approach

Classify by durable ownership, not by filename age or current implementation status. Keep one canonical copy only. Move files with clear ownership and update references in the same P4A PR.

### Move Matrix

| Current path | Final path | Class / owner | Decision |
|---|---|---|---|
| `docs/ARCHITECTURE.md` | `docs/architecture/ARCHITECTURE.md` | canonical architecture | Approved |
| `docs/MODULE_OWNERSHIP.md` | `docs/architecture/MODULE_OWNERSHIP.md` | canonical architecture/ownership | Approved |
| `docs/ONBOARDING_ARCHITECTURE.md` | `docs/architecture/ONBOARDING_ARCHITECTURE.md` | canonical architecture | Approved |
| `docs/UX_UI_SYSTEM.md` | `docs/architecture/UX_UI_SYSTEM.md` | cross-platform UI architecture/policy | Approved |
| `docs/ROADMAP.md` | `docs/planning/ROADMAP.md` | durable planning | Approved |
| `docs/MVP_ACCEPTANCE.md` | `docs/planning/MVP_ACCEPTANCE.md` | durable acceptance planning | Approved |
| `docs/FEATURE_ROLLOUT.md` | `docs/planning/FEATURE_ROLLOUT.md` | rollout planning/policy | Approved |
| `docs/FLUTTER_MODULAR_STRUCTURE.md` | `docs/mobile/FLUTTER_MODULAR_STRUCTURE.md` | Flutter mobile architecture detail | Approved |
| `docs/WATCH_STRATEGY.md` | `docs/wearables/WATCH_STRATEGY.md` | Wear OS/watchOS strategy | Approved |
| `docs/DATA_AND_SYNC.md` | `docs/data/DATA_AND_SYNC.md` | canonical data/sync | Approved |
| `docs/SUPABASE_STRATEGY.md` | `docs/data/SUPABASE_STRATEGY.md` | Supabase/data platform | Approved |
| `docs/SUPABASE_RUNTIME_CONFIG.md` | `docs/data/SUPABASE_RUNTIME_CONFIG.md` | Supabase runtime config | Approved |
| `docs/SUPABASE_SERVER_ACCESS.md` | `docs/data/SUPABASE_SERVER_ACCESS.md` | Supabase access boundary | Approved |
| `docs/DATABASE_BACKUP_RECOVERY.md` | `docs/data/DATABASE_BACKUP_RECOVERY.md` | database operations/data durability | Approved |
| `docs/API_LIFECYCLE.md` | `docs/backend/API_LIFECYCLE.md` | protected API lifecycle | Approved |
| `docs/ASYNC_RELIABILITY.md` | `docs/backend/ASYNC_RELIABILITY.md` | backend async reliability | Approved |
| `docs/DEPLOYMENT_AND_ROLLBACK.md` | `docs/backend/DEPLOYMENT_AND_ROLLBACK.md` | backend/platform delivery | Approved |
| `docs/OBSERVABILITY.md` | `docs/backend/OBSERVABILITY.md` | backend/platform observability | Approved |
| `docs/QUEUE_STRATEGY.md` | `docs/backend/QUEUE_STRATEGY.md` | async/backend queue policy | Approved |
| `docs/SCALING_READINESS.md` | `docs/backend/SCALING_READINESS.md` | backend/platform scaling | Approved |
| `docs/WORKER_ARCHITECTURE.md` | `docs/backend/WORKER_ARCHITECTURE.md` | worker/backend architecture | Approved |
| `docs/AUTH_ARCHITECTURE.md` | `docs/security/AUTH_ARCHITECTURE.md` | identity/security architecture | Approved |
| `docs/SECURITY.md` | `docs/security/SECURITY.md` | security policy | Approved |
| `docs/DATA_PRIVACY_GOVERNANCE.md` | `docs/security/DATA_PRIVACY_GOVERNANCE.md` | privacy governance | Approved |
| `docs/SECRETS_AND_ENVIRONMENTS.md` | `docs/security/SECRETS_AND_ENVIRONMENTS.md` | secrets/environment security | Approved |
| `docs/DEVELOPMENT_SETUP.md` | `docs/development/DEVELOPMENT_SETUP.md` | developer workflow | Approved |
| `docs/TESTING_GUIDE.md` | `docs/development/TESTING_GUIDE.md` | developer/testing workflow | Approved |
| `docs/POST_MERGE_SYNC.md` | `.github/POST_MERGE_SYNC.md` | repository workflow | Approved |
| `docs/PUSH_TEMPLATE.md` | `.github/PUSH_TEMPLATE.md` | repository push/PR workflow | Approved |
| `docs/README.md` | unchanged | documentation catalog/governance entrypoint | Keep |
| `docs/adr/**` | unchanged | ADR ownership | Keep |
| `docs/screens/**` | unchanged | screen/product-spec ownership | Keep |
| root `README.md`, `CONTRIBUTING.md`, `AGENTS.md` | unchanged | repository entry/governance | Keep |
| `apps/**/README.md`, nested `AGENTS.md` | unchanged | module-local ownership | Keep |
| `.ai/**` | unchanged location | execution/routing/handoff | Keep; stale-content follow-up |

### Ownership and Data Flow

```text
runtime/source/config/migrations -> actual behavior truth
docs/<owner>/                  -> durable canonical documentation
Linear + linked GitHub        -> live task/phase/status truth
.ai/                          -> active execution/routing/handoff
```

### Alternative Rejected

Keeping all canonical docs flat under `docs/` was rejected because it does not meet the owner's navigation/management goal and makes unrelated ownership domains harder to distinguish.

## 5. Implementation Plan

- [x] reconcile GitHub #250 / Linear TNYX-193 / main / open PR state;
- [x] complete read-only P4A audit;
- [x] lock taxonomy and move matrix;
- [x] create/move canonical files to approved final paths;
- [x] update all affected relative/absolute repository references;
- [x] update `docs/README.md` catalog/taxonomy;
- [x] verify old canonical paths are absent and no duplicate copies remain;
- [x] run moved-path holder coverage plus changed-Markdown-link target integrity at the exact source-validation head;
- [x] run exact patch scan / docs-only scope checks;
- [x] open bounded P4A PR (#412);
- [ ] obtain independent Codex exact-head review.

## 6. Quality Review

### Validation Run

```text
Latest full validation checkpoint: 2519d6f4a2e06328ccc94dbc7d63e48c7df9a101
Base / merge base: main@1e22f623454b85b432aa2ea0dedcc6d31a90d9ba
Ahead / behind: 111 / 0
Net files: 111 = 29 renamed + 1 added task brief + 81 modified reference/catalog files
Approved final paths: 29/29 present
Old canonical paths: 0 remaining
Changed Markdown link targets: 279 refs / 74 unique targets / 0 missing
Moved-path baseline holder verification: all active holders reconciled; one old path string intentionally remains only in the byte-identical historical Supabase migration comment
Patch scan: 0 trailing whitespace / 0 conflict markers / 0 missing-final-newline markers
Out-of-scope net diff: apps 0 / services 0 / supabase 0 / .github/workflows 0 / lockfiles 0
docs/status: absent
docs/integrations: absent (future destination only)
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| P4A-AUDIT-01 | Follow-up | Deferred | Several top-level `.ai/` orientation files contain stale Supabase/backend/current-state wording. | `1e22f623454b85b432aa2ea0dedcc6d31a90d9ba` | Keep location unchanged in P4A; reconcile content in a separately bounded follow-up/P7-adjacent governance slice rather than promoting stale duplicate truth. |
| P4A-VAL-01 | Info | Accepted | Historical migration `supabase/migrations/20260903052101_reconcile_legacy_lineage_state.sql` contains the old `docs/DATABASE_BACKUP_RECOVERY.md` text reference. | `c2dd606e83f50a90feb0c432b8819a0197a443ab` | Preserve the applied historical migration byte-for-byte; P4A does not mutate migration history. The canonical document itself moved to `docs/data/DATABASE_BACKUP_RECOVERY.md`, and net `supabase/**` diff is 0. |

## 7. Final Handoff

### Changed Files

At source-validation head: 111 net paths, including 29 approved renames, the focused P4A task brief, and reference/catalog updates. No net changes under `apps/**`, `services/**`, `supabase/**`, `.github/workflows/**`, or lockfiles.

### Actual Behavior

Documentation ownership/location normalization only. Canonical product/architecture docs now live under ownership-based `docs/` folders, repository workflow docs live under `.github/`, and P4B's future schema inventory path is fixed at `docs/data/SUPABASE_SCHEMA.md`. No runtime or database behavior changes.

### Known Limitations

P4B schema inventory, P5/P6 headers and P7 CURRENT refresh remain separately gated.

### Final Status

`REVIEW`
