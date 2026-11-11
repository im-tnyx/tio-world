# Tio Design Guide

Document Status: Canonical Live Doc
Last Verified: 2026-10-20
Owner: repository documentation governance
Truth Boundary: Navigation to existing design documentation only; the linked documents retain policy and implementation ownership, and runtime source/tests prove rendered behavior.

Use this guide to find the owning document before planning or changing phone or
Wear OS UI. Documentation authority and conflict resolution are defined in the
[documentation index](docs/README.md).

## Design References

| Question | Read |
| :--- | :--- |
| What is the shared UI/UX direction, including accessibility, motion, and navigation policy? | [UI/UX system](docs/architecture/UX_UI_SYSTEM.md) |
| Which theme APIs, tokens, and reusable components should a Flutter screen use? | [Core theme and design system](apps/core/lib/src/theme/README.md) |
| What content, actions, and states belong to a particular screen? | [Screen catalog and per-screen specifications](docs/screens/README.md) |
| Which package owns the change? | [Module ownership](docs/architecture/MODULE_OWNERSHIP.md) |
| How do the application and package boundaries fit together? | [Architecture](docs/architecture/ARCHITECTURE.md) |
| Why was a durable architecture or design decision made? | [Architecture Decision Records](docs/adr/README.md) |
| How should Wear OS and Apple Watch experiences differ from the phone? | [Watch strategy](docs/wearables/WATCH_STRATEGY.md) |
| Which validation is appropriate for the changed area? | [Testing guide](docs/development/TESTING_GUIDE.md) |

## Before A UI Change

Follow the applicable [agent instructions](AGENTS.md) and
[feature development workflow](.ai/FEATURE_DEVELOPMENT.md). For Flutter UI work,
start with the core theme guide above and inspect existing reusable components.
Feature-package work also follows [feature instructions](apps/features/AGENTS.md).

Update design rules in their owning documents and link them here when needed.
Keep token values, component contracts, and screen specifications with those
owners rather than maintaining copies in this guide. A target design in a linked
document does not establish that the behavior is implemented or validated.
