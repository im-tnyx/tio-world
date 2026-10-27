# Feature Task: GitHub #596 Slice D1 — Quality Measurement Plan (Option 1)

**Status:** In progress (D1-E1 and D1-E2 all 10 PRs evidence normalized to Partial; full-channel census and seven-day observations pending)
**Primary owner:** Repository AI Governance
**Affected platforms:** Documentation/process only (Multi-agent quality measurement across all platforms)

---

## Owner Approval and Scope Boundary

**Trigger:** None (Documentation and measurement planning; no independent product feature, visible UI/UX change, or Supabase table/column shape change).
**Approval status:** Approved for this bounded docs-only D1 slice.
**Approval evidence:** Owner's explicit `GO D1: GitHub #596 Quality Measurement Implementation` (Decision: `Option 1: Strict Prospective Cohort`) on 2026-10-23 in conversation; followed by owner explicit `go merge` authorization for PR #658 on 2026-10-23.
**Approved product/UI/data-shape boundaries:** None.
**Explicit non-changes:** No app/watch/UI code, Auth/health data, Supabase schema/RLS/functions, CI workflows, branch protection, attribution guard, credentials, product architecture, new governance framework, #250/#571/#580 scope, or parent issue #596 closure.

---

## Post-Merge Validated Outcome (PR #658)

