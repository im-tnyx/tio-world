# Feature Development Workflow

Document Status: Canonical Live Doc
Last Verified: 2026-10-20
Owner: repository AI governance
Truth Boundary: Authoritative for the repository's AI/contributor feature-execution workflow and Owner Approval gates; not product architecture, runtime behavior, or live tracker state.

This workflow adapts the same practical sequence used by structured feature-development tools: understand the existing system before coding, make consequential decisions explicit, review the delivered behavior, and leave a usable handoff.

It is a repository process, not a dependency on a specific AI product or plugin.

## When To Use It

Use it for user-facing features, cross-package changes, routing, data/persistence, watch behavior, shared contracts, platform integrations, and design-system changes.

For a one-file documentation correction or a mechanical formatting fix, record the scope and validation in the final handoff without creating a full task brief.

## Owner Approval Gate

Approval is for product direction and high-risk product/data shape changes, not normal engineering execution.

Mandatory Owner Approval applies only before:

1. **A new independently scoped product task, feature, or product slice.** Before implementation, explain what will be built, why it should be next, what will change, and what will not change. Stop at `AWAITING OWNER APPROVAL` until the owner approves that scope.
2. **An unapproved product-visible UI/UX change.** This includes layout, visual appearance, spacing, typography, colors, component geometry, visible navigation or interaction behavior, adding or removing visible UI, or redesigning an existing screen or flow. UI/UX already included in the owner-approved task scope does not need repeated approval for each implementation detail. Pixel- and behavior-preserving internal refactors do not require approval.
3. **A Supabase table or column shape change.** Creating, deleting, renaming, or materially changing a table or column requires approval, including column type, nullability, or semantic ownership changes. Explain the proposed data-model and compatibility impact before implementation. An approval covering the exact shape does not need to be repeated for each migration statement.

`New task` does not mean a normal implementation subtask needed to complete an already approved scope. Tests, scoped bug fixes, repository/provider/controller wiring, internal refactors, validation or CI fixes, review findings, documentation, and internal RPC/RLS/security/correctness work are not new-task approval triggers by themselves.

Other engineering decisions may be resolved and implemented without Owner Approval when they are necessary to complete the approved task and stay within its boundaries. If implementation discovers a new idea that would create a new independently scoped product task, introduce an unapproved visible UI/UX change, or change a Supabase table/column shape, record it as a follow-up and return to the Owner Approval Gate. Do not broaden the active task silently.

## The Seven Phases

### 1. Discovery

Define the user outcome, the problem being solved, success criteria, non-goals, affected platforms, and ownership candidate. Create a task from [tasks/TEMPLATE.md](tasks/TEMPLATE.md).

### 2. Codebase Exploration

Read the current runtime source, configuration, tests, package manifests, nearby feature patterns, and canonical docs. Record file paths and observed behavior, not assumptions.

### 3. Clarification

Resolve engineering decisions that are necessary to complete the approved scope and record material rationale in the task brief. Stop for Owner Approval only when a choice triggers one of the three conditions in the Owner Approval Gate. Add a durable decision to [DECISIONS.md](DECISIONS.md) when needed.

### 4. Architecture Design

Document the owning package, public contracts, route/state flow, data boundary, failure states, validation plan, and at least one rejected alternative when a design choice is material. Keep feature business logic out of the app shell and shared UI.

### 5. Implementation

Implement the smallest complete vertical slice. Keep the task brief's approved scope and non-goals enforced. Continue normal engineering execution without repeated approval while it remains inside those boundaries. Record any newly discovered product direction, unapproved visible UI/UX change, or Supabase table/column shape change as a follow-up and return to the Owner Approval Gate before implementing it.

### 6. Quality Review

Run the smallest meaningful checks. Review the diff for module-boundary violations, secrets, accessibility, empty/loading/error states, offline behavior where applicable, and platform-specific constraints. Record failed or unavailable validation honestly.

Independent review is preferred for substantive changes when available, but this is a **role separation**, not a mandated number, order, vendor, or model of agents. A reviewer who also implemented the reviewed changes performs **self-review**, not independent review. Record the review source (GitHub, linked external tool, manual, or chat-only), reviewed diff/commit SHA, reviewer relationship to the implementation, findings/dispositions, and what could not be reviewed. A Grok, Codex, Cursor, or other agent assessment is evidence to verify, not automatically a formal GitHub `APPROVED` review or passing CI. A failed/limited review service is not a clean review; honor any actually required independent-review or merge-policy gate.

