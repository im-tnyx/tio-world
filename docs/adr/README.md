# Architecture Decision Records

Architecture Decision Records (ADRs) preserve durable choices that affect platform strategy, module ownership, data boundaries, navigation, or design-system governance.

They do not describe runtime completion. Runtime source remains the behavior truth; canonical architecture and roadmap documents remain the product-direction truth.

## Status Values

| Status | Meaning |
| :--- | :--- |
| Accepted | The direction is approved and should guide new work. |
| Superseded | A newer ADR replaced the decision. Keep the old record for history. |
| Proposed | A decision is being evaluated and must not be treated as approved. |

## Records

| ADR | Status | Decision |
| :--- | :--- | :--- |
| [0001](0001-flutter-wear-os-and-native-watchos.md) | Accepted | Flutter for Wear OS; native SwiftUI for future Apple Watch. |
| [0002](0002-shared-app-mode-and-dynamic-navigation.md) | Accepted | One shared AppMode contract drives target phone navigation. |
| [0003](0003-supabase-first-data-boundary.md) | Accepted | Supabase is the initial Auth/data/Storage foundation; protected backend work is a later upgrade. |
| [0004](0004-material-3-expressive-through-core.md) | Accepted | Material 3 Expressive is delivered through `apps/core` tokens and components. |
| [0005](0005-adaptive-navigation-and-action-entry.md) | Accepted | A future custom layout adapts Home sections and feature action entry points without moving domain ownership. |
| [0006](0006-single-route-onboarding-parent-flow.md) | Accepted | One onboarding route owns fixed progress/actions and mode-derived child steps. |

## When To Add An ADR

Add an ADR before or alongside a change that alters a durable boundary, such as a platform stack, package owner, persistence model, privacy boundary, navigation model, or shared UI system. Do not create ADRs for small implementation details or temporary tasks.

For active product work, also update the relevant task in [`.ai/tasks/`](../../.ai/tasks/README.md), the canonical document in [`docs/`](../README.md), and the implementation status only after source evidence exists.

## Related

- [Architecture](../ARCHITECTURE.md)
- [Module Ownership](../MODULE_OWNERSHIP.md)
- [Roadmap](../ROADMAP.md)
- [Supabase-First Platform Strategy](../SUPABASE_STRATEGY.md)
- [Active Decisions](../../.ai/DECISIONS.md)