- **PR / Merge Receipt:** [GitHub PR #658](https://github.com/im-tnyx/tio-world/pull/658) squash-merged into protected `main` at `6a4e113b06bc714039199f94d38ce59e4e0515b7` on 2026-10-23T09:14:18Z.
- **Reviewed Source HEAD SHA:** `d7d50bdf910769c500e8ae16a956ca062edfd16a`.
- **Independent Review Provenance:** Independent review completed and formal `APPROVED` verdict submitted by authenticated collaborator `im-tio` on reviewed source HEAD `d7d50bdf` at 2026-10-23T09:12:27Z.
- **Review Finding Disposition:** All 8 findings D1-F01 through D1-F08 verified resolved in current repository source before merge.
- **Check Outcomes:**
  - `Commit attribution guard`: SUCCESS (run #39928982511).
  - `Attribution guard runner`: SUCCESS (run #39928982511).
  - `Docs Hygiene CI`: SUCCESS (run #39928984283; native `git diff --check` passed with exit 0).
  - Cursor Bugbot / Security / Approval Agent: NEUTRAL (quota/integration limit; no code defect).
  - Copilot / Codex: Quota limit noted; no unverified passes claimed.
- **Local Synchronization:** Owner local `main` synchronized clean via fast-forward merge to `6a4e113b06bc714039199f94d38ce59e4e0515b7`; local `git diff --check` passed with exit 0.
- **Current Lifecycle State:** Plan specification is validated and merged. The first 10 consecutive eligible substantive PRs are **SELECTED** in GitHub #596; evidence normalization and 168-hour post-merge observation are **ACTIVE**. Parent [GitHub Issue #596](https://github.com/im-tnyx/tio-world/issues/596) remains **OPEN**.

---

## Active Handoff

**Planning owner:** GitHub #596 / Repository AI Governance; D1 Option 1 strict fixed first-ten cohort, no restart or extra PRs
**Implementation owner:** Repository AI Governance — bounded D1-E2 final-five evidence documentation, no application/runtime ownership
**Review owner:**  reviewer account where available; review is not security sign-off
**Implementation ownership state:** Active (GitHub-only docs branch, owner-approved D1-E2; Windows checkout inaccessible)
**Ownership transition:** Prior E1 [PR #683](https://github.com/im-tnyx/tio-world/pull/683) squash-MERGED at `bba5d59ded79e430ab59b238050224569e1f1c02` (obsolete OPEN handoff corrected); sibling C1G [PR #684](https://github.com/im-tnyx/tio-world/pull/684) MERGED at `29cf8656d20d253bc981d4bd1a4d19e6334efe28`; the parent #596 remains OPEN
**Repository state last verified:** 2026-10-25 protected remote `main@29cf8656d20d253bc981d4bd1a4d19e6334efe28` (C1G sibling merged, includes E1)
**Branch:** `docs/issue-596-d1-e2-final-five-evidence-20261025`
**HEAD SHA:** Live GitHub branch / PR HEAD is authoritative. `29cf8656d20d253bc981d4bd1a4d19e6334efe28` is the immutable branch-creation **base**, not a current edited-head claim
**Observed working-tree state:** Local `G:\projects\Tio-World` state Unknown; no access or sync claim from GitHub connector
**Observed uncommitted/dirty files:** Unknown (not inspected)
**PR / tracker:** [GitHub Issue #596](https://github.com/im-tnyx/tio-world/issues/596) OPEN. D1-E1 PR #683 MERGED; [D1-E2 PR #685](https://github.com/im-tnyx/tio-world/pull/685) OPEN; current PR source HEAD is GitHub authority (CI/review gate). No positively identified dedicated #596 Linear mirror; TNYX-193 tracks separate GitHub #250, TNYX-201 app-shell and TNYX-81/TNYX-267 Workout
**Current implementation state:** First five E1 [§6A](#6a-d1-e1--first-five-cohort-pr-evidence-normalization-2026-10-25), last five E2 [§6B](#6b-d1-e2--last-five-cohort-pr-evidence-normalization-2026-10-25) documented as Partial representative evidence with exact historical source heads, review roots, fix commits and original-HEAD checks. Known inline-only roots: 20/20 resolved severity-tagged (P0=0/P1=2/P2=12/P3=6). Not an all-review-channel total
**Relevant execution surface:** `.ai/tasks/issue-596-d1-measurement-plan.md`, `.ai/tasks/README.md` only. Historical PRs, canonical docs, GitHub check runs and hosted Supabase catalog read-only; no runtime modifications
**Validation completed at SHA:** Historical original-HEAD checks for all ten cohort PRs were independently inspected from GitHub; E2 #668/#676 Flutter, #673/#674 disposable DB, #677 Docs Hygiene, plus final-head attribution/Docs Hygiene PASS across all five. These are **historical checks, not** current D1-E2 docs-branch validation
**Validation remaining:** D1-E2 new PR exact-HEAD docs diff/hygiene and attribution + technical review; complete all-channel root census and review-rework/revalidation denominators where source access allows; full 168h linked-regression observation and final evaluation
**Current blocker:** No numeric quality uplift, complete review coverage, valid revalidation ratio or downstream regression rate until evidence fully reconciled; latest 168h observation ends `2026-10-31T17:31:09Z` (23:01:09 IST). Hosted cross-owner/guest/JWT QA, device release acceptance and independent security review are separate #569/#675 boundaries, not D1 evidence PASS
**Open review finding IDs:** All twenty known inline-root threads in cohort resolved; any new D1-E2 docs-PR findings must be separately dispositioned on the current head
**Next exact action:** Inspect live [PR #685](https://github.com/im-tnyx/tio-world/pull/685) changed-file scope and exact-head docs CI, attribution and review; STOP for owner `Go merge`; do not close parent #596.

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

| Slot | PR # | Title & Platform | Change Class | Merged SHA | Reviewed source HEAD | AC Evidence | Review Provenance | Verdict | Findings (P0/P1/P2/P3) | Rework & Revalidation | Check Results | Downstream Regression |
|:---:|:---:|---|---|:---:|:---:|---|---|:---:|---|---|---|---|
| **PR 01** | [#660](https://github.com/im-tnyx/tio-world/pull/660) | Flutter direct Move UX | UI / Routing | `6dee84bfd018e13a7f8674560c07f719cfb0f5e9` | `b0c9cd13d98cfff383921f26f3c0c74fbfa21f7a` | **Partial — E1 mapped subset below**  | APPROVED at HEAD | 0/0/1/0 (inline only, resolved) | P2 app-route test correction in final source; earlier reviewed SHA not retained as a separate PR commit, so review-caused commit count Unknown | Exact-HEAD Flutter, attribution and Docs Hygiene SUCCESS (observed); ruleset requiredness Unknown | In observation (7-day window open) |
| **PR 02** | [#661](https://github.com/im-tnyx/tio-world/pull/661) | Existing Program Undo | UI / Routing | `16dbb6dbee51035280bfa8dec97153273cd764be` | `07b86b4f33736810e3bc7960b352015472868e32` | **Partial — E1 mapped subset below**  | APPROVED at HEAD (earlier CHANGES_REQUESTED) | 0/0/5/1 (inline only, resolved) | 3 source-linked post-Codex-review fix commits: `844e5978`, `127a5a00`, `07b86b4f`; final-HEAD Flutter/Docs/attribution PASS | Exact-HEAD Flutter, attribution and Docs Hygiene SUCCESS (observed); ruleset requiredness Unknown | In observation (7-day window open) |
| **PR 03** | [#663](https://github.com/im-tnyx/tio-world/pull/663) | Manual mobile QA build | CI / Tooling | `9811086ed05db877ffc619fddea4fde284299f42` | `19ccf3f5ccd77feb24d27bcb6b274d5fc3dc261c` | **Partial — E1 mapped subset below** | APPROVED at HEAD (earlier COMMENTED) | 0/0/0/1 (inline only, resolved) | 1 review-related docs-handoff commit `19ccf3f5`; final-HEAD CI PASS; manual QA builds/device smoke NOT RUN | Exact-HEAD Flutter, attribution and Docs Hygiene SUCCESS (observed); ruleset requiredness Unknown | In observation (7-day window open) |
| **PR 04** | [#664](https://github.com/im-tnyx/tio-world/pull/664) | Atomic Create+Move full Undo | Supabase / RPC | `9805ee1b58f38d04e5b692aa049ef9e280bcf850` | `72ddd28168c15c415c63c8e641242fee6b8c4420` | **Partial — E1 mapped subset below**  | APPROVED at HEAD (earlier COMMENTED) | 0/2/1/2 (inline only, resolved) | 5 source-linked fix commits `3caa3646`, `e0733baa`, `7c57ab18`, `3fd2ce17`, `72ddd281`; no exact all-review rework total asserted | Exact-HEAD disposable DB, attribution and Docs Hygiene SUCCESS (observed); hosted JWT QA NOT RUN | In observation (7-day window open) |
| **PR 05** | [#665](https://github.com/im-tnyx/tio-world/pull/665) | Flutter full Undo integration | UI / Repository | `19703d794b9593a104ccd3cf2b8f86ea2b634dd8` | `80a62755e222a2eabf7a490355a9ceab0c085aad` | **Partial — E1 mapped subset below**  | APPROVED at HEAD (earlier CHANGES_REQUESTED) | 0/0/1/0 (inline only, resolved) | 2 source-linked correction commits `0035df46` and `c05cc00b`; final-HEAD Flutter/Docs/attribution PASS | Exact-HEAD Flutter, attribution and Docs Hygiene SUCCESS (observed); hosted/device QA NOT RUN | In observation (7-day window open) |
| **PR 06** | [#668](https://github.com/im-tnyx/tio-world/pull/668) | Account Settings route extraction | UI / Routing | `69f4e8643e22a9c96c47e0b99ed4c525a119f99e` | `f8527b699c12ca931b11fb02445d6b3cec64f1df` | **Partial — E2 mapped subset below** | APPROVED at final HEAD | 0/0/0/0 (inline-only; not zero in all channels) | No inline-root-driven rework observed; total review-driven commit count Unknown; 5 PR commits include source + handoff | Final-HEAD Flutter matrix, attribution, Docs Hygiene SUCCESS; requiredness Unknown | In observation, 168h not complete |
| **PR 07** | [#673](https://github.com/im-tnyx/tio-world/pull/673) | Move RPC ACL CI tests | CI / Supabase tests | `c0c90caa9a092ebd1572e7ad96f76aeac39eed34` | `734ca15cc8f74e8e705a38a8cb9478fe71e8d67a` | **Partial — E2 mapped subset below** | APPROVED at final HEAD (earlier CHANGES_REQUESTED) | 0/0/1/1 (inline only, resolved) | Review-linked fix `bc680899` and handoff `734ca15c`; 2 identifiable follow-up commits, not full all-channel count | Final-HEAD disposable DB (two runs), attribution, Docs Hygiene SUCCESS; requiredness Unknown | In observation, 168h not complete |
| **PR 08** | [#674](https://github.com/im-tnyx/tio-world/pull/674) | Protected Move RPC grant | Supabase / Security | `9e883c690fc5ca84f2f00e32c0b1489664dd1d1c` | `6c782981f3d076dc1a615b7399017f2d8be5679a` | **Partial — E2 mapped subset below** | APPROVED after final HEAD, human sign-off unverified | 0/0/1/0 (inline only, resolved) | P2 source-linked `d2f6f7e` + `f44fa2d` normalization; later HTTP smoke hardening not all unambiguously inline-root rework | Final-HEAD disposable DB, attribution, Docs Hygiene SUCCESS; hosted JWT QA NOT RUN | In observation, 168h not complete |
| **PR 09** | [#676](https://github.com/im-tnyx/tio-world/pull/676) | Opt-in release-candidate gate | UI / CI | `74f3ebd42a0a388eb817d86de75a1db8b518f335` | `9a51d213f8d720e1b146249e3295e0ce921d2e63` | **Partial — E2 mapped subset below** | author self-review | COMMENTED only (NO distinct-account APPROVED) | 0/0/1/1 (inline only, resolved) | P2 fixes `83bfb7ce`, `967f6c46`; P3 handoff/index `8f39a258`, `9a51d213`; do not equate four commits with four findings | Final-HEAD Flutter incl opt-in assertion, attribution, Docs Hygiene SUCCESS; device QA NOT RUN | In observation, 168h not complete |
| **PR 10** | [#677](https://github.com/im-tnyx/tio-world/pull/677) | Hosted QA authorization runbook | Governance Process | `cf73c051e85b17d5e38c83569f4c164da5d60f02` | `968d1f252c304d77b5f0568d384569e342ffcbd4` | **Partial — E2 mapped subset below** | author self-review | COMMENTED only (NO distinct-account APPROVED) | 0/0/1/0 (inline only, resolved) | P2 wording fix `9b0cdbda`; final handoff `968d1f` is additional docs commit; not hosted QA execution | Final-HEAD attribution, Docs Hygiene SUCCESS; actual hosted JWT/guest/device QA NOT RUN | In observation, 168h not complete |

*Evidence boundary:* This is a bounded 2026-10-25 snapshot of the [GitHub #596 first 10-PR cohort audit](https://github.com/im-tnyx/tio-world/issues/596#issuecomment-6393903470), cross-checked against the 10 actual GitHub review/inline-thread sets and changed-path lists. Counts are **deduplicated severity-tagged inline roots only**; all-channel findings and post-review rework-commit counts are not yet normalized. Source HEAD means reviewed PR tip, not squash merge SHA. None of the 10 168-hour post-merge windows had matured as of this snapshot; no final regression or quality-uplift rate may be computed.

### 6A. D1-E1 — First-five cohort PR evidence normalization (2026-10-25)

**Scope/method:** Fixed consecutive PRs **#660, #661, #663, #664, #665 only**, sampled in the original 10-PR denominator (no fresh cohort). Sources: [each live PR](https://github.com/im-tnyx/tio-world/issues/596), GitHub's changed-file list, formal review submissions, inline review thread root/replies, retained PR commit list with timestamps, and actual *final reviewed-source HEAD* check-run conclusions. Historical PR descriptions are statements by the author, **not independent proof** of local/device runs. A link below binds the claim to that exact PR; its merge SHA and reviewed source HEAD are in the table above. This evidence audit does not rerun any historical test.

**AC-to-files-to-checks-to-HEAD mapping — representative, not exhaustive AC completeness:**

| PR | Scoped acceptance claim and changed-path evidence | Actual exact-HEAD check evidence and validation limit | Evidence rating |
|---|---|---|---|
| [#660](https://github.com/im-tnyx/tio-world/pull/660) | Owner-approved destination tap / Save & Move must dispatch directly without prior confirmation, while cancel performs no write: `apps/features/workout/lib/src/presentation/library/routines/routine_move_flow.dart`, `.../programs/programs_surface.dart`; covered by `apps/features/workout/test/presentation/routine_move_flow_test.dart` and `apps/app/test/app/workout_exercises_route_test.dart`. | At `b0c9cd13d98cfff383921f26f3c0c74fbfa21f7a` actual `Test Flutter (app-workout)`, `Analyze Flutter and Dart / test Dart`, `Commit attribution guard`, `Attribution guard runner`, and `Check documentation diff hygiene` all **SUCCESS**; PR body additionally reports 31/31 flow, 87/87 route and 923/923 package tests, not independently rerun here. | **Partial**: representative AC/files/tests/SHA verified; full per-AC mapping and local test assertion trust remain partial. |
| [#661](https://github.com/im-tnyx/tio-world/pull/661) | Real 5s existing-Program Undo must reverse by protected CAS and reconcile UNKNOWN while suppressing old-owner feedback: `apps/features/workout/lib/src/presentation/library/routines/routine_move_flow.dart`, `apps/app/lib/app/routing/shell/shell_route.dart`, `apps/features/workout/test/presentation/routine_move_flow_test.dart`. | At `07b86b4f33736810e3bc7960b352015472868e32` actual final-head Flutter app-workout, Dart analysis, attribution and Docs Hygiene checks **SUCCESS**; PR body says 48/48 move, 87/87 route tests and local Android/Docker QA A–D PASS with grants revoked. Historical local QA assertion not independently rerun; hosted equivalent not inferred. | **Partial**: relevant AC/tests/SHA mapped; local QA and exhaustive acceptance independently unverifiable. |
| [#663](https://github.com/im-tnyx/tio-world/pull/663) | Manual selected-platform `workflow_dispatch` builds Android APK / unsigned iOS IPA with client-safe QA config, secrets never uploaded: `.github/workflows/mobile-qa-build.yml`, `.github/scripts/mobile_qa_runtime_config.py`, `.github/scripts/test_mobile_qa_runtime_config.py`, `apps/app/README.md`. | At `19ccf3f5ccd77feb24d27bcb6b274d5fc3dc261c` GitHub Flutter matrix, attribution, Docs Hygiene **SUCCESS**. PR body reports 10/10 Python helper tests and YAML syntax review; manual Android/iOS artifact dispatch, physical login and device smoke **NOT RUN** in this PR. | **Partial**, workflow/test-file mapping present; real manual build/device acceptance unverified. |
| [#664](https://github.com/im-tnyx/tio-world/pull/664) | Protected atomic Create+Move Undo enforces caller/ownership, CAS, replay/idempotency, eligible Program deletion and two-session race: `supabase/migrations/20261024090000_m5b_atomic_create_move_full_undo.sql`, `supabase/tests/database/tnyx_569_m5b_full_undo.test.sql`, `supabase/tests/database/tnyx_569_m5b_undo_concurrency.sh`, `.github/workflows/supabase-db-ci.yml`. | At `72ddd28168c15c415c63c8e641242fee6b8c4420` GitHub `Replay and test database migrations`, attribution and Docs Hygiene **SUCCESS**, including fixed revision/race/rename fixture expectations. Disposable CI is not hosted owner/guest/JWT negative-path QA; **NOT RUN** here. | **Partial**: protected SQL/test/CI/SHA linked; no hosted authorization or production evidence. |
| [#665](https://github.com/im-tnyx/tio-world/pull/665) | New Program full Undo receipt frozen before mutation; direct and exact-token UNKNOWN readback both offer actionable Undo; invalidation is owner/session guarded: `apps/features/workout/lib/src/data/repositories/supabase_routine_move_repository.dart`, `apps/features/workout/lib/src/presentation/library/routines/routine_move_flow.dart`, `apps/features/workout/test/presentation/routine_move_flow_test.dart`, `apps/app/lib/app/routing/shell/shell_route.dart`. | At `80a62755e222a2eabf7a490355a9ceab0c085aad` GitHub Flutter app-workout, Dart analysis, attribution, Docs Hygiene **SUCCESS**; PR body reports 170 focused Flutter tests on earlier source `65177c75`, but subsequent fix commits `0035df46` and `c05cc00b` require relying on *final* CI rather than transplanting that older local test proof. Device/hosted QA **NOT RUN**. | **Partial**, relevant code/test/HEAD verified; comprehensive acceptance and device tests remain open. |

**Deduplicated findings and review-caused rework evidence (distinct inline-root floor):**

| PR | Root IDs, severity, disposition | Proven review fixes and re-review |
|---|---|---|
| #660 | `PRRT_kwDOTOXwB86vlcmV` P2, **resolved**; app-level routing tests expected deleted confirmation dialogs. | Codex review cites earlier `b6c0e1c804`; GitHub retained PR commit list has **only** final `b0c9cd13d` after the review. Exact new-commit rework count = **Unknown**, not 0; `im-tio APPROVED` final HEAD and Flutter CI success are observed. |
| #661 | `PRRT_kwDOTOXwB86voxAL` P2 (UNKNOWN invalidation); `PRRT_kwDOTOXwB86vp10A` P2 (new-write eligibility gating); `PRRT_kwDOTOXwB86vp10G` P2 (QA evidence conflict); `PRRT_kwDOTOXwB86vp10M` P2 (false runtime handoff); `PRRT_kwDOTOXwB86vrKx1` P2 (old-owner feedback); `PRRT_kwDOTOXwB86vrKyA` P3 (final status token). All **resolved**. | Retained review-driven fix commits **3**: `844e5978` (post Codex P2), `127a5a00` (post three im-tio P2s), `07b86b4f` (remaining P2/P3). Earlier `CHANGES_REQUESTED`; final `im-tio APPROVED` after last commit and exact-HEAD Flutter CI SUCCESS. |
| #663 | `PRRT_kwDOTOXwB86vvLd0` P3, **resolved**; handoff falsely claimed PR/CI pending. | One documented follow-up docs commit `19ccf3f5` after `im-tio COMMENTED` review, then exact-HEAD `im-tio APPROVED` and CI success. Earlier `COMMENTED` must not count as approval. |
| #664 | `PRRT_kwDOTOXwB86v0iCg` P1 revision-CAS; `PRRT_kwDOTOXwB86v0iCj` P2 transaction setup; `PRRT_kwDOTOXwB86v0nyf` P3 stale handoff SHA; `PRRT_kwDOTOXwB86v0t9l` P3 rename guard fixture; `PRRT_kwDOTOXwB86v0wKF` P1 timestamp expectation. All **resolved**. | Five source-linked correction commits across these roots: `3caa3646`, `e0733baa`, `7c57ab18`, `3fd2ce17`, `72ddd281`. Other intermediate docs commits exist, so this is **verified lower-bound fixes**, not a complete all-channel review-rework denominator. Final `im-tio APPROVED` and disposable SQL CI SUCCESS at exact HEAD; hosted QA unrun. |
| #665 | `PRRT_kwDOTOXwB86v1Wyr` P2, **resolved**; UNKNOWN readback produced confirmation without actionable Undo. | Two source-linked fix commits `0035df46` (frozen receipt/Undo presenter) and `c05cc00b` (UUID fixture + analyzer correction after failed CI). Further docs handoff commits are separate. Earlier `CHANGES_REQUESTED`, final `im-tio APPROVED` and exact-HEAD Flutter CI SUCCESS. |

**E1 tallies/denominator discipline:** 5/5 PRs have formal APPROVED at retained final reviewed heads, **14 resolved severity-tagged inline roots** in E1 (P0=0, P1=2, P2=8, P3=4); original cohort has 20 known inline roots over 10 PRs (do not change its denominator). Review-caused fix counts shown above are PR-specific *lower bounds*; #660's precise count is Unknown. Check-run `SUCCESS` is observed, but repository-required vs supplemental/path-filtered classification remains Unknown without permissioned ruleset evidence. Historical tests were **not rerun** by E1. AC mapping is **Partial**, not `Complete`. Do not compute final `R_evidence`, `R_revalidation`, full-channel `Y_findings`, uplift, or downstream-regression rate from these partial records.

**Supabase separation:** Connected hosted project was read-only `ACTIVE_HEALTHY`, with 70 applied migrations and current security-advisor warnings (including authenticated-executable SECURITY DEFINER notices); this is a **current catalog/advisor observation**, not a claim that #664's hosted JWT/owner/guest QA passed or a new vulnerability was proven. No SQL, Edge Function, migration, secrets or runtime mutation. Security/launch review debt remains #569/#675, Linear TNYX-40/TNYX-126, distinct from the #596 measurement.

**E1 lifecycle:** D1 first five normalized for identifiable evidence, remaining five await D1-E2; all 10 168h observation windows open on 2026-10-25, last ends 2026-10-31T17:31:09Z. Parent #596 stays OPEN. This docs-only PR requires its own exact-HEAD review and CI, with no automatic merge.

### 6B. D1-E2 — Last-five cohort PR evidence normalization (2026-10-25)

**Scope and evidence boundary:** Original fixed slots **#668/#673/#674/#676/#677 only**; no new cohort, no additional quality-governance mechanism. Inspected each historical [GitHub PR #668](https://github.com/im-tnyx/tio-world/pull/668), [#673](https://github.com/im-tnyx/tio-world/pull/673), [#674](https://github.com/im-tnyx/tio-world/pull/674), [#676](https://github.com/im-tnyx/tio-world/pull/676), [#677](https://github.com/im-tnyx/tio-world/pull/677) and actual changed-path lists, formal review submissions, resolved inline thread roots, retained PR commits and timestamp ordering, and exact original *final HEAD* GitHub check-run conclusions. Historical PR descriptions and local QA statements are supporting claims, not tests independently rerun by E2. Current live source/config inspected for `account_settings_routes.dart`, `workout_providers.dart`, opt-in test, R3 migration/DB CI and R5 runbook. Distinct GitHub login ≠ independently verified.

**Representative AC → source/test file → check result → exact original source HEAD:**

| PR | Acceptance example and actual changed-file/test ownership | Verified historical exact final source HEAD checks; non-evidence / NOT RUN | Completeness |
|---|---|---|---|
| [#668](https://github.com/im-tnyx/tio-world/pull/668) | Account Settings GoRoute extraction preserves single root GoRouter, account/username/OTP/delete callback ordering and no UI redesign; `apps/app/lib/app/router.dart` delegates to `apps/app/lib/app/routing/routes/account_settings_routes.dart`. Historical PR cites existing `account_settings_route_test.dart`, `router_provider_stability_test.dart` and `onboarding_root_logout_router_test.dart`, **none added by this PR**. | At `f8527b699c12ca931b11fb02445d6b3cec64f1df`, `Test Flutter (app-workout)`, `Analyze Flutter and Dart / test Dart`, `Analyze and test`, attribution guard/runner and Docs Hygiene **SUCCESS**. Auth/delete parity is PR-level verified through source inspection/CI, not device or full behavioral-equivalence proof. | **Partial** — core mapping source-backed; exhaustive AC/visual/runtime equivalence unproven. |
| [#673](https://github.com/im-tnyx/tio-world/pull/673) | Preserve three Move RPCs' owner/permanent-account/CAS and denied-or-granted ACL restoration, including simulated failure cleanup; `.github/workflows/supabase-db-ci.yml`, `supabase/tests/database/tnyx_569_move_rpc_access_contract.test.sql`, `tnyx_569_move_acl_fixture.sh`, `tnyx_569_move_acl_restore_regression.sh`, and the three updated Move matrices. | At `734ca15cc8f74e8e705a38a8cb9478fe71e8d67a`, **two** `Replay and test database migrations` runs and attribution/Docs Hygiene **SUCCESS**. This validates a disposable DB's initial denied/granted restoration, **not** the later hosted authenticated EXECUTE rollout or hosted JWT negatives. | **Partial** — SQL/CI source mapped; hosted authorization not exercised. |
| [#674](https://github.com/im-tnyx/tio-world/pull/674) | Source-only R3 migration preflight pins full normalized function-body fingerprints, postgres-owned SECURITY DEFINER and RLS/direct-write boundaries before authenticating the exact three RPC signatures; checks revoke/regrant and HTTP smoke using `supabase/migrations/20261024120000_grant_move_routine_rpc_execute_to_authenticated.sql`, `supabase/tests/database/tnyx_569_r3_grant_rollback.test.sql`, `tnyx_569_r3_postgrest_revoke_smoke.py`, `.github/workflows/supabase-db-ci.yml`. | At `6c782981f3d076dc1a615b7399017f2d8be5679a`, `Replay and test database migrations`, attribution and Docs Hygiene **SUCCESS**. Migration was **later** applied separately to hosted Supabase (70 migrations; three `authenticated EXECUTE=true`), not deployed by PR merge. CI's disposable guest/owner/revoke simulation is **not** hosted JWT/cross-owner negative QA. | **Partial** — source/CI verified, post-merge hosted authorization/device safety gate pending. |
| [#676](https://github.com/im-tnyx/tio-world/pull/676) | Default-OFF internal Move release-candidate opt-in at `apps/app/lib/app/composition/workout_providers.dart` via `TIO_MOVE_ROUTINE_RELEASE`; independent test-only ON assertion at `apps/app/test/app/routine_move_release_gate_test.dart`, invoked by `.github/workflows/flutter-ci.yml`. | At `9a51d213f8d720e1b146249e3295e0ce921d2e63`, all final-head Flutter checks incl app-workout and aggregate, attribution and Docs Hygiene **SUCCESS**. Test fail-closed if release define omitted from ON CI step; *no* Android/iOS physical-device QA, hosted JWT negative-case QA or public flag ON evidence. | **Partial** — opt-in gate/CI mapped; release/owner acceptance not proven. |
| [#677](https://github.com/im-tnyx/tio-world/pull/677) | Document *actual* hosted R3 70-migration/three authenticated RPC exposure, then require safe hosted HTTP/JWT negative-path QA matrix (anon, anonymous Auth, cross-owner, stale revision, Create+Move/Undo, UNKNOWN/session-switch) in `docs/development/DEVELOPMENT_SETUP.md` plus `.ai/tasks/issue-569-r5-hosted-qa-readiness.md` / `.ai/tasks/README.md`. | At `968d1f252c304d77b5f0568d384569e342ffcbd4`, attribution guard, attribution runner and Docs Hygiene **SUCCESS**. This PR is **runbook preparation only**; actual hosted JWT/cross-owner negative HTTP calls, data mutation QA, Android/iOS device acceptance **NOT RUN**. | **Partial** — documentation acceptance mapped, runtime/security validation unexecuted. |

**Review root IDs and source-backed correction evidence (deduplicate roots, not comments):**

| PR | Historical original inline finding(s) and disposition | Evidence-driven rework/approval limitations |
|---|---|---|
| #668 | **0** inline roots; formal `im-tio APPROVED` on source HEAD. | Five retained commits are mainly planned source extraction and handoff; no inline findings ≠ no top-level/bot findings or no review-associated work. Full review-rework count **Unknown**, not 0. |
| #673 | `PRRT_kwDOTOXwB86v4ANa` **P2** initially-granted ACL restoration untested; `PRRT_kwDOTOXwB86v4ANc` **P3** stale CI/security handoff; both **resolved**. | After `im-tio CHANGES_REQUESTED` at prior HEAD `57b71fb3`, `bc680899` adds denied/granted + simulated failure cleanup coverage; `734ca15c` records verified final CI/limits. Distinct-account `im-tio APPROVED` final `734ca15c`. **2 source-linked correction commits**, but not universal review-rework denominator. |
| #674 | `PRRT_kwDOTOXwB86v4fZO` **P2** pre-grant admission/owner/CAS/provenance guard verification too weak; **resolved**. | `d2f6f7e` adds whole-body SHA-256 fingerprints; `f44fa2d` corrects CRLF/LF normalization after failed disposable DB CI. Later independently strengthened PostgREST smoke / cleanup (`bec1b50a`) and docs commits cannot all be uniquely charged to the one inline finding. Formal `im-tio APPROVED` submitted after final `6c782981` HEAD; technical approval security sign-off or hosted deploy GO. |
| #676 | `PRRT_kwDOTOXwB86v5o_z` **P2** opt-in test could silently pass as OFF; `PRRT_kwDOTOXwB86v5o_1` **P3** stale review/handoff and R3 grant state; both **resolved**. | P2 technical corrections `83bfb7ce` (separate OFF/ON assertions), `967f6c46` (independent ON marker in CI); P3 docs/index corrections `8f39a258` and `9a51d213`. Review is author-account `im-tnyx COMMENTED` only, **no distinct-account formal APPROVED**. Final-head Flutter checks SUCCESS; hosted/device QA NOT RUN. |
| #677 | `PRRT_kwDOTOXwB86v6FVT` **P2** isolated-only QA wording conflicted with deployed hosted grant state; **resolved**. | `9b0cdbda` corrects historical Option A vs live R3/approved hosted-QA distinction; `968d1f25` final docs handoff. Author-account `im-tnyx COMMENTED` only; **no distinct-account formal APPROVED**; docs/tests cannot establish live hosted JWT authorization QA. |

**Combined evidence accounting and quality limits:** E1 14 (P1=2/P2=8/P3=4) + E2 6 (P1=0/P2=4/P3=2) = **20 resolved *inline-only* severity-coded roots** in original 10 PRs (**P0=0/P1=2/P2=12/P3=6**). E2 formal distinct-account approval = **3/5**, combined **8/10**. All original 10 selected slots, source HEAD / merge SHAs, final original HEAD attribution/Docs Hygiene checks and scope-relevant CI checked. **No verified exhaustive full PR-channel findings**, full AC completeness, precise review-rework total or revalidation denominator; `R_evidence`, `R_revalidation`, quality uplift and linked-regression rate remain **Unknown / N/A**, not zero. Required-check policy classification is not asserted from check names when ruleset access is unavailable. Cursor NEUTRAL/quotas and Copilot quotas are infrastructure/evidence limits, not no-defect verdicts. No historical tests were rerun by E2.

**Security and tracker separation:** At the read-only 2026-10-25 Supabase audit, connected project `oykupyiitspujzpwwvuj` was ACTIVE_HEALTHY with 70 migrations, R3 exact three Move RPCs postgres-owned SECURITY DEFINER/empty search_path, `authenticated EXECUTE=true` and `anon/service_role=false`; Security Advisor reports authenticated SECURITY DEFINER warnings for review. A live permission catalog is **not** hosted owner/guest/JWT negative QA. [#569](https://github.com/im-tnyx/tio-world/issues/569), human review [#675](https://github.com/im-tnyx/tio-world/issues/675), Linear TNYX-40 / TNYX-126 govern release acceptance. TNYX-201/TNYX-81/TNYX-267 are product owners, not a verified #596 mirror; TNYX-193 mirrors #250. No hosted actions, tests using real users, Supabase mutations, grants, product source, CI/ruleset or app activation in D1-E2.

**Lifecycle:** First-ten source-only evidence reconciliation is now **Partial for all ten**; observation window remains OPEN for each PR on 2026-10-25. Earliest 168h close `2026-10-30T12:16:57Z`, last `2026-10-31T17:31:09Z` / 23:01:09 IST. Do not claim no regressions, completed denominators, uplift, or parent #596 completion yet. This is a docs-only review-gate slice; new PR must pass its **own** exact-HEAD Docs Hygiene/attribution and source review before any separately authorized merge.

### 7. Post-Boundary PR Audit & Cohort Entry Log

| PR # | Merged At / SHA | Touched Scopes | Eligibility Decision | Rationale |
|:---:|:---:|---|:---:|---|
| [PR #658](https://github.com/im-tnyx/tio-world/pull/658) | 2026-10-23T09:14:18Z<br>`6a4e113b` | `.ai/tasks/issue-596-d1-measurement-plan.md`<br>`.ai/tasks/README.md` | **EXCLUDED**<br>(Measurement Framework Setup) | PR #658 introduced the D1 measurement framework itself under #596. Touched paths are limited to `.ai/tasks/**` task brief setup. It does not alter production runtime code, shared architecture contracts (`docs/architecture/**`), testing guides (`TESTING_GUIDE.md`), or repository rules (`AGENTS.md`, `.ai/FEATURE_DEVELOPMENT.md`). Including the measurement setup PR within its own observed cohort of measured engineering PRs would introduce self-measurement circularity. |

*Cohort Status:* All 10 consecutive substantive slots were filled with PRs #660, #661, #663, #664, #665, #668, #673, #674, #676 and #677 (2026-10-23 through 2026-10-24 UTC). Subsequent #678/#679/#680 and newer PRs are outside the **fixed** first cohort. The earliest 168-hour window closes 2026-10-30T12:16:57Z and the latest closes 2026-10-31T17:31:09Z. Unknown evidence must remain Unknown.

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
| **AC-08** | Applicable docs-only checks (at minimum `git diff --check`) actually run for the eventual process-doc PR; its PR contains changed-file audit, independent review findings, evidence and limitations. | **Verified for #596 PRs** | PRs #631, #632, #633, #634, and #658 executed exact-HEAD `git diff --check` (exit 0), included scope audits, and recorded review provenance (`im-tio`). (PR #652 excluded as it belongs to #250). | None for merged PRs; will apply to this post-merge reconciliation PR as well. |
| **AC-09** | 10-PR measurement plan is documented with observable sources and an explicit point of review; do not claim uplift until observed. | **Plan: Verified / Cohort: In Progress** | D1 prospective measurement plan is established and merged in PR #658 (`main@6a4e113b`). The 10 eligible substantive PRs are selected and recorded; their 7-day observation windows and exhaustive evidence normalization are unfinished. | **Gap:** Observation of the 10 prospective PRs and subsequent uplift analysis must occur before criterion is fully completed; parent #596 remains OPEN. |

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
- **Reviewed SHA:** `d7d50bdf910769c500e8ae16a956ca062edfd16a` (PR commit 5, re-reviewing prior `0ada08d6`, `828dc92e`, and `beec9099`)
- **Review verdict:** `APPROVED` by `im-tio` on `d7d50bdf` at 2026-10-23T09:12:27Z (all 8 prior findings D1-F01..D1-F08 verified resolved in current source; no new actionable defects found). External tool notes:
  - Commit attribution guard / runner: SUCCESS (run #39928982511).
  - Docs Hygiene CI: SUCCESS (run #39928984283; native `git diff --check` exit 0).
  - Cursor Bugbot / Security / Approval Agent: NEUTRAL due to usage/integration limits (not counted as pass/fail).
  - Codex / Copilot PR reviewer: Quota limit noted (no unverified passes claimed).
- **Limitations:** Prospective cohort observation across 10 substantive PRs is active; parent #596 remains OPEN until all 10 PRs are observed and evaluated.
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
| D1-F09 | P3 | Resolved | Composite final status token `PASS / ACTIVE MEASUREMENT` used instead of canonical single token | `e84a7409` | Separated into canonical `PASS` for plan slice and `Measurement phase: ACTIVE` for ongoing lifecycle |
| D1-F10 | P3 | Resolved | Active handoff HEAD SHA and validation language did not distinguish recorded checkpoint from live PR tip | `560513c5` | Distinguish historical recorded checkpoints (`e84a7409`, `560513c5`) from authoritative live PR tip and recorded exact-HEAD receipts |

---

## 7. Final Handoff

### Changed Files
- `.ai/tasks/issue-596-d1-measurement-plan.md` (New durable task brief specifying prospective measurement plan)
- `.ai/tasks/README.md` (Active task index entry for D1 measurement plan)

### Actual Behavior
Establishes the canonical execution contract for GitHub #596 Slice D1: Option 1 Strict Prospective Cohort. Defines cohort boundaries, eligibility, ledger schema, metric formulas, review checkpoint at PR #10, and reconciles parent acceptance criteria AC-01 through AC-09.

### Known Limitations
- All 10 eligible substantive PRs have merged and are fixed. 8/10 distinct-GitHub-account APPROVED verdicts and 20 resolved inline severity-tagged roots (P0=0, P1=2, P2=12, P3=6) are a preliminary **partial** checkpoint only; no all-channel finding yield, review-caused revalidation rate, exact independent-person rate or final regression rate is supported yet.
- Multi-agent handoff edge scenarios (C0-S01..S06) are observed only as they naturally occur in the cohort, not as a synthetic stress drill.
- Parent #596 remains OPEN and acceptance checkboxes remain unchecked until live measurement completes.

### Final Status
**`PASS`** (D1 measurement plan implementation merged into `main@6a4e113b06bc714039199f94d38ce59e4e0515b7` via PR #658 with `im-tio` APPROVED review and all CI green; post-merge synchronization complete).
**Measurement phase:** **`ACTIVE`** (first 10 consecutive eligible PRs selected; evidence normalization and all 10 seven-day regression windows remain in progress; parent #596 stays OPEN). Historical **`PASS`** above certifies the original *plan PR #658* only, not the final cohort outcome.
