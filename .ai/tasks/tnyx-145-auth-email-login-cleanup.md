# TNYX-145 Auth Legacy Email Login Cleanup

**Status:** Validated
**Primary owner:** Codex
**Affected platforms:** Flutter phone app (Auth package and existing route contract)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner explicitly requested GitHub #194 / Linear TNYX-145 implementation from fresh current `origin/main`.
**Approved product/UI/data-shape boundaries:** Remove the dead duplicate email-login implementation and its obsolete export while preserving the canonical `LoginPage`, `/login`, and `/login/email` behavior.
**Explicit non-changes:** No Auth UI redesign; no route removal or rename; no session/bootstrap change; no legacy onboarding redirect migration; no synthetic success fallback; no Truecaller capability change; no #24 or #34 work; no schema, migration, Supabase, backend, or API change.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** Codex
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-09
**Branch:** `tnyx/tnyx-145-auth-cleanup`
**HEAD SHA:** `4b808a0bf6825f02aa96c902bbd2168085cd8a75`
**Observed working-tree state:** Fresh branch tracks `origin/main`; approved task changes are implemented and validated but not yet committed.
**Observed uncommitted/dirty files:** Pre-existing `pubspec.lock` modification and `.ai/tasks/tnyx-54-nutrition-ia-readiness.md` untracked file; both are outside scope and must remain untouched.
**PR / tracker:** GitHub #194; Linear TNYX-145 set to `In Progress` with Phase 1 evidence comment.
**Current implementation state:** Dead implementation/export removed; stale exact-name task-note references corrected; canonical login/router/session source unchanged.
**Relevant execution surface:** `apps/features/auth`, existing app router and session route policy tests.
**Validation completed at SHA:** Working tree based on `4b808a0bf6825f02aa96c902bbd2168085cd8a75`; focused Auth/app analyze, canonical login widget tests, session route-policy tests, zero-reference search, and canonical-source diff audit passed.
**Validation remaining:** Final post-commit parent-to-head scope audit and exact-head CI after push.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Run final Git checks, commit scoped files, push, open PR, and update Linear.

## Global UI / Design-System Guardrail

Core contract read: YES

Relevant Core README read: YES

Relevant component implementation/public surface inspected: YES

Relevant component tests inventoried: YES

This is dead-code deletion with zero intended rendered or behavioral delta. The canonical `LoginPage` and every reusable Core contract remain unchanged.

## 1. Discovery

### User Outcome

Remove the obsolete duplicate email-login screen so `LoginPage` is the sole canonical login surface, without breaking the legacy email-login deep link.

### Success Criteria

- The duplicate implementation and obsolete export are gone.
- Repository-wide exact-name/path searches return zero references.
- `/login` still constructs canonical `LoginPage`.
- `/login/email` remains a compatibility alias that opens Email mode on the same page.
- Session/bootstrap route policy is unchanged.
- Focused validation and branch-scope checks pass.

### Scope

- Auth presentation dead-code cleanup.
- Stale historical task-note correction required by the zero-reference acceptance gate.
- Focused Auth/router/session validation.

### Non-Goals

- Any product-visible Auth change.
- Auth hardening, reusable field migration, routing redesign, backend, schema, or Supabase work.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: Auth public barrels, legacy duplicate source, canonical `LoginPage`, app router, route contracts, and session route policy.
- Existing pattern to follow: both `/login` and `/login/email` construct `LoginPage`; route-aware mode selection is owned inside canonical `LoginPage`.
- Tests or validation already present: Auth widget coverage asserts the legacy route opens Email mode; session policy coverage retains both route aliases.
- Fresh open-PR overlap search: no open overlapping PR found.
- Pre-delete reference audit: no runtime construction or dedicated test/golden for the duplicate implementation; remaining references were its own declaration, one barrel export, and two historical task notes.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep `LoginPage` canonical | Frozen | GitHub #194 and current runtime route construction agree | Owner |
| Keep `/login/email` alias | Frozen | Compatibility behavior and Email-mode test already exist | Owner |
| Do not migrate legacy success/navigation callbacks | Frozen | Session/bootstrap flow is authoritative | Owner |
| Correct stale task-note wording | Chosen | Required to satisfy exact zero-reference acceptance without changing product behavior | Codex |

## 4. Architecture Design

### Chosen Approach

Delete only the unreachable duplicate source and its public export. Preserve the canonical page, router builders, route contract, and session policy byte-for-byte.

### Ownership and Data Flow

```text
/login or /login/email
-> apps/app router
-> canonical LoginPage
-> existing Auth use cases/providers
-> existing session/bootstrap policy
```

### Alternative Rejected

Migrating callbacks, validation, navigation, synthetic-success behavior, or UI from dead code was rejected because it would broaden #194 and risk changing the canonical Auth contract.

### Failure and Accessibility States

Unchanged. The removed source has no runtime consumer; canonical `LoginPage` continues to own loading, validation, failure feedback, and unavailable Truecaller feedback.

## 5. Implementation Plan

- [x] Remove the dead duplicate source and obsolete barrel export.
- [x] Remove stale exact-name references from historical task notes.
- [x] Confirm canonical route/session source remains unchanged.
- [x] Run focused Auth/app analyze and route/session tests.
- [x] Run exact zero-reference and pre-commit Git scope checks.
- [ ] Commit, push, open PR, and update Linear with validation/PR link.

## 6. Quality Review

### Validation Run

```text
flutter analyze (machine-local Flutter SDK)
  - apps/features/auth: PASS (no issues)
  - apps/app: PASS (no issues)

flutter test test/presentation/login_page_test.dart
  - PASS (7 tests)
  - emitted the repository's existing use-material-design package warning

flutter test test/app/session/app_session_route_policy_test.dart
  - PASS (5 tests)

Repository-wide exact-name/path search
  - PASS (zero matches)

Canonical router/session/page/test diff versus origin/main
  - PASS (no changes)

git diff --check
  - PASS
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | — | Resolved | No pre-implementation blockers or overlapping PRs found | `4b808a0b` | Phase 1 audit |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-145-auth-email-login-cleanup.md`
- `.ai/tasks/design-system-slice-d-auth-account.md`
- `.ai/tasks/issue-24d-account-settings-username-migration.md`
- Auth presentation barrel
- Legacy duplicate email-login source (deleted)

### Actual Behavior

`LoginPage` remains the sole canonical login surface. Both login routes and existing session/bootstrap behavior are unchanged; only unreachable duplicate code and stale references were removed.

### Known Limitations

- Exact-head GitHub CI remains to be observed after the PR is pushed.
- The focused Auth test emitted the pre-existing `use-material-design` package/root warning; all tests still passed.

### Final Status

`PASS`
