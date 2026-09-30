# Pre-P9 — Mode-conditional onboarding flow supersession

**Status:** In progress
**Primary owner:** repository AI governance
**Affected platforms:** Documentation / execution orientation only

## Owner Approval and Scope Boundary

**Trigger:** None — documentation lifecycle reconciliation inside the user-authorized fresh audit follow-up.
**Approval status:** Not required
**Approval evidence:** User: `Go follow agent.md`.
**Approved product/UI/data-shape boundaries:** Retire the stale active onboarding-flow execution brief while preserving its historical evidence and updating direct references.
**Explicit non-changes:** No Flutter/runtime/UI/routing behavior; no Supabase/schema/RLS/migration/Auth mutation; no Product Onboarding redesign; no TNYX-159 or TNYX-202 implementation; no GitHub #250 P9 start/acceptance decision.

## Discovery

Repository baseline: `main@dda448b2c91039685ece2edd00c2ae0415024369`.

Verified current truth:
- GitHub #40 is closed and records Product Onboarding O1–O11 COMPLETE / FROZEN.
- Linear TNYX-15 (O10) and TNYX-16 (O11) are Done.
- `docs/architecture/ONBOARDING_ARCHITECTURE.md` is the canonical live architecture/status boundary and records Supabase-backed draft persistence and owner-backed completion.
- `.ai/tasks/onboarding-flow.md` still presents a historical `PARTIAL` / durable-completion-blocked execution snapshot and is indexed as `Ready`.
- The prior PR #426 reconciliation intentionally did not close this independent architecture/reference scope; subsequent canonical reconciliation now supplies sufficient evidence to retire it as an active task.
- Direct active-path references exist in `docs/screens/README.md`, `docs/planning/ROADMAP.md`, `docs/screens/onboarding.md`, `docs/adr/0006-single-route-onboarding-parent-flow.md`, and `docs/architecture/ONBOARDING_ARCHITECTURE.md`.

## Scope

- Preserve the old brief at `.ai/archive/2026-09-mode-conditional-onboarding-flow.md` as a Superseded historical snapshot.
- Remove `.ai/tasks/onboarding-flow.md` from active tasks.
- Remove its Current Tasks row from `.ai/tasks/README.md`.
- Update direct canonical/reference links to the archived historical snapshot without changing architecture/product semantics.
- Index the historical snapshot in `.ai/archive/README.md`.

## Guardrails

- Historical checkpoints remain historical; do not rewrite them into current acceptance evidence.
- Current runtime/canonical docs remain authoritative.
- TNYX-159 / GitHub #215 remains future/no implementation authorized.
- TNYX-202 / GitHub #261 remains separate architecture-cleanup backlog.
- P9 remains separately gated.

## Validation

- [x] Exact changed-path scope reviewed: 9 paths; docs/AI lifecycle only.
- [x] Branch-file verification confirms all five direct canonical/reference links now target the historical archive path and `.ai/tasks/README.md` no longer lists the active task. GitHub code search is default-branch indexed, so it cannot validate unmerged branch contents.
- [ ] Exact-head review completed.
- [ ] Required repository checks inspected.
- `git diff --check` cannot be executed through the connected GitHub API; do not claim it passed.

## Handoff

Current state: patch complete; review pending.
Next exact action: complete reference/index reconciliation, open a focused docs-only PR, request exact-head Codex review, and stop before merge unless explicitly authorized.
