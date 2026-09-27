# Pre-P9 — Product Onboarding task-index reconciliation

**Status:** Review
**Primary owner:** repository AI governance
**Affected platforms:** Documentation / execution orientation only

## Owner Approval and Scope Boundary

**Trigger:** User authorized the next slice after PR #425 merge.
**Approval status:** Not required
**Approved boundary:** Reconcile stale Product Onboarding current-sequencing claims in active `.ai/tasks` orientation against source/runtime, canonical docs, GitHub, and Linear.
**Explicit non-changes:** No runtime/UI/Supabase/schema/RLS/migration/canonical product architecture changes; no #250 acceptance bookkeeping; no P9 decision; no unrelated task-status closure.

## Active Handoff

**Planning owner:** GitHub #250 / Linear TNYX-193
**Repository baseline:** `main@19790d1d8bb64fd3ca74d79cd0e6d771c74f35fb`
**Branch:** `tnyx/pre-p9-onboarding-task-index-reconciliation`
**Current blocker:** None
**Next exact action:** Correct only current-sequencing statements proven stale by completed/frozen GitHub #40, completed GitHub #11, and Done Linear TNYX-6.

## Discovery

Verified:
- GitHub #40 is closed and explicitly marks Product Onboarding O1–O11 COMPLETE / FROZEN.
- GitHub #11 is closed and explicitly marks O1 App Mode VALIDATED / COMPLETE.
- Linear TNYX-6 is Done and says O1 completed in GitHub #11.
- GitHub #44 remains open only as the broader post-onboarding canonical-ownership umbrella.
- The former canonical execution brief is archived as Superseded/Historical and explicitly MUST NOT be used as current sequencing truth.
- `.ai/tasks/README.md` simultaneously says O1 is NEXT and later says O1–O11 is complete/frozen; this is contradictory.
- Several active task briefs still point to the archived execution brief or describe O1/O1F as current next/active work.

## Scope

Reconcile current-orientation/sequencing wording in:
- `.ai/tasks/README.md`
- `.ai/tasks/app-mode-foundation.md`
- `.ai/tasks/product-onboarding-slice-2b-target-weight-goal-pace.md`
- `.ai/tasks/account-profile-app-preferences-canonical-split.md`

Audit `.ai/tasks/onboarding-flow.md` for index wording, but do not redesign or close its independent architecture/reference scope without evidence.

## Guardrails

- Preserve historical implementation evidence.
- Do not rewrite historical checkpoints merely because they are old.
- Do not mark independent unresolved gates complete.
- Do not resurrect the archived execution brief as authority.
- For new onboarding work, require source + canonical docs + live trackers.

## Validation

Source/tracker reconciliation complete. Branch changes only the focused task-index/orientation surfaces plus this handoff. Current-sequencing assertions that marked O1/O1F as NEXT/ACTIVE or pointed to the archived execution brief as current authority were removed; historical/negative references are retained intentionally. Exact-head PR review and CI remain.

## Final Status

`REVIEW`
