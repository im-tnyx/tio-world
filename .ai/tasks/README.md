# Task Files

Task files are compact, durable briefs for work that is active, blocked on one decision, or ready to hand off. They are not a backlog dump or a replacement for GitHub Issues when external tracking is needed.

## Current Tasks

| Task | Status | Primary owner | Read before |
|---|---|---|---|
| [Design-system token consolidation](design-system-token-consolidation.md) | Validated | `apps/core/lib/src/theme` | **Any Flutter visual/token/theme/component styling change** |
| [Design-system Slice A — Core Foundation](design-system-slice-a-core-foundation.md) | Validated | `apps/core/lib/src/theme`, `apps/core/test/theme` | Foundation/source boundary validated by Flutter CI #624 |
| [Design-system Slice B — Welcome](design-system-slice-b-welcome.md) | Validated | Welcome + governed core contracts | Welcome final boundary validated by Flutter CI #646 |
| [Design-system Slice C — Core Components](design-system-slice-c-core-components.md) | Validated | reusable core UI/component contracts | Core components final source boundary validated by Flutter CI #710 |
| [Design-system Slice D — Auth + Account Setup](design-system-slice-d-auth-account.md) | Validated | Auth/Account Setup presentation | Validated by Flutter CI #742 |
| [Design-system Slice E — Product Onboarding](design-system-slice-e-onboarding.md) | Validated | Onboarding presentation | Validated by Flutter CI #825 |
| [Design-system Slice F — Home + Profile + Settings](design-system-slice-f-home-profile-settings.md) | Validated | Home/Profile/Settings presentation | Validated by Flutter CI #843 |
| [Design-system Slice G — Remaining UI](design-system-slice-g-remaining-ui.md) | Validated | remaining phone/Wear presentation | Validated by Flutter CI #846 |
| [Design-system Slice H — Final Enforcement](design-system-slice-h-final-enforcement.md) | Validated | repository-wide design-system audit | Final enforcement validated by Flutter CI #865 |
| [Design-system hardcoded color audit](design-system-hardcoded-color-audit.md) | Cross-cutting | `apps/core` design-system ownership | Any work touching colors, gradients, shadows, alpha/state colors, or feature color helpers |
| [Flutter UI reusable-first governance](flutter-ui-reusable-governance.md) | In progress | repository AI governance + `apps/core` | Any change to repository-wide Flutter UI agent/workflow rules |
| [App Mode foundation](app-mode-foundation.md) | In progress | `apps/shared`, `apps/app`, onboarding, Settings, `user_app_preferences` | Local foundation exists; durable account persistence is P2 after the canonical P1 schema slice |
| [Mode-conditional onboarding flow](onboarding-flow.md) | Ready | onboarding with Profile, Workout, Nutrition, `apps/shared`, `apps/app` contracts | Building onboarding steps, draft/resume, completion, or router gating |
| [Product Onboarding Slice 1 — identities](product-onboarding-slice-1-identities.md) | In progress | `apps/features/onboarding` | Changing Product Onboarding section/step identity, draft serialization, resume, or progress compatibility |
| [Product Onboarding Slice 2B — Target Weight + Goal Pace](product-onboarding-slice-2b-target-weight-goal-pace.md) | In progress | `apps/features/onboarding` | Canonical PR #50; Body B1 validated by CI #1153; next persistence work is the account/profile/preferences P1 foundation before Profile/Body cleanup |
| [Canonical Supabase Owner Migration](canonical-supabase-owner-migration.md) | In progress | Supabase + domain repositories | #44 owner schema/backfill applied; `users` is now account root, with approved `user_profiles` + `user_app_preferences` forward split |
| [Account / Profile / App Preferences Canonical Split](account-profile-app-preferences-canonical-split.md) | Ready | Supabase + Account/Profile/App Mode composition | **Next canonical sequence source:** P1 schema → P2 App Mode → P3 Profile → P4 Body/Profile composition → P5/P6 domain splits → P7 cleanup |
| [Canonical Body Owner Repository Cutover](canonical-body-owner-repository-cutover.md) | In progress | `apps/features/progress` + onboarding/Profile/Settings composition | Body A + B1 validated (#1135/#1153); B2/B3 waits for P1/P3 so Profile uses `user_profiles`, not `users` |
| [Adaptive navigation and action entry](adaptive-navigation-and-actions.md) | Ready | `apps/shared`, `apps/core`, `apps/app`, Settings, affected features | Designing custom tabs, Home composition, or feature action placement |
| [Material 3 Expressive foundation](material-3-expressive.md) | In progress | `apps/core`, `apps/app` | Changing shared theme, navigation, buttons, motion, or accessibility behavior |
| [Screen catalog and module plan](screen-catalog-and-module-plan.md) | Ready | `apps/app`, `apps/core`, `apps/shared`, affected features | Starting a screen or module vertical slice |
| [Supabase foundation](supabase-foundation.md) | Needs decision | `supabase/`, `apps/shared`, affected features | Starting Auth, data, RLS, Storage, or protected AI work |

## Canonical persistence execution order

```text
Body B1 canonical read/history contract        VALIDATED (#1153)
        ↓
P1 user_profiles + user_app_preferences        NEXT
        ↓
P2 durable App Mode / active_tabs
        ↓
P3 common Profile repository cutover
        ↓
P4 Body B2/B3 Profile/Settings composition
        ↓
P5 Wellness/Nutrition split
        ↓
P6 Workout Profile/Targets split
        ↓
P7 integrated persistence acceptance
        ↓
later legacy-column cleanup migration
```

Do not skip a slice before its validation evidence is recorded in the focused task and relevant GitHub issue.

## Design-System Execution Order

```text
Parent architecture contract           VALIDATED
        ↓
Slice A — Core Foundation              VALIDATED (#624)
        ↓
Slice B — Welcome                      VALIDATED (#646)
        ↓
Slice C — Core Components              VALIDATED (#710)
        ↓
Slice D — Auth + Account Setup         VALIDATED (#742)
        ↓
Slice E — Product Onboarding           VALIDATED (#825)
        ↓
Slice F — Home + Profile + Settings    VALIDATED (#843)
        ↓
Slice G — Remaining UI                 VALIDATED (#846)
        ↓
Slice H — Final Enforcement            VALIDATED (#865)
```

The hardcoded color audit remains a cross-cutting governance contract for future work that touches colors/alpha/gradients/shadows/state layers.

## Mandatory UI Governance

Before any Flutter production UI/theme/token change:

1. read [Design-system token consolidation](design-system-token-consolidation.md);
2. read the relevant feature/task brief;
3. read `apps/core/lib/src/theme/README.md` before implementing visual code or inspecting internal token files;
4. inspect the existing reusable core UI/component surface and prefer the public `package:tio_core/core.dart` boundary before rebuilding an equivalent pattern locally;
5. when editing under `apps/features/*`, also follow `apps/features/AGENTS.md` for the nested feature-package contract.

Global rules:

- centralized `apps/core` design-system ownership is the visual source of truth;
- existing reusable core components are preferred before raw local reconstruction of equivalent cards, buttons, inputs, avatars, dialogs, pickers, sheets, navigation surfaces, or other shared patterns;
- a new reusable core component/contract requires genuine reuse evidence; one-off feature/workflow composition stays with its owning feature while consuming governed core values;
- feature packages must not create parallel design-token/color/layout/theme catalogs;
- fixed visual values must follow canonical primitive/semantic/component ownership;
- **not every widget/dialog/screen gets a token file**; component-token classes are admitted only for proven reusable contracts;
- screen/feature/workflow/product-action token bags are forbidden final architecture;
- behavior/domain constants must not be misclassified as visual tokens;
- design-system migration is pixel-preserving by default;
- **no screen design/UI may change without separate explicit owner/design confirmation**;
- if a visual improvement is discovered during non-visual work, record it separately and preserve existing rendering until approved.

The design-system consolidation implementation is validated under GitHub Issue #6 and PR #22. The parent task owns stable architecture rules; child slices contain implementation evidence.

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