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

## Implementation Plan

1. Replace only four stale status-table entries, preserving the remaining catalog and owner links.
2. Record a clearly scoped 2026-10-15 verification note so the document header does not imply every planned screen was revalidated.
3. Index this handoff once in `.ai/tasks/README.md`.
4. Verify exact `main...HEAD` four-row diff, changed-path inventory, all catalog local Markdown links, no added trailing whitespace, review threads and required checks.
5. Request Codex exact-head review; if unavailable, record the actual limitation and manual findings. Stop before merge.

## Active Handoff

**Planning owner:** GitHub #250 / Linear TNYX-193 governance
**Implementation owner:** Documentation governance (this bounded docs-only slice)
**Review owner:** Exact-head Codex review and independent manual diff examination
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** Remote `main@9de4863800dcb2229797c7a92b76a4975491bcf3`
**Branch:** `docs/pre-p9-screen-catalog-current-state`
**Observed working-tree state:** No local checkout available through GitHub connector; user-local state not inspected in this turn
**Observed uncommitted/dirty files:** Unknown locally; GitHub branch created at verified `main`
**Current implementation state:** Documentation correction in progress
**Validation completed at SHA:** Read-only source/tracker audit against above `main`
**Validation remaining:** GitHub exact-head diff, link/hygiene checks, attribution/Codex; local `git diff --check` not available in connector session
**Current blocker:** No blocker within approved docs-only correction; full-catalog criterion 2 requires separate complete re-audit
**Open review finding IDs:** None yet
**Next exact action:** Complete source-backed catalog row replacements and open scoped docs-only PR, STOP before merge

## Final Handoff

**Changed files:** Pending branch audit.
**Actual behavior:** No executable behavior or user-facing UI change.
**Known limitations:** No local `git diff --check`, Flutter tests or Supabase live commands run through this GitHub connector workflow.
**Final status:** REVIEW pending exact-head validation.
