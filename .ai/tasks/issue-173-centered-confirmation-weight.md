# #173 — Compact centered confirmation — Core presenter + Weight adoption

**Status:** In progress (stacked after #701; do not merge).
**Approval:** Owner 2026-10-27: "Go next ui meri taraf se thik h only conformation card change karna h". Previous owner direction: Routine Delete's centered small-button card is reference; make a reusable design across suitable confirmations. All other Weight UI approved/frozen.
**Implementation owner:** `im-tnyx`; independent `im-tio` review account is not authorized for implementation.
**Immediate parent:** `feat/issue-700-progress-weight-timeline@0f5566e2de28d853bba07f794ec2df27808b3546` (PR #701 OPEN, not merged).
**Authoritative tracker:** GitHub #173. Related #700/PR #701, Linear TNYX-119 In Progress; Linear TNYX-222 shared confirmation intent Done.

## Source audit and design boundary

- Routine Delete renders feature-local, centered `Dialog` with `TioCard.elevated`, `TioSize.dp320`, `TioSize.dp38` visual-minimum Tio semantic buttons and accessible Material targets. It is the approved visual baseline; its deletion/RPC/unknown-outcome logic remains Workout-owned.
- Existing Core `showTioConfirmationBottomSheet` already owns text/action semantics and `TioConfirmationIntent.standard|destructive`, and optional `activeWhileOpen: ValueListenable<bool>` route-scoped owner invalidation guard; Progress Weight Delete is its current destructive consumer.
- **Chosen:** New additive public `showTioConfirmationDialog` in the same Core presenter source, reusing the Core internal confirmation composition, variants, intent, result conventions, and lifecycle binding. Centered presentation changes only in the new entry point: transparent `Dialog`, max 320dp, existing compact 38dp button visual minimum, centered theme text/icon, scrollable narrow/large text. No new tokens, custom button/color scheme or duplicate business operations.
- **First consumer:** Progress Edit Weight -> Delete only. Keep existing title/message, explicit destructive Confirm, exact-ID / owner-session guard, `bool?` dismissal semantics and ambiguous-delete canonical reconciliation. No other Weight UI or workflow changes.
- **Non-goals:** Modify #701 itself; Routine migration, all other confirmation migrations, Body Goal, Settings/Logout, Nutrition, Delete Account, global sheet style/geometry or confirmation action semantics; any database, RPC, Storage, RLS or Auth changes. Do not infer global replacement permission.
- **Tests:** Core dialog geometry, semantics, compact minimum buttons, dark/light, accessibility and cancellation/barrier, session invalidation; Progress Delete editor dialog lifecycle, Cancel=no-delete and confirm=one exact ID. Ensure existing original Core bottom-sheet consumers unchanged.
- **Verification gates:** Branch parent ancestry, only Core UI + Progress sheet/tests + canonical docs/task; Flutter analyze/unit/widget and Docs Hygiene on final exact HEAD, independent review; physical device layout QA not claimed unless actually performed. PR stacked onto #701 parent until parent is independently approved/merged; do not merge without explicit owner Go merge. Local Windows checkout / Flutter SDK unavailable through connected GitHub tools.
