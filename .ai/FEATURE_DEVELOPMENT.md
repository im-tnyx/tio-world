# Feature Development Workflow

This workflow adapts the same practical sequence used by structured feature-development tools: understand the existing system before coding, make consequential decisions explicit, review the delivered behavior, and leave a usable handoff.

It is a repository process, not a dependency on a specific AI product or plugin.

## When To Use It

Use it for user-facing features, cross-package changes, routing, data/persistence, watch behavior, shared contracts, platform integrations, and design-system changes.

For a one-file documentation correction or a mechanical formatting fix, record the scope and validation in the final handoff without creating a full task brief.

## The Seven Phases

### 1. Discovery

Define the user outcome, the problem being solved, success criteria, non-goals, affected platforms, and ownership candidate. Create a task from [tasks/TEMPLATE.md](tasks/TEMPLATE.md).

### 2. Codebase Exploration

Read the current runtime source, configuration, tests, package manifests, nearby feature patterns, and canonical docs. Record file paths and observed behavior, not assumptions.

### 3. Clarification

Stop for choices that would change product scope, persistence, data/privacy ownership, platform strategy, compatibility, or external systems. Record the decision and rationale in the task brief and add a durable decision to [DECISIONS.md](DECISIONS.md) when needed.

### 4. Architecture Design

Document the owning package, public contracts, route/state flow, data boundary, failure states, validation plan, and at least one rejected alternative when a design choice is material. Keep feature business logic out of the app shell and shared UI.

### 5. Implementation

Implement the smallest complete vertical slice. Keep the task brief's scope and non-goals enforced. Do not add backend schemas, third-party services, or platform migrations without their explicit approved decision.

### 6. Quality Review

Run the smallest meaningful checks. Review the diff for module-boundary violations, secrets, accessibility, empty/loading/error states, offline behavior where applicable, and platform-specific constraints. Record failed or unavailable validation honestly.

### 7. Final Handoff

State the changed files, actual behavior, validation evidence, known limitations, and one final status: `PASS`, `REVIEW`, `PARTIAL`, or `BLOCKED`. Update [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md), canonical docs, and the task brief when the observed state changed.

## Required Gates

| Gate | Must be true before moving on |
|---|---|
| Start implementation | Scope, owner, current behavior, and material decisions are recorded. |
| Add persistence or external integration | Data ownership, privacy boundary, and synchronization behavior are explicitly approved. |
| Claim completion | Applicable validation has run, or the exact limitation is recorded. |
| Archive a task | It is validated or superseded, and durable decisions/status are reflected in canonical docs. |

## Agent Roles

When multiple agents are available, separate the work into bounded roles:

- **Explorer**: maps current execution paths, dependencies, and conventions.
- **Architect**: proposes owner-safe approaches and records trade-offs.
- **Implementer**: changes the agreed vertical slice.
- **Reviewer**: independently checks the diff, tests, security boundaries, and stated outcome.

The primary agent remains responsible for integrating evidence and never treats an agent suggestion as runtime truth without verification.
