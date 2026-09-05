# Architecture Decision Records

Architecture Decision Records (ADRs) preserve **durable implementation-level architecture decisions** that should remain understandable after the original Linear issue, PR, or discussion is closed.

They are intentionally lightweight. ADRs are not a second backlog and are not required for routine implementation choices.

## Source-of-truth roles

Use each source for its own job:

```text
Linear
→ planning, sequencing, ownership, acceptance and follow-up work

ADR
→ durable architecture decision + trade-offs + historical trace

canonical docs/
→ current architecture/product policy and operating boundaries

runtime source/config
→ actual implemented behavior
```

An ADR does not claim runtime completion. Runtime source/config remains the behavior truth.

## When an ADR is required

Create an ADR when a decision is both **durable** and **architecturally significant**, especially when reversing it later would be expensive, cross-cutting, security-sensitive, or likely to confuse future implementation.

Typical ADR-worthy decisions include:

- platform/runtime choices such as Flutter vs native or a protected-service runtime;
- canonical identity/Auth model or trust boundary;
- database/persistence ownership model;
- queue/job architecture;
- AI provider/orchestration boundary;
- deployment topology;
- caching, search, or vector architecture;
- Storage/media ownership model;
- cross-platform navigation/ownership model;
- shared design-system architecture;
- API contract/versioning architecture when a specific durable design is selected;
- replacement of another accepted ADR.

A Linear issue proposing a future option does **not** by itself justify an ADR. Create the ADR only when the durable decision is approved and supported by current implementation direction or an explicitly approved architecture change.

## When an ADR is not required

Do not create ADRs for:

- routine refactors that preserve existing boundaries;
- bug fixes;
- ordinary feature acceptance criteria;
- small UI decisions;
- low-cost/reversible library choices;
- temporary experiments or spikes;
- one-off migrations that follow an already accepted migration policy;
- implementation details already governed by an existing ADR/canonical policy;
- speculative future architecture with no approved decision.

If a short Linear comment or canonical-doc update can fully explain the choice, an ADR is probably unnecessary.

## Status values

| Status | Meaning |
| :--- | :--- |
| Proposed | Decision is under review. It must not be treated as approved implementation direction. |
| Accepted | Decision is approved and should guide new work until explicitly replaced or deprecated. |
| Superseded | A newer ADR replaces this decision. Keep the old ADR for history and link both directions. |
| Deprecated | The decision should no longer guide new work, but no single replacement ADR exists. Keep it for traceability. |

Do not delete an ADR merely because its decision is old.

## Lifecycle rules

### Proposed → Accepted

Accept an ADR only when the owning architecture/product decision is actually approved. Link the planning source and, when available, the implementation PR/commit or canonical document that proves the direction.

### Accepted → Superseded

When a durable decision changes materially:

1. create a new ADR with a new number;
2. explain why the old decision no longer fits;
3. mark the old ADR `Superseded`;
4. link old → new and new → old;
5. preserve the old Context/Decision/Consequences instead of rewriting history.

ADR-0003 → ADR-0007 is the first repository example of this lifecycle: the original Supabase-first decision is preserved, while the later `services/api` namespace/Fastify/current-Supabase boundary is recorded separately.

### Accepted → Deprecated

Use `Deprecated` when the old direction should stop guiding new work but there is no single replacement decision yet. Link the issue/document that owns the transition.

### Historical facts inside ADRs

An ADR records the context that existed when the decision was made. Some factual statements may later become stale while the decision remains valid, or the decision itself may later be superseded.

Do **not** rewrite historical Context/Consequences only to make them read like current runtime documentation. Instead:

- keep the ADR as the historical decision record;
- update canonical docs/runtime source for current truth;
- create a new ADR when the **decision itself** changes materially;
- mark and cross-link the old ADR when it is superseded.

Example: ADR-0003 was accepted on 2026-08-11 and included then-current assumptions that `supabase/` was not live and the future protected server would live under `backend/`. Later accepted decisions made `supabase/` active and locked `services/api` + Fastify. Those material changes are recorded in ADR-0007 rather than rewriting ADR-0003's historical Decision section.

