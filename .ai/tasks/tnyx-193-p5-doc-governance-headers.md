# TNYX-193 P5 — Documentation Governance Header Rollout

**Status:** In progress
**Primary owner:** repository documentation governance
**Affected platforms:** documentation only

## Owner Approval and Scope Boundary

**Trigger:** None — docs-only execution inside the separately gated TNYX-193 P5 phase
**Approval status:** Approved
**Approval evidence:** Owner said `Go next` after the P5 read-only audit.
**Approved product/UI/data-shape boundaries:** Roll out the canonical four-line governance header across every Markdown file under `docs/` after each document's status/owner/truth boundary is classified and its `Last Verified` value is evidence-backed.
**Explicit non-changes:** No runtime/UI/routing/state change; no Supabase schema/migration/RLS/storage/function/Auth mutation; no CI workflow change; no lockfile change; no P6 `.ai/` header rollout; no P7 `.ai/CURRENT.md` refresh; no P9 routing-map work.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** independent exact-head reviewer after each bounded slice
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main@aac56b3f0323ea4f5b8b0e5741ead815097f3da8`; prerequisite PR #416 merged; GitHub #250 open; Linear TNYX-193 restored to `In Progress`; P6/P7/P9 remain separately gated.
**Branch:** `tnyx/tnyx-193-p5-doc-governance-headers`
**HEAD SHA:** branch created from `main@aac56b3f0323ea4f5b8b0e5741ead815097f3da8`; header-rollout implementation commit pending
**Observed working-tree state:** Connector/API execution only; no local worktree claim.
**Observed uncommitted/dirty files:** Not applicable through connector/API.
**PR / tracker:** GitHub #250 / Linear TNYX-193; prerequisite PR #416 merged; header-rollout PR pending
**Current implementation state:** prerequisite factual-drift correction is merged. The 68-document classification is resolved and the four-line header rollout is ready to implement.
**Relevant execution surface:** all 68 `docs/**/*.md` files plus this focused task handoff. No `.ai/` rule-file header rollout (P6) is included.
**Validation completed at SHA:** prerequisite PR #416 exact reviewed head `9a56c1c8a01d99e7a5e437e05063833fa4258691` merged as `aac56b3f0323ea4f5b8b0e5741ead815097f3da8`; Codex no major issues; unresolved threads 0; both attribution guards PASS; known Supabase strategy/backup current-state drift resolved. Header audit baseline remains 68 docs Markdown files and 0 complete four-line governance headers before rollout.
**Validation remaining:** apply the resolved 68-row classification; verify 68/68 exact header coverage, canonical label vocabulary, preserved existing status semantics, Markdown links, patch hygiene and zero out-of-scope diff; then open/review the header-rollout PR.
**Current blocker:** none
**Open review finding IDs:** P5-AUDIT-01, P5-AUDIT-02
**Next exact action:** insert only the four-line governance metadata under each `docs/` title according to the resolved classification and ownership rules.

## 1. Discovery

### User Outcome

Make documentation governance trustworthy rather than decorative: every document under `docs/` will eventually carry an explicit document status, evidence-backed last-verified date, stable owner, and truth boundary without overwriting existing runtime/planning/ADR status semantics.

### Success Criteria

For P5 overall:

- all 68 Markdown files under `docs/` carry the four-line header directly under the title;
- only canonical status labels from `docs/README.md` are used;
- existing `## Status`, `**Status:**`, and ADR lifecycle status are preserved because they describe runtime/planning/decision state, not documentation-governance classification;
- `Last Verified` is not invented from file modification dates;
- owners use durable role/module ownership, not a human name;
- truth boundaries state what each file is authoritative for and what it is not;
- P6/P7/P9 remain out of scope.

For this prerequisite slice only:

- `SUPABASE_STRATEGY.md` current Status block stops naming legacy non-current owner tables and removed adapter examples;
- `DATABASE_BACKUP_RECOVERY.md` no longer claims the live migration count is 24;
- no governance headers are added yet;
- no other factual cleanup is bundled.

### Scope

