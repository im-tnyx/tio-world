# Pre-P9 — Mode-conditional onboarding flow supersession

**Status:** Validated
**Completed:** 2026-09-30
**Archived:** 2026-10-11
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
- [x] Exact-head manual patch review completed after Codex returned usage-limit notices instead of a review; no material scope, link-target, historical-evidence, or future-scope finding identified.
- [x] Required repository checks inspected on reviewed head: no combined statuses or pull-request workflow runs were published; therefore no CI/check-pass claim is made.
- `git diff --check` cannot be executed through the connected GitHub API; do not claim it passed.

## Handoff

Current state: Validated and merged. The supersession decision and historical record are durable in `docs/architecture/ONBOARDING_ARCHITECTURE.md`, `docs/screens/onboarding.md`, and `.ai/archive/2026-09-mode-conditional-onboarding-flow.md`.
Next exact action: None for the completed supersession handoff; any further audit or P9 phase needs a separate authorization.

## Final Outcome And Lifecycle Evidence

- PR #490 `docs(ai): supersede historical onboarding flow handoff` closed/merged on **2026-09-30**.
- Final reviewed PR head: `ff2a55653da0ecfd89e7860fa803bde88006e240`.
- Exact-head Codex review **was not available**: the bot returned code-review usage-limit notices. Manual patch review reported no material issue; unresolved review threads: **0**. Do not label this a clean Codex review.
- The reviewed head had **no published combined statuses or pull-request workflow runs**; no CI-pass claim. `git diff --check` was not executed through the GitHub-only connector.
- Squash merge SHA: `f5e02a22f5ac4d39be2b2c4e4f7c90ded6c47cf6`; immediately after merge, remote `main` was verified identical to that SHA (**0 ahead / 0 behind**).
- GitHub #250 and Linear TNYX-193 received post-merge evidence comments; Linear TNYX-193 remained **In Progress**.
- Fresh archive baseline: `main@4921ab4e54c424ea5c7b16c0e2e29fe0c9e382f3` (2026-10-11); source-backed canonical onboarding status still implemented/frozen, and historical onboarding-flow supersession remains preserved.
- The archived historical task has no current execution authority. TNYX-159 / GitHub #215 and TNYX-202 / GitHub #261 remain separate backlog/planning work. P9 was not started by this lifecycle cleanup.
- **Verdict: VALIDATED** — supersession outcome verified and durable; this file now records completion history rather than an active/merge-pending task.

## Archive-PR Boundary

This is a documentation-only handoff move plus archive-index edit. The archive PR's own exact-head review/CI evidence is independent of PR #490's evidence and must be checked before any separately authorized merge.
