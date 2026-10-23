# Feature Task: GitHub #596 Slice D1 — Quality Measurement Plan (Option 1)

**Status:** In progress
**Primary owner:** Repository AI Governance
**Affected platforms:** Documentation/process only (Multi-agent quality measurement across all platforms)

---

## Owner Approval and Scope Boundary

**Trigger:** None (Documentation and measurement planning; no independent product feature, visible UI/UX change, or Supabase table/column shape change).
**Approval status:** Approved for this bounded docs-only D1 slice.
**Approval evidence:** Owner's explicit `GO D1: GitHub #596 Quality Measurement Implementation` (Decision: `Option 1: Strict Prospective Cohort`) on 2026-10-23 in conversation.
**Approved product/UI/data-shape boundaries:** None.
**Explicit non-changes:** No app/watch/UI code, Auth/health data, Supabase schema/RLS/functions, CI workflows, branch protection, attribution guard, credentials, product architecture, new governance framework, #250/#571/#580 scope, or merge authorization.

---

## Active Handoff

**Planning owner:** GitHub #596
**Implementation owner:** Current AI Agent edit session on branch `docs/issue-596-d1-measurement-plan`
**Review owner:** Independent review requested via GitHub (`im-tio` / Codex / human)
**Implementation ownership state:** Active
**Ownership transition:** Fresh implementation owner established under owner approval from clean `main@21286e78fc3d899a739cc7abc658ffa765031806`
**Repository state last verified:** 2026-10-23, remote `main@21286e78fc3d899a739cc7abc658ffa765031806`
**Branch:** `docs/issue-596-d1-measurement-plan`
**HEAD SHA:** `0ada08d6e3c5262feb83fbdb73492a6520a8014a` (prior reviewed HEAD; this commit resolves D1-F07 zero-denominator semantics and D1-F08 SHA provenance)
**Observed working-tree state:** Clean working tree; PR #658 open (4 commits ahead / 0 behind)
**Observed uncommitted/dirty files:** None
**PR / tracker:** [GitHub PR #658](https://github.com/im-tnyx/tio-world/pull/658), parent [GitHub Issue #596](https://github.com/im-tnyx/tio-world/issues/596); no dedicated Linear mirror (TNYX-193 belongs to #250)
**Current implementation state:** PR #658 amended; prior D1-F01..D1-F06 verified fixed; D1-F07/F08 edge cases resolved
**Relevant execution surface:** `.ai/tasks/issue-596-d1-measurement-plan.md`, `.ai/tasks/README.md`
**Validation completed at SHA:** `0ada08d6`: GitHub-hosted Docs Hygiene CI run #39927198717 PASS (5s); Commit attribution guard run #39927196366 PASS (4s); Attribution guard runner PASS (11s); historical receipts preserved
**Validation remaining:** Exact-head checks on amended commit; re-review approval from `im-tio`
**Current blocker:** Awaiting re-review approval from `im-tio` and explicit owner `Go merge` authorization; do not merge or close #596
**Open review finding IDs:** D1-F01..D1-F08 resolved in this amendment
**Next exact action:** Push amended commit, verify exact-HEAD CI, await re-review approval from `im-tio` and owner merge directive

---

## Global UI / Design-System Guardrail

Not applicable for this docs-only process task. No Flutter UI, widgets, theme tokens, styling, or layouts are modified.

---

## 1. Discovery

### User Outcome
A transparent, evidence-backed quality measurement plan that tracks the next 10 consecutive eligible substantive PRs to empirically observe whether the repository's multi-agent evidence contract (Slice B1) and risk-based regression matrix (Slice C1) reduce unverified claims, caught defects, and post-merge rework without inventing ungrounded quality scores.

### Success Criteria
1. **Deterministic Cohort Boundary:** Strictly prospective cohort beginning immediately after owner authorization at `2026-10-23T12:55:54+05:30` (`2026-10-23T07:25:54Z`) and `main@21286e78fc3d899a739cc7abc658ffa765031806`.
2. **Deterministic Eligibility Rules:** Explicit, unambiguous inclusion and exclusion rules with documented rationale.
3. **13-Dimension Observable Schema:** Complete ledger schema capturing review provenance, exact SHAs, evidence completeness, rework commits, check results, regressions, and explicit `Unknown` classifications.
4. **Observable Mathematical Formulas:** Strict numerator/denominator definitions for governance metrics without arbitrary percentage multipliers or invented scores.
5. **Separation of Baselines:** Historical baseline sample clearly separated from prospective cohort slots.
6. **Parent AC Reconciliation:** Fact-checked status and evidence mapping for all parent #596 criteria (AC-01 through AC-09).
7. **Milestone Review Point:** Explicit review checkpoint at the 10th eligible PR merge.

### Scope
Documentation and measurement planning only.

### Non-Goals
- No product feature or UI implementation.
- No Supabase SQL, RLS, RPC, or migration changes.
- No retrospective cherry-picking of convenient historical PRs into the prospective cohort.
- No invented "developer productivity" or "quality index" metrics.
- No closing of GitHub Issue #596 or marking all checkboxes complete prior to observation.
- No branch-protection, CI workflow, or attribution rule modifications.

---

## 2. Codebase Exploration

### Verified Evidence
- **Parent Issue:** [GitHub #596](https://github.com/im-tnyx/tio-world/issues/596) (OPEN, reopened after PR #634 merge to track D1 measurement and parent acceptance).
- **Canonical Process Documents:**
  - `AGENTS.md`: Multi-agent boundaries, single implementation owner, visual safety, security validation.
  - `.ai/FEATURE_DEVELOPMENT.md`: 7-phase lifecycle, Final Status Decision Rule (`PASS | REVIEW | PARTIAL | BLOCKED`), Agent Roles.
  - `docs/development/TESTING_GUIDE.md`: Risk-Based Regression Selection matrix (codified in C1 via PR #633).
  - `.ai/tasks/TEMPLATE.md` & `.ai/tasks/README.md`: Evidence fields and task lifecycle rules.
- **Archived Foundations:**
  - [.ai/archive/2026-10-issue-596-b1-multi-agent-evidence-contract.md](../archive/2026-10-issue-596-b1-multi-agent-evidence-contract.md) (PR #631 / PR #632).
  - [.ai/archive/2026-10-issue-596-c1-risk-regression-policy.md](../archive/2026-10-issue-596-c1-risk-regression-policy.md) (PR #633 / PR #634).
- **Historical Comparison Baseline:** Slice A baseline audit sample PRs:
  - [PR #605](https://github.com/im-tnyx/tio-world/pull/605) (`bd55f80e`): Real Move sheets release-OFF assertion (2/2 P1 docs findings resolved pre-merge).
  - [PR #613](https://github.com/im-tnyx/tio-world/pull/613) (`a892e2db`): UNKNOWN Move mutation readback verification (Codex quota-blocked; manual self-comment noted).
  - [PR #626](https://github.com/im-tnyx/tio-world/pull/626) (`fbf13284`): Canonical default identity across Move (Chat bot approvals; 0 formal GitHub reviews).

---

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Prospective vs Retrospective Cohort | **Option 1 (Strict Prospective)** Chosen | Owner authorized Option 1 to eliminate post-hoc selection bias and measure live multi-agent execution from an exact verified boundary. | Owner |
| Primary Ledger Location | **GitHub #596 Issue Thread** Primary | Live tracking updates belong in issue comments to avoid git commit churn; this task brief serves as the durable specification and checkpoint. | Repository AI Governance |
| Process/Governance PR Eligibility | **Substantive Included / Mechanical Excluded** | Substantive process PRs changing rules/contracts are eligible; administrative task archival or typo PRs are explicitly excluded. | Repository AI Governance |
| AC-07 CI Misattribution Correction | **Confirmed Separate (#250)** | PR #652 Docs Hygiene CI was created under #250 to replace manual PowerShell runs, not as a #596 child enforcement task. | Repository AI Governance |
| AC-03 Desk Walkthrough vs Live Testing | **Distinction Codified** | Six C0 walkthroughs were desk policy audits. The 10 prospective PRs will measure natural workflows but cannot guarantee executing all 6 edge takeovers. | Repository AI Governance |

---

## 4. Architecture Design & Cohort Methodology

```
Owner Approval Boundary (2026-10-23T12:55:54+05:30 @ 21286e78)
  │
  ├── Consecutive Merged PRs on main
  │     ├── Eligible Substantive PR? ───► Slot into Prospective Cohort (PR #1 .. #10)
  │     └── Excluded PR (Archive/Typo/Bot)? ───► Log in Exclusion Ledger with Reason
  │
  └── 10th Eligible PR Squash-Merged
        │
        └── Audit Checkpoint: Compute Metrics & Compare with Baseline (Issue #596)
```

### 1. Cohort Boundary Definition
- **Authorization Timestamp:** `2026-10-23T12:55:54+05:30` (UTC: `2026-10-23T07:25:54Z`).
- **Baseline Git Reference:** `main@21286e78fc3d899a739cc7abc658ffa765031806` (`fix(workout): refresh expanded source routines after atomic Create+Move (#657)`).
- **Boundary Invariant:** Only PRs squash-merged into `main` strictly **after** this commit and timestamp are eligible for cohort evaluation. No PR merged prior to or at `21286e78` can be counted in the prospective cohort.

### 2. Eligibility & Exclusion Rules

#### Eligible Substantive PRs (Inclusions):
- **Phone Application:** `apps/app` (App shell, navigation, dependency injection, top-level routes).
- **Feature Packages:** `apps/features/*` (Workout, Nutrition, Auth, Settings, Onboarding, Profile presentation and controllers).
- **Core & Shared Packages:** `apps/shared`, `apps/core` (Domain models, calculation logic, reusable design components and contracts).
- **Wearable Platforms:** `apps/wear`, `apps/watchos` (Wear OS and Apple Watch companions, synchronization, platform channels).
- **Database & Security:** `supabase/**` (Postgres migrations, RLS policies, RPCs, Edge Functions, security roles).
- **CI & Repository Automation:** `.github/workflows/**` (CI workflows, check configurations, testing matrix).
- **Substantive Architecture/Process:** `docs/architecture/**`, `docs/development/**`, `AGENTS.md`, `.ai/FEATURE_DEVELOPMENT.md` when introducing or altering architecture contracts, testing policies, or engineering rules.

#### Explicit Exclusions (with documented rationale):
- **Mechanical Task Brief Archival:** Moving `.ai/tasks/*.md` to `.ai/archive/*.md` without changing process contracts.
  *Rationale:* Purely administrative lifecycle housekeeping; no substantive code, behavior, or testing risk.
- **Pure Mechanical / Typo / Formatting Fixes:** Minor whitespace, spelling, or comment-only edits not affecting behavior.
  *Rationale:* Trivial changes that do not exercise multi-agent quality gates or regression policies.
- **Automated Bot PRs:** Dependabot or automated dependency version updates.
  *Rationale:* Machine-generated single-step dependency bumps; does not represent human/AI multi-agent software engineering.
- **Unmerged / Abandoned / Closed PRs:** PRs closed without merge into `main`.
  *Rationale:* Only code merged to protected `main` becomes production/runtime truth.

### 3. Per-PR Measurement Schema (13 Verifiable Dimensions)
For every eligible PR, the following fields must be recorded in the measurement ledger:
1. **PR Identifier:** PR number, Title, and GitHub URL.
2. **Change Class & Risk Level:** Exhaustive taxonomy mapped to repository scopes with explicit precedence:
   - `Pure Domain` (`apps/shared`)
   - `Controller / Repository` (`apps/features/*` domain/data/state)
   - `UI / Routing / Design System` (`apps/app`, `apps/features/*` presentation, `apps/core` UI)
   - `Wearables & Sync` (`apps/wear`, `apps/watchos`)
   - `Auth, Health & Personal Data` (`apps/features/auth`, biometric, credential flows)
   - `Supabase / Database / RLS / RPCs` (`supabase/**`)
   - `CI, Tooling & Workflows` (`.github/workflows/**`, tooling scripts)
   - `Substantive Architecture & Governance Process` (`docs/architecture/**`, `AGENTS.md`, `.ai/FEATURE_DEVELOPMENT.md`, `TESTING_GUIDE.md`)
   - `Multi-Class / Mixed` (Classified by highest-risk touched boundary: Supabase/Security/Auth > Wear/Sync > UI/Routing > Domain/Controller > CI/Tooling > Architecture/Process)
   - `Other / Unknown` (Fallback with mandatory explicit explanation of touched scope)
3. **Author / Agent Provenance:** Implementing model, tool, or human (e.g. Cursor, Claude, Codex, Human).
4. **Source HEAD SHA:** Exact commit SHA of the reviewed PR tip.
5. **Merged SHA:** Exact squash merge commit SHA on `main`.
6. **Acceptance Evidence Completeness:** Evaluation of PR description against DoD (`Complete` / `Partial` / `Missing` / `Not applicable`). Requires mapping of AC → Changed Files → Test/Proof → Result → SHA.
7. **Review Provenance & Relationship:** Reviewer identity, tool, and relationship to implementer (`Independent` vs `Self-review` vs `Automated bot`).
8. **Review Verdict:** Formal GitHub review state (`APPROVED`, `COMMENTED`, `CHANGES_REQUESTED`, or `None`). Chat-only or external bot comments cannot be labeled `APPROVED`.
9. **Review Findings & Severity:** Count of distinct deduplicated findings by severity (`P0` critical blocker, `P1` blocking defect, `P2` correctness/maintainability, `P3` polish/docs) and their resolution (`Resolved` / `Deferred` / `Open`). Deduplication rule: A finding raised across multiple review comments or repeated across commits is counted once by its root issue ID.
10. **Post-Review Rework & Commit Provenance:** Did review findings generate subsequent commits? If yes, number of rework commits and was the final HEAD re-reviewed?
11. **Check Results (Required vs Supplemental vs Path-Filtered):** The required-check set for each PR is derived dynamically from its touched paths and live branch protection/ruleset evidence on `main` (where only `Commit attribution guard` is universally required; Flutter CI and Database CI are path-filtered). Each check run is classified as: `Required`, `Supplemental`, or `Not applicable (path-filtered)`; status is tracked independently distinguishing concrete code/security findings from external tool infrastructure/quota failures.
12. **Downstream Regression / Reopened Work (7-Day Observation Window):** Evaluated after a fixed 7-calendar-day (168-hour) observation horizon post-merge. Any verifiably linked post-merge regression, bug report, reopened task, or revert commit is recorded. If the 7-day window is not yet complete at evaluation time, status is explicitly recorded as `In observation (window open)`, not as zero regressions.
13. **Data Integrity / Unknown Classification:** Any unavailable or unverified field must be explicitly marked `Unknown`, never inferred or left blank.

### 4. Observable Metric Formulas (Strict Numerator/Denominator)

1. **Acceptance Evidence Completeness Rate ($R_{evidence}$):**
   $$R_{evidence} = \frac{\sum \text{Eligible PRs with Complete AC-to-Evidence Mapping}}{\text{Total Eligible Substantive PRs in Cohort (10)}}$$

2. **Review Provenance Completeness Rate ($R_{provenance}$):**
   $$R_{provenance} = \frac{\sum \text{Eligible PRs with Full Reviewer Identity, SHA, and Relation Recorded}}{\text{Total Eligible Substantive PRs in Cohort (10)}}$$

3. **Independent Review Metrics (Separated Activity vs Approval):**
   - **Independent Review Activity Rate ($R_{ind\_reviewed}$):**
     $$R_{ind\_reviewed} = \frac{\sum \text{Substantive PRs with Verified Independent Reviewer Activity (APPROVED, CHANGES\_REQUESTED, or Substantive COMMENTED)}}{\text{Total Eligible Substantive PRs in Cohort (10)}}$$
   - **Independent Approval Rate ($R_{ind\_approved}$):**
     $$R_{ind\_approved} = \frac{\sum \text{Substantive PRs Merged with Formal Independent APPROVED Review}}{\text{Total Merged Substantive PRs in Cohort (10)}}$$
   *(Denominator is fixed to the full cohort of 10 eligible substantive PRs, preventing post-hoc denominator manipulation).*

4. **Post-Review Exact-HEAD Revalidation Rate ($R_{revalidation}$):**
   $$R_{revalidation} = \frac{\sum \text{PRs with Rework that Re-Ran and Verified Exact-HEAD Checks}}{\sum \text{PRs with Review Findings Causing Code/Docs Rework}}$$
   *Zero-denominator rule:* If no PR in the cohort requires rework (denominator = 0), this rate is formally reported as `N/A (no review-caused rework; 0/0)` recording raw numerator and denominator counts, rather than a misleading `0%` or generic `Unknown`.

5. **Review Finding Yield ($Y_{findings}$) and Density ($D_{findings}$):**
   $$Y_{findings} = \sum P0 + \sum P1 + \sum P2 + \sum P3 \quad (\text{Categorized deduplicated findings caught pre-merge})$$
   $$D_{findings} = \frac{Y_{findings}}{\text{Total Eligible Substantive PRs in Cohort (10)}}$$
   *Comparison baseline rule:* Raw finding counts from 10 PRs cannot be directly compared with the 3-PR historical baseline; compare per-PR finding density ($D_{findings}$) and percentage severity distributions instead.

6. **Downstream Regression Rate ($R_{regression}$ across 7-Day Window):**
   - **Provisional Reporting (at 10th PR Merge Checkpoint):**
     At the merge of PR #10, report regression counts and rate only for cohort PRs whose 7-day (168h) observation window has completed ($N_{completed}$). PRs whose 7-day window remains open (e.g. PR #10) are explicitly reported as censored (`In observation (window open)`), not counted as zero regressions.
     $$R_{regression\_provisional} = \frac{\sum \text{Cohort PRs with Linked Regressions in Completed Windows}}{N_{completed}}$$
     *Zero-denominator rule:* If all 10 cohort PRs merge within 168 hours ($N_{completed} = 0$), the provisional rate is formally reported as `N/A (no completed windows; 0/0, 10 open)` along with the exact timestamp when the earliest window matures, rather than a computed `0%` or generic `Unknown`.
   - **Final Reporting (after all 10 PRs reach 7-day window):**
     $$R_{regression\_final} = \frac{\sum \text{Cohort PRs with Linked Reverts, Regressions, or Reopened Tasks within 7-Day Window}}{\text{Total Merged Cohort PRs with Completed 7-Day Window (10)}}$$
   *Attribution rules:* A regression is attributed if verifiably linked via: (a) a revert commit on `main`, (b) a reopened parent/child GitHub or Linear issue, or (c) a newly filed bug issue citing the PR or squash merge SHA.

### 5. Historical Comparison Baseline (Reference Only)

From Slice A baseline audit (`2026-10-18`), the observed characteristics prior to B1/C1 codification:
- **PR #605** (`bd55f80e`): Real Move sheets release-OFF assertion. 2/2 P1 docs findings resolved pre-merge. Attribution PASS. Codex review completed.
- **PR #613** (`a892e2db`): UNKNOWN Move mutation readback verification. Codex review quota blocked; author self-review noted; formal independent review unavailable.
- **PR #626** (`fbf13284`): Canonical default identity across Move. Chat-only bot approvals; 0 formal GitHub reviews; passing Database CI.
*Baseline Takeaway:* High test/CI compliance, but inconsistent review provenance recording, frequent confusion between chat-bot comments and formal GitHub approval, and lack of explicit AC-to-file-to-SHA mapping.

### 6. Prospective Cohort Tracking Ledger (Slots 1 to 10)

| Slot | PR # | Title & Platform | Change Class | Merged SHA | AC Evidence | Review Provenance | Verdict | Findings (P0/P1/P2/P3) | Rework & Revalidation | Check Results | Downstream Regression |
|:---:|:---:|---|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **PR 01** | *Pending* | *Awaiting next eligible PR* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* |
| **PR 02** | *Pending* | *Awaiting eligible PR* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* |
| **PR 03** | *Pending* | *Awaiting eligible PR* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* |
| **PR 04** | *Pending* | *Awaiting eligible PR* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* |
| **PR 05** | *Pending* | *Awaiting eligible PR* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* |
| **PR 06** | *Pending* | *Awaiting eligible PR* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* |
| **PR 07** | *Pending* | *Awaiting eligible PR* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* |
| **PR 08** | *Pending* | *Awaiting eligible PR* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* |
| **PR 09** | *Pending* | *Awaiting eligible PR* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* |
| **PR 10** | *Pending* | *Awaiting eligible PR* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* | *Pending* |

*Note on dynamic tracking:* Each slot will be populated dynamically in the GitHub #596 issue tracker thread as PRs merge.

---

## 5. Parent Acceptance Criteria (AC-01 through AC-09) Reconciliation

| Criterion | Stated Expectation | Evidence-Based Status | Grounded Verification Evidence | Remaining Gap / Exact Limit |
|---|---|---|---|---|
| **AC-01** | Baseline audit completed with direct references to current files, sample PRs, and actual gaps; existing controls explicitly credited. | **Verified** | Slice A baseline audit (`2026-10-18`) in #596 comments analyzed `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, and historical PRs #605, #613, #626. | None. Baseline complete. |
| **AC-02** | Documented authority map has one canonical owner per process rule, with no conflicting root/nested instructions. | **Verified** | Slice B1 PR #631 (`6000fe81`, archived in PR #632) established `docs/README.md` as doc authority, `.ai/FEATURE_DEVELOPMENT.md` as process authority, and `.ai/tasks/README.md` as execution evidence authority. | None. Authority map codified. |
| **AC-03** | Multi-agent role/ownership/handoff contract supports arbitrary agent switching and role permutations, including mid-task limit recovery, same-agent sequential roles, third-party audits/prompts, previous-owner return and independently evidenced review, without authorizing multiple implementers to write the same slice. | **Partially verified** | PR #631 codified Agent Roles and single-ownership transfer rules. Slice C0 documented 6 scenario walkthroughs (C0-S01 to C0-S06) against `main@b327a63a`. | **Gap:** C0 was a policy-level desk audit, not live execution. Ten prospective PRs will observe natural workflows but cannot guarantee triggering all 6 edge-case handoffs. |
| **AC-04** | Definition of Done maps acceptance criteria to evidence; `PASS/REVIEW/PARTIAL/BLOCKED` semantics are clear for passed/failed/unavailable checks. | **Verified** | PR #631 codified the Final Status Decision Rule and Required Gates in `.ai/FEATURE_DEVELOPMENT.md`. PR #633 integrated evidence and merge gates into `TESTING_GUIDE.md`. | None. Decision rule codified. |
| **AC-05** | Risk-based test/review matrix covers UI regressions and protected data/security cases without forcing unrelated expensive checks. | **Verified** | PR #633 (`0627cdac`, archived in PR #634) added the 7-class Risk-Based Regression Selection matrix to `docs/development/TESTING_GUIDE.md`. | None. Matrix codified. |
| **AC-06** | Existing approved owner gates, visual preservation, source-of-truth precedence, strict tenant/privacy controls, required CI and attribution guard are preserved. | **Verified** | Verified across B1 and C1 PRs; no security, UI, or owner approval gates were weakened or bypassed. | None. Core guardrails preserved. |
| **AC-07** | Any needed CI automation, tests, tooling or ruleset changes are tracked as separate approved child work and linked here. | **Verified (Separate Scope Preserved)** | No dedicated child CI automation was required or introduced for #596. Docs Hygiene CI (PR #652/#653) belongs to separate Issue #250. Separate scopes (#250, #571, #580) were strictly preserved. | None. No conflated child work. |
| **AC-08** | Applicable docs-only checks (at minimum `git diff --check`) actually run for the eventual process-doc PR; its PR contains changed-file audit, independent review findings, evidence and limitations. | **Verified for #596 PRs** | PRs #631, #632, #633, and #634 executed exact-HEAD `git diff --check` (exit 0), included scope audits, and recorded review provenance (`im-tio`). (PR #652 excluded as it belongs to #250). | None for merged PRs; will apply to this D1 PR as well. |
| **AC-09** | 10-PR measurement plan is documented with observable sources and an explicit point of review; do not claim uplift until observed. | **Unverified (Pending D1)** | D1 prospective measurement plan is established in this brief. The 10 PR cohort is awaiting observation. | **Gap:** Observation of the 10 prospective PRs must occur before this criterion is marked verified. |

---

## 6. Quality Review

### Validation Run
- `git diff --check`: Exit 0 (Verified locally before commit).
- Changed file scope: Exactly two files touched (`.ai/tasks/issue-596-d1-measurement-plan.md` and `.ai/tasks/README.md`).
- Markdown reference check: All relative links verified against repository structure.

### Acceptance Evidence (Substantive Process Scope)

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| D1-AC01 Cohort Boundary | `.ai/tasks/issue-596-d1-measurement-plan.md` | Defined at `main@21286e78` / `2026-10-23T12:55:54+05:30` | `21286e78` on Windows | None (Exact git commit referenced) |
| D1-AC02 Eligibility Rules | `.ai/tasks/issue-596-d1-measurement-plan.md` | Explicit inclusion/exclusion criteria with documented rationale | `21286e78` on Windows | None (No ambiguous categories) |
| D1-AC03 13-Dimension Ledger | `.ai/tasks/issue-596-d1-measurement-plan.md` | Full schema with explicit `Unknown` and finding severity fields | `21286e78` on Windows | None (Matches B1/C1 contracts) |
| D1-AC04 Metric Formulas | `.ai/tasks/issue-596-d1-measurement-plan.md` | 6 mathematical formulas with explicit numerators and denominators | `21286e78` on Windows | None (Zero invented scores) |
| D1-AC05 Parent AC Audit | `.ai/tasks/issue-596-d1-measurement-plan.md` | Fact-checked table for AC-01..AC-09 with corrected AC-03, 07, 08 | `21286e78` on Windows | None (Reflects verified reality) |

### Review Provenance
- **Review source / link:** [GitHub PR #658](https://github.com/im-tnyx/tio-world/pull/658)
- **Reviewer / relation:** Independent review completed by `im-tio` (Collaborator, separate from author)
- **Reviewed SHA:** `0ada08d6e3c5262feb83fbdb73492a6520a8014a` (PR commit 4, re-reviewing prior `828dc92e3a5c25181742d4a962f1074d1afe0c49` and `beec9099170c61eb28b2a5b1297b5cc14e3fc77e`)
- **Review verdict:** `CHANGES_REQUESTED` by `im-tio` on `0ada08d6` (prior D1-F01..D1-F06 verified fixed; new edge cases D1-F07 zero-denominator semantics and D1-F08 SHA provenance resolved in this amendment). External tool notes:
  - Codex code review: Failed due to usage limit exhaustion (infrastructure limit, no code finding).
  - Cursor Bugbot: Failed due to usage limit exhaustion (infrastructure limit, no code finding).
  - Copilot pull request reviewer: Failed due to usage limit exhaustion (infrastructure limit, no code finding).
- **Limitations:** Formal re-review pending from `im-tio` on amended HEAD; no formal `APPROVED` review claimed yet.
### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| D1-F01 | P2 | Resolved | Change class taxonomy lacked CI/process classes and precedence rules | `beec9099` | Exhaustive 10-class taxonomy + mixed precedence + Other/Unknown fallback added |
| D1-F02 | P2 | Resolved | Omission of P0 findings from schema, table, and finding yield formula | `beec9099` | P0 added to schema, table header, yield formula, deduplication rule, and density metric |
| D1-F03 | P2 | Resolved | Hardcoded Flutter & Database CI as required across entire cohort | `beec9099` | Dynamic per-PR check classification (Required vs Supplemental vs Path-Filtered) codified |
| D1-F04 | P2 | Resolved | Independent review conflated with formal approval; denominator unanchored | `beec9099` | Separated into Activity Rate ($R_{ind\_reviewed}$) and Approval Rate ($R_{ind\_approved}$), fixed to 10 PRs |
| D1-F05 | P2 | Resolved | Unequal post-merge observation horizon biased regression metric | `beec9099` | Fixed 7-calendar-day (168h) window established; open windows censored as `In observation` |
| D1-F06 | P3 | Resolved | Final status pinned to older commit SHA `75755a8a` instead of current PR HEAD | `beec9099` | Corrected reviewed SHA `beec9099170c61eb28b2a5b1297b5cc14e3fc77e` and updated exact-HEAD receipt |
| D1-F07 | P2 | Resolved | Undefined zero denominator for provisional regression and revalidation rates | `0ada08d6` | Explicit N/A semantics, raw count reporting, and open-window maturation tracking added to formulas 4 & 6 |
| D1-F08 | P3 | Resolved | PR description and comment receipts cited imprecise commit SHAs | `0ada08d6` | Exact 40-character SHAs verified via `git rev-parse`; PR description synchronized |

---

## 7. Final Handoff

### Changed Files
- `.ai/tasks/issue-596-d1-measurement-plan.md` (New durable task brief specifying prospective measurement plan)
- `.ai/tasks/README.md` (Active task index entry for D1 measurement plan)

### Actual Behavior
Establishes the canonical execution contract for GitHub #596 Slice D1: Option 1 Strict Prospective Cohort. Defines cohort boundaries, eligibility, ledger schema, metric formulas, review checkpoint at PR #10, and reconciles parent acceptance criteria AC-01 through AC-09.

### Known Limitations
- The 10 PR cohort is prospective; actual metrics cannot be computed until 10 eligible substantive PRs merge.
- Multi-agent handoff edge scenarios (C0-S01..S06) are observed only as they naturally occur in the cohort, not as a synthetic stress drill.
- Parent #596 remains OPEN and acceptance checkboxes remain unchecked until live measurement completes.

### Final Status
**`REVIEW`** (Implementation complete, PR #658 amended resolving D1-F01..D1-F08; CI green on `0ada08d6` [Docs Hygiene #39927198717]; awaiting exact-HEAD CI and re-review approval from `im-tio` before owner `Go merge`. Not `PASS` until gates pass; do not merge).