Prerequisite slice:
- `.ai/tasks/tnyx-193-p5-doc-governance-headers.md`
- `.ai/tasks/README.md`
- `docs/data/SUPABASE_STRATEGY.md`
- `docs/data/DATABASE_BACKUP_RECOVERY.md`
- GitHub #250 / Linear TNYX-193 state reconciliation

Later P5 header slice:
- every Markdown document recursively under `docs/` (68 files at audited base)

### Non-Goals

- no database mutation;
- no runtime source changes;
- no broad rewrite of canonical docs;
- no cleanup of unrelated stale `.ai/` content;
- no replacement of existing per-document runtime/planning/ADR status sections;
- no automatic use of Git commit date as `Last Verified`.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md`, `.ai/workflow.md`, `.ai/tasks/README.md`, `docs/README.md`, GitHub #250 and Linear TNYX-193 were reconciled before implementation.
- P4A/P4B are completed and archived; P5 is the next separately gated phase.
- `docs/` contains 68 Markdown files: root 1, ADR 13, architecture 4, backend 7, data 6, development 2, mobile 1, planning 3, screens 26, security 4, wearables 1.
- 0/68 currently contain all four canonical header fields.
- Existing runtime/planning/ADR status prose is present in many files and must remain semantically separate from `Document Status`.
- Live Supabase migration parity is 49/49 by version+name.
- Live `public` tables are: `body_weight_logs`, `meal_log_entries`, `meal_log_item_snapshots`, `onboarding_drafts`, `user_app_preferences`, `user_body_goals`, `user_devices`, `user_nutrition_profiles`, `user_nutrition_targets`, `user_profiles`, `user_wellness_targets`, `user_workout_profiles`, `user_workout_targets`, `users`.
- Current Flutter startup initializes Supabase through `SupabaseRuntimeConfig` + `initializeSupabaseRuntime`; current code contains multiple feature-owned Supabase repositories. The old `SupabaseWorkoutPreferencesRepository` and `SupabaseTargetsSetupRepository` named in the strategy Status block are not current source classes.
- The future-safe backend examples later in `SUPABASE_STRATEGY.md` are mostly still present, but `RemoteWorkoutPreferencesRepository` and `RemoteTargetsSetupRepository` are no longer current source examples and must not be presented as currently inactive code.
- P4A establishes ownership folders under `docs/`; `docs/README.md` says canonical docs own repository-wide current policy within their stated truth boundaries, while runtime source/config proves actual behavior and live trackers own task state.
- `docs/adr/README.md` keeps ADR lifecycle status separate from implementation completion and explicitly preserves superseded ADR history.
- `docs/screens/README.md` maps screen/product areas to durable module owners, which P5 uses for screen `Owner` metadata.
- P5 verification date for this rollout is `2026-09-27`; it records verification of each document's governance class/owner/truth boundary against the current canonical/source context, not a claim that planned features are implemented.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| P5 scope is recursive `docs/**/*.md`, not only root `docs/*.md` | Resolved | GitHub #250 acceptance says every document under `docs/`. | Tracker |
| Existing `Status` prose should be replaced by `Document Status` | Rejected | They describe different semantics and both are needed. | Governance model |
| Use one current date for every `Last Verified` value without content evidence | Rejected | Would create false verification claims. | AGENTS.md / audit-first rule |
| Fix known stale current-state prose inside the 68-file header PR | Rejected | Keep the P5 header rollout reviewable; prerequisite drift gets its own bounded docs slice. | Slice discipline |
| Treat future backend policy docs as automatically `Planned/Future Doc` | Rejected | They are current canonical policies even when the runtime they govern is future-only. | docs/README.md authority model |
| Actual numbered ADR files use `Architecture Decision Record` even when superseded | Resolved | The governance label describes document class; each ADR's existing lifecycle `Status` preserves Accepted/Superseded/Deprecated state. | ADR governance |
| `docs/adr/README.md` and `docs/adr/TEMPLATE.md` are ADRs | Rejected | They govern/index ADRs but are not decision records themselves; classify them as `Canonical Live Doc`. | ADR governance |
| Planned-only classification set | Resolved | `docs/planning/ROADMAP.md`, `docs/planning/MVP_ACCEPTANCE.md`, and eight planned-only screen specs: active-workout, meal-plan, nutrition-targets, programs, recovery, routine-library, workout-insights, workout-settings. | P5 matrix |
| Mixed current + target screen specs are planned-only | Rejected | Where a screen doc records current runtime plus target contract, it remains a current canonical screen spec; runtime source still wins for shipped behavior. | Screen catalog |

## 4. Architecture Design

### Chosen Approach

Use two sequential slices under one P5 task:

```text
P5 audit
  -> prerequisite factual-drift correction
  -> validated/merged current docs baseline
  -> 68-row classification + verification matrix
  -> four-line header rollout across docs/
  -> exact review + archive
```

### Ownership and Data Flow

Documentation governance only. Runtime/source and verified Supabase metadata provide evidence; canonical docs receive metadata only after their stated truth is verified to the appropriate boundary.

### Alternative Rejected

A mechanical 68-file header insertion was rejected because it would falsely imply current verification on documents already known to contain stale current-state claims.

### Failure and Accessibility States

Not applicable to runtime/UI. If a document cannot be truthfully classified or verified, P5 must record it as decision-needed rather than inventing metadata.

## 5. Implementation Plan

Prerequisite slice:
- [x] correct `SUPABASE_STRATEGY.md` current Status block using verified current platform state;
- [x] remove no-longer-current backend adapter examples from its future-safe preservation list while keeping valid examples;
- [x] correct the backup/recovery migration-count sentence with an explicitly dated P4B verification note;
- [x] validate exact scope, links and patch hygiene;
- [x] open bounded prerequisite PR and obtain exact-head review; PR #416 merged as `aac56b3f0323ea4f5b8b0e5741ead815097f3da8`.

Header slice after prerequisite merge:
- [x] build and review 68-row path/status/owner/truth-boundary/last-verified matrix; classification summary: 47 `Canonical Live Doc`, 11 `Architecture Decision Record`, 10 `Planned/Future Doc`.
- [ ] apply headers without deleting existing status semantics;
- [ ] verify 68/68 coverage and canonical label vocabulary;
- [ ] validate links/patch/scope;
- [ ] open P5 header PR and obtain exact-head review.

## 6. Quality Review

### Validation Run

```text
Prerequisite source validation complete on branch: 4 ahead / 0 behind from `main@74a3903537442c4d2bb5e120b51a479da851e980`; exactly four planned paths; 49 live migrations = 49 checked-in by version+name; legacy 24-count/table/removed-adapter claims absent; 43 local Markdown references checked with 0 missing; patch scan 0 trailing whitespace / 0 conflict markers / 0 missing-final-newline markers; no out-of-scope path diff.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| P5-AUDIT-01 | Blocking prerequisite | Resolved | `DATABASE_BACKUP_RECOVERY.md` says current live migration history contains 24 applied migrations; live + repository history verify 49/49. | `74a3903537442c4d2bb5e120b51a479da851e980` | Correct only this current-state claim before P5 verification metadata. |
| P5-AUDIT-02 | Blocking prerequisite | Resolved | `SUPABASE_STRATEGY.md` Status block lists legacy tables and removed adapter examples as current; its later inactive-backend examples also include two classes no longer in source. | `74a3903537442c4d2bb5e120b51a479da851e980` | Reconcile the bounded stale current-state/example prose against live schema + current source. |

## 7. Final Handoff

### Changed Files

Prerequisite slice:
- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-193-p5-doc-governance-headers.md`
- `docs/data/SUPABASE_STRATEGY.md`
- `docs/data/DATABASE_BACKUP_RECOVERY.md`

### Actual Behavior

Known current-state drift blocking truthful P5 verification metadata is reconciled in the prerequisite branch. No governance headers or runtime/database behavior changes are included.

### Known Limitations

P5 header rollout remains pending until this prerequisite current-state cleanup is reviewed and merged.

### Final Status

`PARTIAL`
