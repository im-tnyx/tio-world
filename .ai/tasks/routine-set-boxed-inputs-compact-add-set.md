# Routine Set boxed numeric fields + compact Add Set

**Status:** In progress, draft implementation. **Approval:** Owner-approved two screenshot references in conversation on 2026-10-13; accepted UI boundaries recorded under Linear [TNYX-81](https://linear.app/tnyx/issue/TNYX-81/w4-programs-and-routines-canonical-content-composition-and-builders). **Implementation owner:** This connected GitHub session, exclusively new visual child slice on `tnyx/routine-set-boxed-fields-compact-add-set` based on Draft #549 head `0d43c4646aa85ff38c13c0e8488eab012a198420`. **Review owner:** Independent GitHub/Codex reviewer pending. **Platforms:** Flutter phone Create and Edit Routine only.

## Discovery and ownership
- Source: root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/workflow.md`, task TEMPLATE, design-system token consolidation, theme README, routine-library canonical doc, GitHub #544/#546/#549, Linear TNYX-81, runtime source/test read at #549 head. The broad TNYX-81 remains Backlog, blocked by TNYX-78/TNYX-80; this is a bounded UI refinement, not acceptance of W4.
- Existing Workout `RoutineSetInputRow` is reused by both Create and Edit. Existing `TioInput.compactNumber` renders *no border* (underline on focus), so it cannot produce the two screenshots' boxed fields without a new variant. Core `TioInput` **standard** already supports centered input, outlined border, hintStyle/contentPadding/textStyle and a controller; reuse it feature-locally. Existing `TioButton.secondary` is a governed 46dp interactive target and exposes a leading icon. Do not change Core globally.
- **Owner UI acceptance:** Create `SET/KG(or LB)/REPS ▼`; Edit `SET/PREVIOUS/KG(or LB)/REPS ▼`; real editable Weight/Reps outlined rounded rectangular centered boxes with muted dash when blank. Range Min and Max are distinct bordered boxes separated by `–` (not `to`); `PREVIOUS` remains a truthful dash placeholder, never a fabricated history value. Add Set remains full-width beneath table but visually compact (governed 46dp button, plus affordance, tightened Edit spacing). Follow theme in light/dark, keep 320dp and text scaling safe.
- **Out of scope:** old/new auth route behavior, repairing inherited Codex P1/P2, changing Flutter shared Core API/theme, adding notes/image/Rest Timer, tracking PerformedSet history, schema/RLS/RPC, Routine Detail read-only layout, or parent branch updates.
- **Single-owner boundary:** Source writes only on this child branch; parents #549/#546/#544 unchanged. No other implementation owner assigned to this visual slice. This session cannot inspect a local worktree (`git status`) because no repository is mounted and no Flutter/Dart SDK is installed; GitHub remote ref + blob SHAs are the concurrency gates. No claims of local Flutter execution.

## Plan
1. Reuse feature `RoutineSetInputRow` and existing Core `TioInput` outlined style to center and box Weight, Reps, Min, Max. Preserve existing formatting, controllers, callbacks, identity, Save guards, and swipe.
2. Keep the already governed `TioButton.secondary` target, add a plus icon in Create/Edit, and tighten only the Edit gap above it. Avoid app/global button styling.
3. Add focused widget assertions for outlined fields, dash range separator, mode/blank gate, narrow viewport and compact button.
4. Inspect remote diff, run available validation honestly, request independent review. Do not merge while parent stacks and DB drafts are unvalidated.

## Risks / review gates
- `#546` unresolved P1 Advanced Set editor stale controller overwrite and P2 auth-overlay cleanup; `#544` unresolved P2 explicit Range Max and accessibility reorder. Existing ancestor #537 stale Flutter app route test and #536/#540 Supabase undeployed. This styling branch must not claim to resolve them or mask validation failures.
- Validate real Flutter widget tests and dark/light 320dp + large text; keyboard/device QA before merge. No production deployment.
- Initial validation status: NOT RUN. No local SDK available. GitHub branch exists, initial HEAD equals #549 SHA; task file is first intended new commit.