## Required ADR format

New ADRs use [`TEMPLATE.md`](TEMPLATE.md) and stay concise.

Required sections:

```text
Status
Context
Decision
Alternatives
Consequences
Links
```

A Date line should also be present for chronology.

### Context

State the problem and constraints. Do not paste an entire Linear issue.

### Decision

State the approved direction precisely, including important exclusions when they prevent architecture drift.

### Alternatives

Record only meaningful alternatives and why they were rejected. This is not a brainstorming dump.

### Consequences

Record benefits plus real trade-offs/constraints. An ADR should make future costs visible, not only justify the chosen option.

### Links

Link, where applicable:

- owning Linear issue/document;
- canonical architecture/product document;
- implementation PR/commit;
- superseded/superseding ADR.

## Numbering and filenames

Use monotonically increasing four-digit numbers:

```text
0001-decision-title.md
0002-another-decision.md
...
```

Rules:

- never renumber accepted historical ADRs;
- never reuse a removed/abandoned number;
- filename title should remain short and semantic;
- the next number is chosen only when a real ADR is approved/proposed for repository review.

## Records

Existing ADRs remain historical records and are not rewritten merely to match the newest template.

| ADR | Status | Decision |
| :--- | :--- | :--- |
| [0001](0001-flutter-wear-os-and-native-watchos.md) | Accepted | Flutter for Wear OS; native SwiftUI for future Apple Watch. |
| [0002](0002-shared-app-mode-and-dynamic-navigation.md) | Accepted | One shared AppMode contract drives target phone navigation. |
| [0003](0003-supabase-first-data-boundary.md) | Superseded by 0007 | Original Supabase-first boundary with historical future-workspace assumptions. |
| [0004](0004-material-3-expressive-through-core.md) | Accepted | Material 3 Expressive is delivered through `apps/core` tokens and components. |
| [0005](0005-adaptive-navigation-and-action-entry.md) | Accepted | A future custom layout adapts Home sections and feature action entry points without moving domain ownership. |
| [0006](0006-single-route-onboarding-parent-flow.md) | Accepted | One onboarding route owns fixed progress/actions and mode-derived child steps. |
| [0007](0007-active-supabase-and-future-services-api.md) | Accepted | Active Supabase remains the current foundation; future protected backend uses `services/api` with TypeScript/Fastify when explicitly authorized. |
| [0008](0008-settings-hydration-preferences-owner.md) | Superseded by 0009 | Historical account-synced Supabase preference proposal. |
| [0009](0009-settings-local-default-glass-size.md) | Accepted | Settings owns a local-only Default Glass Size convenience preference. |
| [0010](0010-settings-local-calendar-first-day-of-week.md) | Accepted | Settings owns the local-only app-global Calendar Preferences first-day-of-week value. |

## Authoring workflow

For a new durable decision:

```text
Linear / architecture discussion
→ decide whether ADR threshold is met
→ copy TEMPLATE.md to next ADR number
→ Proposed while unresolved
→ review decision + alternatives + consequences
→ Accepted only after approval
→ link canonical docs and implementation evidence
→ update this index
```

For a changed decision:

```text
new durable direction
→ new ADR number
→ old ADR becomes Superseded (or Deprecated)
→ cross-link history
→ update canonical docs + implementation separately
```

## Relationship to Linear and implementation

Linear remains the planning/tracking source. Do not turn ADRs into task checklists, sprint plans, or runtime status dashboards.

An ADR may be Accepted before every implementation slice is complete if the architecture direction itself is approved. Implementation completion must still be proven in its owning issue/PR/source.

Conversely, do not retroactively create ADRs for every completed implementation. Add one only when preserving the durable decision will materially help future work.

## Related

- [ADR template](TEMPLATE.md)
- [Architecture](../ARCHITECTURE.md)
- [Module Ownership](../MODULE_OWNERSHIP.md)
- [Roadmap](../ROADMAP.md)
- [Supabase-First Platform Strategy](../SUPABASE_STRATEGY.md)
- [Documentation index](../README.md)
- [Active Decisions](../../.ai/DECISIONS.md)