### 7. Final Handoff

State the changed files, actual behavior, validation evidence, known limitations, and one final status: `PASS`, `REVIEW`, `PARTIAL`, or `BLOCKED`. Update [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md), canonical docs, and the task brief when the observed state changed.

For substantive changes, link each applicable acceptance criterion to the changed behavior/files and a test or manual proof with its actual result and observed SHA/environment. Note negative, error, offline, accessibility, or owner/tenant-failure paths when relevant to that change, without requiring blanket checks. Explicitly classify required checks, intentionally not-run/non-applicable optional checks, failed checks, and residual risks. A green CI status alone is not proof of all acceptance criteria or independent review.

### Final Status Decision Rule

| Status | Evidence-based meaning |
|---|---|
| `PASS` | All applicable approved acceptance criteria have verified outcomes, all applicable required checks have actually succeeded at the claimed SHA/environment, blocking findings are resolved or validly dispositioned, and any required review/approval gates are satisfied. Optional non-applicable or consciously excluded checks have explained scope/risk; no false independent-review claim. |
| `REVIEW` | Work is awaiting review, an outstanding decision, or a required check that is scheduled/in progress but has no failure conclusion yet. Do not claim completion or merge readiness until those gates pass. |
| `PARTIAL` | Only a documented subset is verified, or meaningful applicable validation could not run and residual risk remains; list incomplete criteria and the next action. Do not use `PARTIAL` to hide a failed required merge check. |
| `BLOCKED` | A known failed required check, inability to obtain required validation, unresolved blocking finding, owner/ownership ambiguity or denied required approval prevents safe continuation or merge. Record the blocker and who can resolve it. A still-running required check remains a pending merge gate, not a claimed failure. |

If several statuses apply, report the **most restrictive**: `BLOCKED` > `PARTIAL` > `REVIEW` > `PASS`, and list the remaining open conditions. In particular, a required validation that cannot be run is `BLOCKED` for completion/merge even when a PR is available for review; an in-progress required check without a failure is `REVIEW` only when no more restrictive condition applies. Do not downgrade an outstanding required gate to `PARTIAL` just because other criteria passed.

These are final **handoff outcomes**, distinct from the task-lifecycle values in [tasks/README.md](tasks/README.md) and GitHub review states. Required-vs-supplemental security checks and infrastructure-failure-vs-concrete-finding decisions retain the existing `AGENTS.md` and `.github/PUSH_TEMPLATE.md` rules. A documented tool limitation never overrides branch protection or owner-only merge authorization.

## Required Gates

| Gate | Must be true before moving on |
|---|---|
| Start a new independently scoped product task/feature slice | What will be built, why it should be next, what will change, and what will not change are explained; the owner has approved that scope. |
| Make a product-visible UI/UX change | The visible change is included in the owner-approved task scope or has later explicit approval. |
| Change a Supabase table/column shape | The exact table/column change and its data-model and compatibility impact are explained and approved. |
| Continue normal implementation | The work is necessary for the approved outcome and remains within its scope and non-goals; no separate Owner Approval is required. |
| Claim completion as `PASS` | Satisfy the [Final Status Decision Rule](#final-status-decision-rule), including actually completed applicable required validation; when that validation cannot run, record the limitation and report `REVIEW`, `PARTIAL`, or `BLOCKED` as appropriate instead of claiming completion. |
| Archive a task | It is validated or superseded, and durable decisions/status are reflected in canonical docs. |

## Agent Roles

Roles are interchangeable responsibilities, not fixed agent identities or a mandatory multi-agent sequence. One or more agents may perform different roles sequentially, preserving the single active implementation owner and truthful review provenance:

- **Explorer**: maps current execution paths, dependencies, and conventions.
- **Architect**: proposes owner-safe approaches and records trade-offs.
- **Implementer**: changes the agreed vertical slice.
- **Reviewer**: checks the diff, tests, security boundaries, and stated outcome; record whether this was independent review or self-review.

The currently verified task/handoff owner integrates evidence; after ownership transfer the receiving owner re-verifies claims against live sources. No specific agent identity remains permanently responsible, and no agent suggestion becomes runtime truth without verification.
