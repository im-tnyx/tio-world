# TNYX-193 P3 — Current-State Documentation Drift

**Status:** In progress  
**Primary owner:** repository documentation governance  
**Affected platforms:** documentation only  
**Tracker:** GitHub #250 / Linear TNYX-193

## Owner Approval and Scope Boundary

**Trigger:** separately authorized governance phase  
**Authorization:** owner said `Next go` after P2 completed and post-merge reconciliation returned GitHub #250 / TNYX-193 to active umbrella state.  
**Base:** `main@25556a83cf49886333ecfe10d8628b79cbf5159d`.

**Approved P3 boundary:** correct checkout-contradicted current-state Supabase/protected-server wording only in the four docs already classified for P3 by GitHub #250 / TNYX-193:

- `docs/DEVELOPMENT_SETUP.md`
- `docs/FLUTTER_MODULAR_STRUCTURE.md`
- `docs/MODULE_OWNERSHIP.md`
- `docs/SUPABASE_STRATEGY.md`

**Explicit non-changes:** no runtime/UI/routing/state, no Supabase schema/migration/RLS/Storage/Edge Function/Auth mutation, no CI workflow, no lockfile, no `.ai/CURRENT.md` (P7), no `docs/README.md` authority/header work (P4), no P5/P6 header rollout, no future `services/api` or `services/worker` scaffolding, no ADR rewrite, and no newly discovered stale docs outside the P1-classified P3 set.

## Active Handoff

**Planning owner:** current P3 session  
**Implementation owner:** current P3 session  
**Review owner:** pending independent review  
**Implementation ownership state:** Complete  
**Branch:** `tnyx/tnyx-193-p3-current-state-doc-drift`  
**Repository base last verified:** `main@25556a83cf49886333ecfe10d8628b79cbf5159d`  
**Observed working-tree state:** connector/API execution only; no local working tree is available to inspect  
**Current blocker:** none; exact-head independent review remains before merge  
**Next exact action:** open the bounded docs-only PR, run exact PR patch/check validation, and request independent exact-head review.

## 1. Discovery

### User Outcome

Canonical repository docs should stop saying Supabase is absent/future or that protected server work belongs under the old `backend/` namespace.

### Verified Current Truth

Fresh current-main audit confirmed:

- root `supabase/` exists and is active;
- it contains `config.toml`, migrations, functions, drafts and tests;
- current canonical architecture assigns Auth/data/migrations/RLS/approved Edge Functions to `supabase/`;
- `services/` does not exist in the checkout;
- future protected server work is architecture-locked to `services/api`, with `services/worker` reserved only for a real future async workload;
- architecture documentation does not authorize creating either future service path.

## 2. Codebase Exploration

GitHub #250 and Linear TNYX-193 already classify these P3 drift areas:

- `docs/DEVELOPMENT_SETUP.md` falsely says no Supabase workspace/config is present and points future backend work at `backend`.
- `docs/FLUTTER_MODULAR_STRUCTURE.md` says root `supabase/` is absent and describes a future `backend/` workspace.
- `docs/MODULE_OWNERSHIP.md` marks Supabase as future and assigns protected server/API/AI/jobs to future `backend/*`.
- `docs/SUPABASE_STRATEGY.md` mixes active-current Supabase statements with stale future-`supabase/` and future-`backend/` setup/tree/sequencing language.

Fresh search also found stale `backend/*` references elsewhere, but they are outside the locked P3 doc set and are not part of this slice.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Treat `supabase/` as active current infrastructure | Chosen | Verified in current checkout and canonical architecture |
| Treat `services/api` as future architecture-only | Chosen | Canonical current architecture; `services/` absent |
| Preserve future async worker as `services/worker` only when justified | Chosen | Canonical architecture already reserves this path |
| Rewrite ADR history | Rejected | Historical decisions are preserved; P3 fixes current docs |
| Pull in newly discovered stale files | Rejected | Would silently broaden P3 beyond canonical tracker classification |
| Create future service folders/tooling | Rejected | Docs correction does not authorize backend implementation |

## 4. Architecture Design

P3 changes documentation statements only. The durable ownership model remains:

```text
Flutter/Wear clients
  → client-safe Supabase access
  → Supabase Auth + Postgres/RLS + approved Storage/Edge Functions

future protected service, only when separately approved:
  services/api

future async worker, only when a real workload justifies it:
  services/worker
```

## 5. Implementation Plan

- [x] correct current Supabase/future-service wording in `docs/DEVELOPMENT_SETUP.md`
- [x] correct current Supabase/future-service wording in `docs/FLUTTER_MODULAR_STRUCTURE.md`
- [x] correct ownership rows/rules in `docs/MODULE_OWNERSHIP.md`
- [x] reconcile internally stale setup/tree/sequencing wording in `docs/SUPABASE_STRATEGY.md`
- [x] keep P3 to exactly four canonical docs plus this execution handoff/index
- [x] validate no runtime/Supabase/CI files changed
- [x] run docs/reference/current-state checks
- [ ] request independent exact-head review

## 6. Quality Review

Implementation validation at `99cd55cf3a164ca4c7e2e669caba1f93aab4eace`:

- base `main@25556a83cf49886333ecfe10d8628b79cbf5159d`
- 7 ahead / 0 behind before this task-handoff update
- exactly 6 expected paths: task brief/index + 4 approved P3 docs
- runtime/Supabase/CI/service files changed: 0
- stale P3 factual patterns in the four docs: 0
- intentional `backend/*` occurrence: only the explicit rule forbidding that namespace
- local-reference integrity over `AGENTS.md`, `docs/README.md`, and `.ai/README.md`: 69 checked, 0 missing
- trailing whitespace: 0
- conflict markers: 0
- current direction verified in all four docs: active `supabase/`, future-only `services/api`/`services/worker`

## 7. Final Handoff

### Expected Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-193-p3-current-state-doc-drift.md`
- `docs/DEVELOPMENT_SETUP.md`
- `docs/FLUTTER_MODULAR_STRUCTURE.md`
- `docs/MODULE_OWNERSHIP.md`
- `docs/SUPABASE_STRATEGY.md`

### Known Limitations

P3 does not fix stale wording outside these four canonical docs and does not start P4, P5, P6, P7 or P9.

### Final Status

`REVIEW` — bounded implementation and branch validation complete; exact PR patch/check validation and independent review remain.
