# Pre-P9 — Screen Catalog Current-State Row Reconciliation

**Status:** In progress
**Primary owner:** Repository documentation governance / `docs/screens/`
**Affected platforms:** Canonical phone screen catalog documentation only; no product behavior change

## Owner Approval and Scope Boundary

**Trigger:** None — continuation of GitHub #250 final contradiction acceptance after a separate read-only screen-catalog audit.
**Approval status:** Owner authorized `Next go with audit follow agent.md` on 2026-10-15 for the recommended bounded screen-catalog correction.
**Approved scope:** Update four false current-state screen status rows (Profile, Profile Photo, Nutrition Targets, Settings) in `docs/screens/README.md`, plus focused execution handoff and index entry.
**Explicit non-changes:** No Flutter source, visual geometry, routes, navigation behavior, Supabase schema/RLS/RPC/Storage policy, account or health data processing, CI/tooling, package/lockfile, other screen specs, broader W4 drafts, GitHub #250 acceptance checkbox, P9 routing map or Linear status transition. No merge without separate owner authorization.

## Discovery and Verified Current Truth

- Verified protected remote `main@9de4863800dcb2229797c7a92b76a4975491bcf3` (2026-10-15) and untruncated 2,397-entry repository tree; root `AGENTS.md`, `.ai/workflow.md`, `docs/README.md`, `docs/architecture/MODULE_OWNERSHIP.md`, related canonical screen docs, GitHub #250 and Linear TNYX-193 inspected.
- GitHub #250 remains Open with its full-catalog canonical contradiction acceptance unchecked; P9 Not started. Linear TNYX-193 remains In Progress. These are governance checks only, not proof of broader product acceptance.
- Catalog has already reconciled Library, Program Detail and read-only Routine Detail for merged PR #522/#530. Do not replace that correct status or misclassify unmerged Exercise/Set editor work as shipped.
- Profile: `apps/app/lib/app/routing/routes/profile_routes.dart`, `docs/screens/profile.md` and Profile-owned repository establish canonical profile/account/body presentation, persisted Profile Settings entry, avatar upload/delete and Settings launch. The catalog's `profile details remain planned` is false.
- Profile Photo: `profile_routes.dart` provides real `AvatarPreviewPage` upload and delete handlers; `docs/screens/profile-avatar.md` describes the current Profile-owned Supabase avatar repository. Download remains unavailable. The catalog incorrectly says safe disabled media actions and Storage operations only planned. Existing public `avatars` bucket is a documented Profile-media exception; do not imply private Storage or expand its policy.
- Nutrition Targets: `apps/app/lib/app/routing/routes/nutrition_routes.dart` registers Nutrition target, macro and additional-goals pages backed by `nutritionTargetsRepositoryProvider`; `docs/screens/nutrition-targets.md` describes implemented repository-backed load/save. The catalog incorrectly calls the entire configuration future.
- Settings: `apps/app/lib/app/routing/routes/settings_routes.dart` registers App Mode, Theme, Measurement Units, Calendar Preferences and Health & Goals / Daily Wellness routes; `docs/screens/settings.md` distinguishes device-local Glass Size, calendar preference and pending broader page-layout acceptance. The catalog's `remaining preferences planned` is false. Do not claim broader Settings readiness or device acceptance.
- Updated current-state rows will be scoped **repository-implemented functionality**, not published mobile-app release evidence.
- Remaining screen statuses and W4 in-flight slices are outside this correction; do not use a four-row fix to mark the full GitHub #250 contradiction criterion passed.

## Implementation and Review Checkpoint — 2026-10-15

