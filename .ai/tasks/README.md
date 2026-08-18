# Task Files

Task files are compact, durable briefs for work that is active, blocked on one decision, or ready to hand off. They are not a backlog dump or a replacement for GitHub Issues when external tracking is needed.

## Current Tasks

| Task | Status | Primary owner | Read before |
|---|---|---|---|
| [Design-system token consolidation](design-system-token-consolidation.md) | In progress | `apps/core/lib/src/theme` | **Any Flutter visual/token/theme/component styling change** |
| [Design-system Slice A — Core Foundation](design-system-slice-a-core-foundation.md) | **In progress** | `apps/core/lib/src/theme`, `apps/core/test/theme` | Current design-system implementation work |
| [Design-system Slice B — Welcome](design-system-slice-b-welcome.md) | Blocked | Welcome + governed core contracts | Starts only after Slice A is validated |
| [Design-system Slice C — Core Components](design-system-slice-c-core-components.md) | Blocked | reusable core UI/component contracts | Starts only after Slices A–B are validated |
| [Design-system Slice D — Auth + Account Setup](design-system-slice-d-auth-account.md) | Blocked | Auth/Account Setup presentation | Starts only after Slice C is validated |
| [Design-system Slice E — Product Onboarding](design-system-slice-e-onboarding.md) | Blocked | Onboarding presentation | Starts only after Slice D is validated |
| [Design-system Slice F — Home + Profile + Settings](design-system-slice-f-home-profile-settings.md) | Blocked | Home/Profile/Settings presentation | Starts only after Slice E is validated |
| [Design-system Slice G — Remaining UI](design-system-slice-g-remaining-ui.md) | Blocked | remaining phone/Wear presentation | Starts only after Slice F is validated |
| [Design-system Slice H — Final Enforcement](design-system-slice-h-final-enforcement.md) | Blocked | repository-wide design-system audit | Starts only after Slice G is validated |
| [Design-system hardcoded color audit](design-system-hardcoded-color-audit.md) | Planned / cross-cutting | `apps/core` design-system ownership | Any slice touching colors, gradients, shadows, alpha/state colors, or feature color helpers |
| [App Mode foundation](app-mode-foundation.md) | In progress | `apps/shared`, onboarding, Settings, `apps/app`, `apps/core` | Changing phone navigation, onboarding, or Settings |
| [Mode-conditional onboarding flow](onboarding-flow.md) | Ready | onboarding with Profile, Workout, Nutrition, `apps/shared`, `apps/app` contracts | Building onboarding steps, draft/resume, completion, or router gating |
| [Adaptive navigation and action entry](adaptive-navigation-and-actions.md) | Ready | `apps/shared`, `apps/core`, `apps/app`, Settings, affected features | Designing custom tabs, Home composition, or feature action placement |
| [Material 3 Expressive foundation](material-3-expressive.md) | In progress | `apps/core`, `apps/app` | Changing shared theme, navigation, buttons, motion, or accessibility behavior |
| [Screen catalog and module plan](screen-catalog-and-module-plan.md) | Ready | `apps/app`, `apps/core`, `apps/shared`, affected features | Starting a screen or module vertical slice |
| [Supabase foundation](supabase-foundation.md) | Needs decision | future `supabase/`, `apps/shared`, affected feature | Starting Auth, data, RLS, Storage, or protected AI work |

## Design-System Execution Order

```text
Parent architecture contract
        ↓
Slice A — Core Foundation              IN PROGRESS
        ↓
Slice B — Welcome                      BLOCKED
        ↓
Slice C — Core Components              BLOCKED
        ↓
Slice D — Auth + Account Setup         BLOCKED
        ↓
Slice E — Product Onboarding           BLOCKED
        ↓
Slice F — Home + Profile + Settings    BLOCKED
        ↓
Slice G — Remaining UI                 BLOCKED
        ↓
Slice H — Final Enforcement            BLOCKED
```

Do not start a blocked design-system slice until its dependency is validated with evidence. The hardcoded color audit is cross-cutting and applies inside any slice that touches colors/alpha/gradients/shadows/state layers.

## Mandatory UI Governance

Before any Flutter production UI/theme/token change, read [Design-system token consolidation](design-system-token-consolidation.md) and the currently active slice task.

Global rules:

- centralized `apps/core` design-system ownership is the visual source of truth;
- feature packages must not create parallel design-token/color/layout/theme catalogs;
- fixed visual values must follow the canonical primitive/semantic/component ownership model;
- component token classes must not become screen-specific token bags;
- design-system migration is pixel-preserving by default;
- **no screen design/UI may change without a separate explicit owner/design confirmation**;
- if a visual improvement is discovered during non-visual work, record it separately and preserve the existing screen until approved.

The active design-system work is tracked by GitHub Issue #6 and Draft PR #22. The parent task owns stable architecture rules; child slices own detailed implementation evidence.

## File Contract

Each task file should contain:

1. A clear outcome, current status, verified evidence, and success criteria.
2. In-scope and out-of-scope boundaries plus ownership and dependency notes.
3. Any decision that must be confirmed before source changes begin.
4. A short implementation checklist, validation evidence, and exit criteria.
5. For UI-affecting work, an explicit reference to the canonical design-system guardrails and any separately approved visual-change decision.

Start new feature work from [TEMPLATE.md](TEMPLATE.md). Existing task briefs may be migrated when they next become active; do not rewrite historical task state just to match the template unless it conflicts with a current canonical architecture or safety/product guardrail.

Use status values `Ready`, `In progress`, `Needs decision`, `Blocked`, `Validated`, or `Superseded`. Move a task to [the archive](../archive/README.md) only after its outcome is validated or superseded and its durable decision/status has been moved to the relevant canonical doc.

Never put secrets, personal data, unverified completion claims, machine-specific paths, or full conversation transcripts in these files.
