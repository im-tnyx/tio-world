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
**HEAD SHA:** review-fix checkpoint `940c6b1f4be852f27b305f15d36c4e12437e83f9`; this handoff refresh creates the final review head that must be revalidated
**Observed working-tree state:** Connector/API execution only; no local worktree claim.
**Observed uncommitted/dirty files:** Not applicable through connector/API.
**PR / tracker:** GitHub #250 / PR #417 / Linear TNYX-193; prerequisite PR #416 merged
**Current implementation state:** four-line governance headers are implemented across all 68 `docs/**/*.md` files. Codex review findings on stale routing/ownership/current-state prose were verified against current source/canonical architecture and fixed; PR #417 exact-head revalidation/re-review remains.
**Relevant execution surface:** all 68 `docs/**/*.md` files plus `.ai/tasks/README.md` and this focused task handoff. No `.ai/` rule-file header rollout (P6) is included.
**Validation completed at SHA:** review-fix checkpoint `940c6b1f4be852f27b305f15d36c4e12437e83f9`: 20 ahead / 0 behind from `main@aac56b3f0323ea4f5b8b0e5741ead815097f3da8`; 70 changed files = 68 docs + `.ai/tasks/README.md` + this active task brief; 64 docs remain pure header-only at 5 additions / 0 deletions; 4 docs have bounded review-driven factual reconciliation in addition to their headers (`ONBOARDING_ARCHITECTURE.md`, `ROADMAP.md`, `docs/screens/README.md`, `docs/screens/coach.md`); status counts remain 47/11/10; Splash/Welcome owners now match `apps/features/splash` and `apps/features/welcome`; obsolete `backend/ai-coach` routing is gone from the reviewed roadmap/Coach locations; onboarding draft persistence and screen-catalog current status match current source evidence.
**Validation remaining:** revalidate the handoff-refreshed final head, reply/resolve the six verified Codex findings with exact evidence, update PR/tracker exact-head evidence, inspect checks, and obtain a fresh independent exact-head review.
**Current blocker:** none
**Open review finding IDs:** P5-REV-01 through P5-REV-06 fixes applied; exact-head revalidation/thread closeout pending
**Next exact action:** revalidate the final review head, then close the six review threads with evidence and request a fresh Codex exact-head review.

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
- [x] apply headers without deleting existing status semantics;
- [x] verify 68/68 coverage and canonical label vocabulary;
- [x] validate header placement, status sets, docs-body preservation, and zero Markdown-link mutation; final patch/scope hygiene remains after this handoff refresh.
- [ ] open P5 header PR and obtain exact-head review.

## 6. Quality Review

### Validation Run

```text
Prerequisite source validation complete on branch: 4 ahead / 0 behind from `main@74a3903537442c4d2bb5e120b51a479da851e980`; exactly four planned paths; 49 live migrations = 49 checked-in by version+name; legacy 24-count/table/removed-adapter claims absent; 43 local Markdown references checked with 0 missing; patch scan 0 trailing whitespace / 0 conflict markers / 0 missing-final-newline markers; no out-of-scope path diff.

Header-rollout + review-fix checkpoint `940c6b1f4be852f27b305f15d36c4e12437e83f9`: 68/68 docs headers remain present with 47 canonical + 11 ADR + 10 planned/future; 64 docs are pure header-only, while 4 docs contain bounded factual corrections required to make `Last Verified` truthful; `.ai/tasks/README.md` now routes takeover to the current PR #417 review state.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| P5-AUDIT-01 | Blocking prerequisite | Resolved | `DATABASE_BACKUP_RECOVERY.md` says current live migration history contains 24 applied migrations; live + repository history verify 49/49. | `74a3903537442c4d2bb5e120b51a479da851e980` | Correct only this current-state claim before P5 verification metadata. |
| P5-AUDIT-02 | Blocking prerequisite | Resolved | `SUPABASE_STRATEGY.md` Status block lists legacy tables and removed adapter examples as current; its later inactive-backend examples also include two classes no longer in source. | `74a3903537442c4d2bb5e120b51a479da851e980` | Reconcile the bounded stale current-state/example prose against live schema + current source. |
| P5-REV-01 | P2 | Fix applied | Active-task index still described the prerequisite slice after the 68-header rollout. | `58882396eab71e414e28b153465eaab4ed81181e` | `.ai/tasks/README.md` now states PR #417 header rollout is implemented and under review. |
| P5-REV-02 | P2 | Fix applied | ROADMAP and Coach repeated obsolete protected-backend path `backend/ai-coach`. | `58882396eab71e414e28b153465eaab4ed81181e` | Both now route future protected AI work to canonical `services/api` with explicit authorization. |
| P5-REV-03 | P2 | Fix applied | Splash header owner conflicted with the real `apps/features/splash` package and its own primary-owner line. | `58882396eab71e414e28b153465eaab4ed81181e` | Header owner corrected to `apps/features/splash`. |
| P5-REV-04 | P2 | Fix applied | Welcome header owner conflicted with the real `apps/features/welcome` package and its own primary-owner line. | `58882396eab71e414e28b153465eaab4ed81181e` | Header owner corrected to `apps/features/welcome`. |
| P5-REV-05 | P2 | Fix applied | Onboarding current-runtime prose said Supabase/draft persistence was not implemented although current source provides `SupabaseOnboardingDraftRepository` and `public.onboarding_drafts`. | `58882396eab71e414e28b153465eaab4ed81181e` | Current runtime boundary now records implemented durable draft persistence/resume and the remaining owner-write/finalization gate. |
| P5-REV-06 | P2 | Fix applied | Screen catalog still called Library/Exercises/Nutrition/Meal Diary future/placeholders despite shipped routes and implemented screen-doc status. | `58882396eab71e414e28b153465eaab4ed81181e` | Those four catalog rows now match current route/source and individual screen-doc evidence. |

## 7. Final Handoff

### Changed Files

Prerequisite slice:
- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-193-p5-doc-governance-headers.md`
- `docs/data/SUPABASE_STRATEGY.md`
- `docs/data/DATABASE_BACKUP_RECOVERY.md`

Header-rollout/review slice:
- all 68 Markdown documents recursively under `docs/`
- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-193-p5-doc-governance-headers.md`

Review-driven body reconciliation is intentionally limited to `docs/architecture/ONBOARDING_ARCHITECTURE.md`, `docs/planning/ROADMAP.md`, `docs/screens/README.md`, and `docs/screens/coach.md`; all other docs changes are governance-header metadata only.

### Actual Behavior

All 68 Markdown documents under `docs/` now carry the canonical four-line governance header directly below the H1 title. Existing ADR lifecycle status and unrelated document content remain intact. Codex review exposed six verified governance/current-truth issues; their fixes update only the active task index, two header owners, and four bounded canonical-doc current-state/routing locations so the new `Last Verified` claims are truthful. Runtime/database behavior is unchanged.

### Known Limitations

P5 source implementation is complete but not merged; exact-head review/check gates remain. P6/P7/P9 are still separately gated.

### Final Status

`REVIEW`
