# Task Files

Task files are compact, durable briefs for work that is active, blocked on one decision, or ready to hand off. They are not a backlog dump or a replacement for GitHub Issues when external tracking is needed.

## Current Tasks

| Task | Status | Primary owner | Read before |
|---|---|---|---|
| [Splash — TIO wordmark](splash-tio-wordmark.md) | Validated | `apps/features/splash` | Any further splash screen visual change; validated by Flutter CI #33265051617 |
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
| [Product Onboarding — Canonical Execution Plan](product-onboarding-canonical-execution.md) | Ready | `apps/features/onboarding` + canonical owner repositories | **Single current sequencing source for finishing Product Onboarding; next O1 durable App Mode (#11)** |
| [App Mode foundation](app-mode-foundation.md) | In progress | `apps/shared`, `apps/app`, onboarding, Settings, `user_app_preferences` | P1 canonical table is live; durable runtime persistence is O1/P2 and is no longer blocked by account-contact verification |
| [Mode-conditional onboarding flow](onboarding-flow.md) | Ready | onboarding with Profile, Workout, Nutrition, `apps/shared`, `apps/app` contracts | Historical/detail reference for flow/controller architecture; use canonical execution task for current sequence |
| [Product Onboarding Slice 1 — identities](product-onboarding-slice-1-identities.md) | Validated | `apps/features/onboarding` | Stable future section/step identity + draft codec foundation validated by CI #945 |
| [Product Onboarding Slice 2B — Target Weight + Goal Pace](product-onboarding-slice-2b-target-weight-goal-pace.md) | In progress | `apps/features/onboarding` | Goal/Target Weight/Goal Pace local + Body foundations validated; remaining picker/recommendation gates are tracked, while onboarding sequence continues from O1 |
| [Canonical Supabase Owner Migration](canonical-supabase-owner-migration.md) | In progress | Supabase + domain repositories | Body foundation + P1 `user_profiles`/`user_app_preferences`/`email_verified_at` are live |
| [Account / Profile / App Preferences Canonical Split](account-profile-app-preferences-canonical-split.md) | In progress | Supabase + Account/Profile/App Mode composition | P1 schema is live; Product Onboarding lane starts with App Mode, while account contact verification is a parallel lane |
| [Profile & Account Data Persistence](profile-account-data-persistence.md) | In progress | `users` account root + Profile/Settings/Auth adapter | Independent A1: real email/mobile add/change/verify; required for account/settings acceptance but not an O1 onboarding blocker |
| [Canonical Body Owner Repository Cutover](canonical-body-owner-repository-cutover.md) | In progress | `apps/features/progress` + onboarding/Profile/Settings composition | Body A + B1 validated (#1135/#1153); final Profile/Settings mirror shutdown follows canonical Profile cutover |
| [Adaptive navigation and action entry](adaptive-navigation-and-actions.md) | Ready | `apps/shared`, `apps/core`, `apps/app`, Settings, affected features | Designing custom tabs, Home composition, or feature action placement |
| [Material 3 Expressive foundation](material-3-expressive.md) | In progress | `apps/core`, `apps/app` | Changing shared theme, navigation, buttons, motion, or accessibility behavior |
| [Screen catalog and module plan](screen-catalog-and-module-plan.md) | Ready | `apps/app`, `apps/core`, `apps/shared`, affected features | Starting a screen or module vertical slice |
| [Supabase foundation](supabase-foundation.md) | Needs decision | `supabase/`, `apps/shared`, affected features | Starting Auth, data, RLS, Storage, or protected AI work |

## Product Onboarding execution order

```text
Foundation: Body B1 + P1 canonical schema          VALIDATED / LIVE
        ↓
O1 durable App Mode / active_tabs                  NEXT (#11)
        ↓
O2 common User Profile owner + section activation
        ↓
O3 Body Goal section + Body/Profile parity
        ↓
O4 Wellness placement + canonical owner
        ↓
O5 Nutrition Profile + Nutrition Targets split
        ↓
O6 Workout Intro/Profile/Targets split
        ↓
O7 Health Connections decision/integration
        ↓
O8 Review + edit-back + draft/resume reconciliation
        ↓
O9 truthful Plan Building/finalization + existing Congratulations
        ↓
O10 full mode/device/persistence acceptance
        ↓
later legacy-column cleanup migration
```

Independent account lane:

```text
A1 real email/mobile contact verification (#8)
```

A1 is required before final account/settings acceptance but does not block O1–O3 Product Onboarding persistence.

Do not skip a Product Onboarding slice before its validation evidence is recorded in `product-onboarding-canonical-execution.md` and Issue #40.

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

## Owner Approval Lifecycle

[Feature Development Workflow](../FEATURE_DEVELOPMENT.md) is the canonical detailed Owner Approval contract. Task files record the applicable trigger, approved scope, explicit non-changes, and approval evidence; they do not broaden the gate.

Mandatory Owner Approval applies only to a new independently scoped product task/feature slice, an unapproved product-visible UI/UX change, or a Supabase table/column shape change. Normal implementation subtasks inside an already approved scope are not new tasks and proceed without separate approval when they are necessary to complete that scope. If implementation discovers a new trigger outside the approved boundaries, record it as a follow-up and return to the Owner Approval Gate before implementing it.

`Ready` describes task preparedness. It does not override the Owner Approval Gate. If an Owner Approval trigger applies, `Approval status: Approved` is required before implementation begins.

## Multi-Agent Active Handoff

Chat history is not canonical project state. Repository source, canonical docs and ADRs, the active task brief, Git state, live PR/tracker state, and exact validation evidence are the shared project memory. This contract is role-based and must not assign fixed capabilities to particular models or agent products.

### Roles And Single Implementation Ownership

- **Planning owner:** shapes scope, decisions, and the implementation approach. Planning work is read-only unless this role also becomes the recorded Implementation owner.
- **Implementation owner:** the only active role permitted to modify the current task slice.
- **Review owner:** inspects the implementation and records findings. A reviewer must not silently become an implementer.

At most one active `Implementation owner` may own a task slice at a time. Other agents may inspect, reason, review, identify risks, and propose findings without modifying that slice. Changing the Implementation owner is execution coordination, not product approval, and does not trigger the Owner Approval Gate when the same approved scope continues.

The `Active Handoff` block in [TEMPLATE.md](TEMPLATE.md) is a compact recovery checkpoint, not a live activity log. Do not update it after every small edit. Refresh it at meaningful durable checkpoints such as a material decision, major implementation milestone, important validation result, important blocker, implementation pause, ownership transfer, or final handoff.

### Planned Handoff

When the Implementation owner intentionally pauses or transfers work, it should, where practical:

1. stop new implementation edits;
2. refresh the active task's repository anchor, current implementation state, validation completed and remaining, blocker, open review findings, and next exact action;
3. record observed uncommitted/dirty files without assuming who created them;
4. set the implementation ownership state to `Handoff pending`, `Paused`, or `Blocked`; and
5. leave the task brief compact and source-backed, without chat transcripts or terminal-log dumps.

The receiving owner still performs repository reconstruction before editing; the outgoing checkpoint is evidence to verify, not truth to trust blindly.

### Unexpected Takeover

If the previous Implementation owner is unavailable because of context/session loss, usage limits, a crash, an interrupted tool session, or another agent transition, the receiving agent must not depend on an outgoing handoff. Before editing, it must:

1. inspect `git status --short --branch`, the current branch and `HEAD`, staged and unstaged diffs, recent commits, and all observed uncommitted/dirty files;
2. read `AGENTS.md`, the active task brief, its relevant canonical docs/ADRs, recorded validation, and open review findings;
3. inspect the relevant live PR and tracker state when applicable;
4. confirm that it is continuing the same approved task slice without changing its approved scope;
5. confirm there is no known concurrent Implementation owner still modifying the same slice; and
6. record `Previous Implementation Owner → Receiving Implementation Owner` and the verified takeover state in the active task before source edits begin.

The receiving agent may then assume `Implementation owner` without Owner Approval. If concurrent ownership remains ambiguous, it must keep source work read-only and report the ambiguity rather than risk overlapping edits.

Never automatically discard, reset, stash, overwrite, or recreate existing work during reconstruction. Inspect and preserve dirty changes; do not claim who owns them unless repository evidence establishes that fact.

### State Verification And Precedence

Use this precedence when records disagree:

```text
Current runtime/source and Git state
→ live PR/tracker state
→ canonical architecture/product docs
→ active task handoff snapshot
→ previous chat claims
```

A handoff branch, SHA, PR, tracker, or task-state record is a timestamped snapshot. Report mismatches and refresh the handoff block after verification. A stale snapshot must never cause an automatic checkout, reset, revert, stash, or overwrite.

Validation evidence remains valid only for the exact SHA and environment it records. If `HEAD` moved, keep the earlier result as historical evidence, record validation still required for the current tree, and rerun the smallest applicable checks before making a current validation claim.

### Review Finding Continuity

Record open findings compactly in the task brief with a stable ID, severity, status, observed SHA, and evidence or follow-up reference. Use `Open`, `Resolved`, or `Deferred`; mark a finding `Resolved` only after its fix and applicable validation are recorded. Link external PR comments rather than copying full conversations. A Review owner may record or re-evaluate findings, but must receive Implementation ownership before modifying source to resolve them.

Existing task briefs do not require bulk migration. Adopt the handoff block when a task next reaches a meaningful checkpoint, pauses, changes implementation ownership, or needs recovery.

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
- **no screen design/UI may change unless it is included in the owner-approved task scope or receives later explicit owner/design approval**;
- approved visible UI/UX scope does not require repeated approval for individual implementation details;
- if an unapproved visual improvement is discovered during implementation, record it as a follow-up and preserve existing rendering until approved.

The design-system consolidation implementation is validated under GitHub Issue #6 and PR #22. The parent task owns stable architecture rules; child slices contain implementation evidence.

## File Contract

Each task file should contain:

1. A clear outcome, current status, verified evidence, and success criteria.
2. In-scope and out-of-scope boundaries plus ownership and dependency notes.
3. The Owner Approval trigger classification and approval evidence when the canonical gate applies; normal engineering decisions inside approved scope do not require Owner Approval.
4. A short implementation checklist, validation evidence, and exit criteria.
5. For UI-affecting work, an explicit reference to the canonical design-system guardrails and the approved visible scope or later visual-change approval.
6. A compact active handoff checkpoint when work pauses, ownership changes, or recovery is needed; normal uninterrupted single-agent work does not require continuous handoff bookkeeping.

Start new feature work from [TEMPLATE.md](TEMPLATE.md). Existing task briefs may be migrated when they next become active; do not rewrite historical task state just to match the template unless it conflicts with a current canonical architecture or safety/product guardrail.

Use status values `Ready`, `In progress`, `Needs decision`, `Blocked`, `Validated`, or `Superseded`. Move a task to [the archive](../archive/README.md) only after its outcome is validated or superseded and its durable decision/status has been moved to the relevant canonical doc.

Never put secrets, personal data, unverified completion claims, machine-specific paths, or full conversation transcripts in these files.
