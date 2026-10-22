# Docs Hygiene CI — exact-HEAD documentation diff guard

**Status:** In progress — separate PR under review; no protected-main merge or required-check policy change
**Primary owner:** GitHub CI / repository developer experience
**Affected platforms:** GitHub Actions only (no Flutter, Wear, Supabase or backend runtime)

## Owner Approval and Scope Boundary

**Trigger:** None (CI validation inside the already discussed Docs Hygiene workflow request)
**Approval status:** Approved — owner `Go` on 2026-10-22, after the explicit proposal to add a separate Docs Hygiene CI PR for docs-only exact-head validation.
**Approved scope:** New, single-purpose `.github/workflows/docs-hygiene-ci.yml`, plus this focused execution handoff. Target `.ai/**`, `docs/**`, and the workflow's own YAML on PRs to `main`.
**Explicit non-changes:** No edits to PR #651's files/branch; no `.ai/tasks/README.md` index change during overlapping PR #651; no Flutter/mobile/watch code, Supabase migrations/ACL/RLS, secrets, protected attribution workflow, branch protection/ruleset, CODEOWNERS, existing tests or production services.

## Active Handoff

**Planning owner:** Owner-approved CI hygiene slice, separate from GitHub #250/TNYX-193 and PR #651.
**Implementation owner:** This isolated GitHub CI branch only.
**Review owner:** Independent `im-tio` requested after PR creation; no pre-emptive approval implied.
**Implementation ownership state:** Active until reviewed/validated.
**Repository state last verified:** Protected GitHub `main@ba611e7e35692597896ee0bfc9b03be1a81252c6`; local Windows checkout unavailable to GitHub-only agent.
**Branch:** `ci/docs-hygiene-exact-pr-head`
**HEAD SHA:** Always read live PR metadata; this checked-in file cannot validate its own final commit SHA.
**Observed working-tree state:** Not accessible remotely; no local cleanliness assertion.
**Current blocker:** Independent formal review, observed GitHub-hosted CI, and owner's separate merge authorization.
**Next exact action:** Verify exact new-HEAD checks and workflow job logs, inspect reviewer inline findings, validate GitHub CI's own positive/negative coverage, then owner-only merge gate. New workflow cannot be credited with validating old PR #651 unless an actual run targets that exact SHA.

## Behavior and Trust Boundary

- `pull_request` to `main`, path-filtered to `.ai/**`, `docs/**`, or this workflow YAML. It is a **supplemental** check; do not add it to branch protection as required without independently approved skip-safe policy.
- Job uses read-only `contents: read` and checks out the PR event's exact **trusted base SHA**, not untrusted proposed changes. Credentials are not persisted.
- Fetch `refs/pull/<number>/head` as Git object data, assert fetched SHA equals event head SHA; fail closed for a changed PR head. Assert base checkout SHA, merge-base availability, then check exactly the changed documentation paths with `git diff --check BASE...HEAD` (three-dot diff). No PR executable, shell, or script is run.
- Historical PRs do not automatically acquire this check once the workflow merges. A new applicable PR event or a separately reviewed validation mechanism is necessary; a CI run on the wrong SHA does not prove #651.
- This check verifies Git diff whitespace/conflict hygiene only, not documentation semantics, all Markdown links, security scans, full application tests, reviewer approval, or canonical drift acceptance.

## Evidence and Validation Boundaries

- Audited existing six GitHub workflows: only the required `Commit attribution guard` ran on docs-only PR #651; its job checks prohibited AI attribution, **not** `git diff --check`. Existing Flutter/Android/Supabase workflows are path-filtered to their own scopes; no duplicate workflow exists.
- Before commit: stand-alone YAML parsed successfully (GitHub `on.pull_request` and permissions checked), embedded Bash passed `bash -n`, temporary Git fixture produced PASS on a clean renamed Markdown diff and expected nonzero FAIL on a whitespace defect.
- Fixture/static results are **not GitHub-hosted CI evidence**. This workflow must actually execute at the exact PR SHA before being described as CI PASS.
- GitHub CI validation cannot substitute for a required *owner-local* receipt if the independent reviewer/owner explicitly retains that prerequisite; seek explicit independent updated review disposition before claiming the gate replaced.
- PR #651 remains independently reviewed as `COMMENTED` at `eef57a7089f8312d7dfcf97ec483bff47dd932c3`, with no actionable changed-line defects but missing accepted exact-head diff validation; no status of PR #651 is modified in this CI slice.

## Exit Conditions

Read-only permissions; no privileged execution; exact SHA guard; positive/negative Git diff behavior evidenced; correct path filters; scoped successful GitHub Actions run on new PR head; no forbidden files changed; independent review findings resolved. Required attribution check remains pinned and unchanged. Separate owner `Go merge` for this CI PR.
