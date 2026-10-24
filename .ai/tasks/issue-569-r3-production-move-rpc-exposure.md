# GitHub #569 R3 — Production Move RPC authenticated exposure PR

**Status:** In progress — code review and explicit hosted exposure/deploy gates pending.
**Primary owner:** Supabase/Postgres implementation (GitHub `im-tnyx`)
**Affected platforms:** Supabase functions/ACL; Database CI; Flutter production gate unchanged.

## Owner Approval and Scope Boundary

**Trigger:** Continuation of already approved #569 Move feature; explicit policy exposure decision.
**Approval status:** User initiated R3 PR work with "start kare" immediately after being asked whether to grant all permanent signed-in accounts access to exactly three Move RPCs. This is consent to start preparation/review, **not** authorization for hosted apply or mobile release. Confirm the exact role-wide exposure policy again before merging/deploying if reviewer/owner governance requires unambiguous written sign-off.
**Approved boundaries:** Only exact three PostgreSQL function EXECUTE grants to `authenticated`, with RLS/owner/anonymous protections preserved; no data-shape change.
**Explicit non-changes:** No hosted SQL apply, no broad table grants, no Flutter flag ON, no UI change, no general Program Delete #567.

## Active Handoff

**Planning owner:** GitHub #569 / Linear TNYX-81 and TNYX-267
**Implementation owner:** `im-tnyx` R3 ACL grant PR only
**Review owner:** Codex and distinct reviewer; genuine human security sign-off remains a separate gate.
**Implementation ownership state:** Active
**Repository state last verified:** GitHub `main@c0c90caa9a092ebd1572e7ad96f76aeac39eed34` (PR #673 squash merge); no access to user's local Windows checkout from this remote session.
**Branch:** `tnyx/569-r3-production-move-rpc-access`
**Observed working-tree state:** Remote branch based exactly on main; local checkout not inspected.
**PR / tracker:** #569 OPEN; #567 OPEN; Linear TNYX-81/TNYX-267 Backlog.
**Current implementation state:** PR #674 at source head `a37baef5a5d1676538f36b161c2456da049b6dc6` replayed the 70 migrations and passed the rollback drill, #569 ownership/idempotency/race matrices, security ACL assertions, DB lint check, Docs Hygiene, and attribution. Hosted grants unchanged. This handoff-only update creates a new final PR HEAD whose exact-head CI must be checked separately.
**Validation completed at SHA:** Source/initial PR HEAD `a37baef5a5d1676538f36b161c2456da049b6dc6`: Database CI `40094780962` SUCCESS, Docs Hygiene `40094780964` SUCCESS, Attribution Guard `40094780950` SUCCESS. CI source-run test receipts are evidence for that SHA only.
**Validation remaining:** Re-run/reverify all required checks on this new handoff-only HEAD; human security review and exact owner role-wide exposure authorization; Codex review was unavailable due to usage limits, not a PASS; owner-hosted apply GO is a separate gate. Device/release QA later.
**Current blocker:** External human security review and hosted deployment release approval.
**Next exact action:** Execute and review exact-head PR CI; resolve findings. Stop before merge/hosted apply.

## 1. Discovery

### User Outcome
Make direct Move, Create & Move and 5-second full Undo eligible for production without granting direct Program DELETE or Routine parent UPDATE.

### Success Criteria
- All permanent signed-in users have only exact three function EXECUTE when the migration is **eventually applied**.
- `PUBLIC`, `anon`, `service_role` EXECUTE denied.
- Anonymous Auth users with role `authenticated` rejected inside RPC bodies using `auth.users.is_anonymous=false`.
- Foreign owners, stale revisions, modified destination B and unsafe Undo fail closed.
- Actual migration + rollback drill and existing race/SQL fixtures PASS on a disposable replay.
- Hosted state remains unchanged during this PR review.

### Scope
One guarded grant migration, updated ACL contract, one transaction-rollback test and CI invocation.

### Non-goals
No hosted apply, no R4 Flutter activation, no #567 destructive delete, no new allowlist/feature-service, no schema or RPC body changes.

## 2. Codebase Exploration

**Verified evidence:** `main@c0c90caa9a092ebd1572e7ad96f76aeac39eed34`, PR #673 merged; existing #569 ACL CI helper tests denied/granted fixture cleanup. Hosted Supabase (read-only) had 69 migrations through `20261024090000`, all three `postgres` SECURITY DEFINER empty-search_path functions present and denied to `PUBLIC`/`anon`/`authenticated`/`service_role`; Program/Routine RLS on, direct authenticated Program DELETE and Routine program_id UPDATE denied. `routineMoveReleaseEnabledProvider=false`.

**Existing pattern:** 20261021120000 granted single protected first-Routine RPC while Flutter release flag remained OFF.

## 3. Clarification

| Decision | Status | Owner / authority |
| --- | --- | --- |
| Prepare R3 PR | Authorized to start | User "start kare" after direct proposal |
| Expose exact 3 APIs to all permanent signed-in | R3 policy for review; require explicit release-gate confirmation | Owner |
| Hosted apply | NOT AUTHORIZED | Separate explicit GO |
| Production Flutter ON | NOT AUTHORIZED | R4/R5 separate GO |
| #567 as Move release blocker | Pending exact limited-release decision | Owner |

## 4. Architecture Design

Use a new imperative Supabase migration with preflight on exact three signatures, owner, SECURITY DEFINER, hardened search_path, body-auth checks, RLS and direct writes. Revoke unintended roles, then GRANT EXECUTE only to `authenticated`. No other privileges change. The Flutter flag is not an API security boundary.

**Security advisor impact:** These three additional callable SECURITY DEFINER functions are expected to produce new authenticated-security-definer warnings when deployed. Their source admission/owner checks must be independently reviewed; do not suppress warnings as blanket false positives.

**Rollback:** A separate approved operational action revokes authenticated EXECUTE on the three exact identities. Source remains and committed data is retained. Revocation prevents *new* calls, not already-running transactions; UNKNOWN receipts require owner-scoped reconciliation. An intentionally separate CI SQL test exercises the rollback inside a `BEGIN ... ROLLBACK` transaction and restores the intended granted state.

## 5. Implementation Plan

- [x] Audit live hosted and source R2 baseline.
- [x] Prepare exact three-signature guarded migration (not applied).
- [x] Update central ACL current-state expectation to authenticated-only granted (after replay).
- [x] Add disposable transactional rollback regression.
- [x] Wire rollback test into DB CI.
- [x] Source HEAD `a37baef5` Database CI migration/SQL/races/lint PASS; final handoff-only HEAD CI pending.
- [ ] Obtain Codex, independent review and genuine human security sign-off.
- [ ] Reconcile owner exposure and staged hosted deploy decision.

## 6. Quality Review

**Validation run:** GitHub Actions source HEAD `a37baef5` passed [Supabase Database CI 40094780962](https://github.com/im-tnyx/tio-world/actions/runs/40094780962), including full migration replay (70 SQL versions), R3 revoked-in-transaction rollback drill, central authenticated-only ACL gate before/after existing #569 operations and two-session races, denied/granted fixture cleanup and DB lint. [Docs Hygiene 40094780964](https://github.com/im-tnyx/tio-world/actions/runs/40094780964) and [Attribution 40094780950](https://github.com/im-tnyx/tio-world/actions/runs/40094780950) succeeded. These are cloud CI results; local Windows Flutter/device or production writes were not performed. This documentation amendment requires new exact-head checks.

**Review provenance:** GitHub Codex review at `a37baef5` FAILED due account quota limit (not a finding or security PASS). Cursor automated checks returned NEUTRAL due limits. Human security sign-off pending; connected distinct-account assistant review, if performed, must be labeled non-human. Do not merge/deploy based on green DB CI alone.

## 7. Final Handoff

**Changed files:** One migration, one access-contract test, one rollback drill, workflow and this task/index.
**Actual hosted behavior:** unchanged until explicit hosted apply. All 3 functions remain EXECUTE denied as of pre-PR read-only verification.
**Known limitations:** No independent human sign-off, no Android/iOS release-build QA, no Flutter flag.
**Final status:** REVIEW — source CI passed, but the final PR HEAD and independent human security/exposure/deployment authorization gates remain pending.
