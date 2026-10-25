# Progress Weight D0 — documentation and contract freeze

**Status:** In progress (docs-only review-gate PR; unmerged)
**Primary owner:** Progress product: `apps/features/progress`; D0 change owner: `docs/screens` and `.ai/tasks`
**Affected platforms:** Flutter phone contract only; no executable platform change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped documentation/contract slice
**Approval status:** Approved
**Approval evidence:** Owner message 2026-10-25: "Go D0 — Progress Weight documentation and contract freeze", explicitly no merge without approval.
**Approved product/UI/data-shape boundaries:** Document the owner-directed Weight summary → range chart → History below chart → Log Weight bottom-sheet structure and contract, without freezing unseen pixel geometry or implementing UI.
**Explicit non-changes:** No Flutter/Watch code, navigation, design tokens, schema/migration/RLS, Storage/bucket, optional photo upload, media registry, release switch, or merge.

## Active Handoff

**Planning owner:** TNYX-119; GitHub #686
**Implementation owner:** Single D0 documentation author, `im-tnyx` GitHub connection
**Review owner:** Distinct GitHub reviewer preferred; pending review-gate evaluation
**Implementation ownership state:** Active (documentation only)
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub remote `main` SHA `516faa298e2437e07f89f156187afd231325679c`; 2026-10-25
**Branch:** `docs/686-progress-weight-d0-contract`
**HEAD SHA:** Consult the live [PR #687](https://github.com/im-tnyx/tio-world/pull/687) for the final exact head; first review-gate evidence was collected at `b635afffa50c61b86b96cb9550e7d375782c111c`.
**Observed working-tree state:** Not available; GitHub-connector execution, no Windows local checkout access
**Observed uncommitted/dirty files:** Not inspectable locally; use parent-to-head GitHub API scope audit
**PR / tracker:** [PR #687](https://github.com/im-tnyx/tio-world/pull/687) (OPEN/unmerged), [GitHub #686](https://github.com/im-tnyx/tio-world/issues/686); [Linear TNYX-119](https://linear.app/tnyx/issue/TNYX-119/progress-weight-logging-photos-and-private-user-media-persistence)
**Current implementation state:** Canonical specification proposal only, Weight screen still placeholder
**Relevant execution surface:** `docs/screens/progress.md`, `.ai/tasks/progress-weight-d0-contract-freeze.md`, task index
**Validation completed at SHA:** First PR head `b635afffa50c61b86b96cb9550e7d375782c111c`: [Docs Hygiene run 40183434680](https://github.com/im-tnyx/tio-world/actions/runs/40183434680) SUCCESS and its job log ran `git diff --check` on exact base/head; attribution guard and runner SUCCESS; GitHub compare ahead 1, behind 0, exactly three intended docs files. These are first-head, not new-head claims.
**Validation remaining:** Refresh exact final-head checks after this handoff-only amendment; formal distinct-reviewer `im-tio` review was requested and is pending; branch protection read returned GitHub 403 and requiredness is unverified.
**Current blocker:** Explicit owner merge authorization not given; formal reviewer pending. GitHub branch-protection endpoint returned `403 Resource not accessible by integration`, so rule-requiredness cannot be asserted.
**Open review finding IDs:** Pending
**Next exact action:** Check current PR head, Docs Hygiene/Attribution and review threads/verdict; leave PR open, do not merge.

## 1. Discovery

### User Outcome

A clean, source-backed target Weight contract lets implementation start in safe bounded slices without guessing data ownership, activating Photos prematurely, or redesigning Tio.

### Success Criteria

- Reconcile current placeholder and parent TNYX-119 with the structural Weight UI reference.
- Fix stale private `progress` bucket wording to current private `user-media` **candidate**, without claiming it is deployed.
- Specify owner-backed summary, range/history, Log/Edit/Delete semantics, errors and privacy.
- Record bounded implementation order A1–A4 and a docs-only reviewable PR.

### Scope

Only the canonical Progress document, this compact task brief and its index, plus GitHub/Linear tracking.

### Non-Goals

No implementation, Photos V1/private Storage, schema/RPC changes, new UI geometry, release or broad platform work.

## 2. Codebase Exploration

### Verified Evidence (2026-10-25 read-only)

- `AGENTS.md`, `apps/features/AGENTS.md`, theme README, `.ai/FEATURE_DEVELOPMENT.md`, `docs/README.md`, architecture/ownership, roadmap and Progress screen contract inspected.
- `apps/features/progress/lib/src/domain/body_setup.dart`: `BodyRepository.getBodyState()`, `recordCurrentWeight()`; `BodyWeightEntry` lacks row `id`. No public exact-entry list/edit/delete methods.
- `apps/features/progress/lib/src/data/supabase_body_setup_repository.dart`: latest weight read ordered by `measured_at DESC` and post-onboarding insert; Settings source is screen-specific today.
- `apps/core/lib/src/units/unit_formatters.dart` and Settings Body & Weight: existing `WeightUnit`/conversion/wheel primitives are reusable.
- Live `public.body_weight_logs` columns and authenticated owner-scoped SELECT/INSERT/UPDATE/DELETE RLS verified; `progress_photos` and `user_media_assets` absent.
- Live Storage bucket audit: only `avatars` exists, public. Private `user-media` is a Slice B candidate, not deployed.
- Linear `TNYX-119` Backlog, blocker `TNYX-48` Done. Separate D0 Linear child creation attempted but workspace rejected due to free issue limit. Tracked instead via parent comment and GitHub #686.

## 3. Clarification and Decisions

| Decision | D0 position | Later gate |
|---|---|---|
| Weight truth | Existing `body_weight_logs` and `user_body_goals`; no duplicated current weight | A1 repository tests |
| Layout | Weight summary → selected-range chart → History → Log Weight bottom sheet | A2 product-visible specifics/approval |
| History | Multiple same-day records; exact row identities; deterministic sort | A1 pagination/edit contracts |
| Weight unit/time | Canonical `kg` and absolute `measured_at`; local display | A1/A3 timezone provenance and future policy |
| Source | Preserve live screen-specific legacy sources; target semantic manual | A1/A3 compatibility resolution |
| Photos | No upload or bucket in Weight Slice A; `user-media` private candidate only | Slice B new audit/approval |
| Percent/chart | No fake goal percentage, zero trends or synthetic measurements | A2 valid calculations and accessible states |

## 4. Architecture Design

```text
Progress UI → Progress notifier/use case → BodyRepository
  → SupabaseBodySetupRepository / bounded future weight adapter
  → owner-scoped body_weight_logs (+ separate Body Goal read model)
```

Keep route wiring in `apps/app` and business/data logic in Progress. Reuse public `tio_core` theme/components and global unit preferences. Reject direct Supabase queries in widgets and adding a mirrored weight column or generic media platform.

## 5. Implementation Plan (separately gated)

- [x] Audit current canonical docs, runtime, Linear and live Supabase read-only.
- [x] Write docs-only D0 contract and handoff.
- [x] Inspect first PR head `b635afff` files/scope/Docs Hygiene (`git diff --check`)/Attribution.
- [ ] Refresh final exact-head CI and await real distinct GitHub reviewer verdict; do not merge without instruction.
- [ ] A1: BodyRepository history and identity/ordering/edit-delete contracts.
- [ ] A2: approved Weight summary/chart/History UI.
- [ ] A3: approved Log Weight bottom sheet and persistence.
- [ ] A4: exact record editing/deleting and QA.
- [ ] Separate Photos Slice B / conditional media registry Slice C only after their own gates.

## 6. Quality Review

**Validation:** Docs-only. Exact-head [Docs Hygiene run 40183434680](https://github.com/im-tnyx/tio-world/actions/runs/40183434680) SUCCESS at first head `b635afff`; job log shows `git diff --check "$BASE_SHA...$PR_HEAD_SHA" -- .ai/ docs/ .github/workflows/docs-hygiene-ci.yml` and `PASS: documentation diff hygiene`. Direct local checkout not accessed; reverify if PR head changes. Commit attribution guard and runner also SUCCESS at first head.

**Acceptance evidence:** D0 spec and tracking only; user-visible Weight behavior, real-device validation, Supabase new-schema validation and production acceptance are `Not applicable` to this docs PR.

**Review provenance:** PR #687; `im-tio` formal reviewer request verified, no review yet at first-head audit. Cursor security/bug/approval checks returned `neutral`, not review approval. Branch-protection endpoint denied (403), required-check/review policy not verified. No independent APPROVED claim.
**Review findings:** None claimed before review.

## 7. Final Handoff

**Changed files:** `docs/screens/progress.md`, this handoff, `.ai/tasks/README.md`.
**Actual behavior:** No runtime changes. Documentation reconciles canonical target and current state.
**Known limitations:** Original image assets are not present in this audit turn; freeze order/semantics rather than pixel geometry. Windows working tree and local `git diff --check` cannot be inspected through the GitHub connector. Supabase private media remains unimplemented.
**Final status:** `REVIEW` pending exact-PR evidence/owner merge authorization.