1. **Completed:** Corrected the four stale screen-status rows (Profile, Profile Photo, Nutrition Targets, Settings) and indexed the handoff; other catalog rows, including merged W4A, remain unchanged.
2. **Completed on original PR head `d1b247ba4e409f3313190648e93095474ac220cb`:** GitHub compare checked 3 expected docs/AI paths, 3 ahead / 0 behind; 44 catalog Markdown links resolved with 0 broken; required attribution checks PASS; 0 inline review threads at that point. The repository owner provided a successful `git diff --check origin/main...origin/docs/pre-p9-screen-catalog-current-state` run for that original head.
3. **Codex review on original head completed with two P2 findings:** `4285947882` (stale active handoff) and `4285947897` (document-wide `Last Verified` falsely implying full-catalog revalidation). Neither finding is a Flutter/Supabase/runtime defect.
4. **In progress:** Restored document-wide `Last Verified: 2026-09-28` while retaining the explicit **2026-10-15 four-row-only verification note**, then reconciled this active handoff and index. The header correction committed at `7763bf7bad5f2f5476aac5a02d1f665490ed2a02`; editing this handoff creates another commit, so the live PR #563 head is authoritative for the latest SHA.
5. **Pending:** Refresh exact final-head branch comparison, links, patch hygiene, required checks and Codex review; respond to the two P2 threads and resolve only when accepted. Local `git diff --check` on the new head must be rerun by the owner. **STOP before merge** without separate owner authorization.

## Active Handoff

**Planning owner:** GitHub #250 / Linear TNYX-193 governance
**Implementation owner:** Documentation governance (this bounded docs-only slice)
**Review owner:** Exact-head Codex review and independent manual diff examination
**Implementation ownership state:** Active — Codex P2 remediation / re-review pending
**Ownership transition:** Not applicable
**Repository state last verified:** Remote `main@9de4863800dcb2229797c7a92b76a4975491bcf3`
**Branch:** `docs/pre-p9-screen-catalog-current-state`
**Observed working-tree state:** No local checkout available through GitHub connector; user-local state not inspected in this turn
**Observed uncommitted/dirty files:** Unknown locally; GitHub branch created at verified `main`
**Current implementation state:** PR #563 is OPEN / NOT MERGED; four catalog rows and scoped verification note corrected; the document-wide date reverted after Codex P2, and the active handoff has been updated for review recovery.
**Validation completed at SHA:** Original PR head `d1b247ba4e409f3313190648e93095474ac220cb` — three-file GitHub compare, 44/44 catalog links, no added trailing whitespace, attribution checks PASS; owner-run local `git diff --check` PASS on that comparison. Header P2 correction committed at `7763bf7bad5f2f5476aac5a02d1f665490ed2a02`; post-remediation exact-head checks pending.
**Validation remaining:** Recheck the new PR #563 HEAD (branch ancestry, three-file patch, Markdown links, whitespace, required attribution checks, Codex re-review and P2 thread dispositions). Owner local `git diff --check` PASS was on the earlier head and must be rerun for final head; the connector cannot execute it.
**Current blocker:** Two actionable P2 Codex findings require same-scope remediation verification and exact-head re-review; full-catalog criterion 2 requires a separately bounded re-audit after merge.
**Open review finding IDs:** `4285947882` — P2 handoff state corrected here, review/disposition pending; `4285947897` — P2 full-doc verified date corrected in `docs/screens/README.md`, review/disposition pending.
**Next exact action:** Review corrected three-file diff on current PR #563 head, verify new attribution CI/link hygiene, request Codex re-review on new head, respond to P2 threads and await owner local `git diff --check` on final head; STOP before merge.

## Final Handoff

**Changed files:** `docs/screens/README.md`, `.ai/tasks/pre-p9-screen-catalog-current-state.md`, `.ai/tasks/README.md` (same three-path bounded docs/AI scope).
**Actual behavior:** No executable behavior or user-facing UI change.
**Known limitations:** No local commands run by the connector. Owner-provided PowerShell `git diff --check` passed for original head before the P2 corrections; repeat on final head. No Flutter tests or Supabase live commands are applicable to this docs-only change.
**Final status:** REVIEW — two P2 Codex findings under correction; exact-head re-review and separate merge authorization required.
