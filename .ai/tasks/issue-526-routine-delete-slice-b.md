# GitHub #526 — Flutter Routine Delete Slice B

**Status:** In review — scoped Flutter implementation; exact source-head CI success before this handoff update (2026-10-17)
**Implementation owner:** GitHub-connected implementation session (single owner).
**Scope approval:** User: “go next slice b @GitHub @Linear @Supabase” after Slice A merge.

## Verified source and trackers
- GitHub main baseline 965b5873ccafc15253c129ce59165560112d1bb3 (merged #586). Github #526 open; Linear TNYX-81 broad W4 Backlog/blocked by TNYX-78 and TNYX-80.
- Supabase Tio-world ACTIVE_HEALTHY, 62 migrations applied; authenticated EXECUTE for delete_user_workout_routine(uuid,uuid,bigint) true, anon/PUBLIC false. No DDL/deploy planned.
- Program Detail and expanded Library use same RoutineMetadataCard with nullable onDelete. Core exposes showTioConfirmationBottomSheet destructive mode.
- apps/app composition/workout_providers.dart has no Delete wiring; apps/app/routing/shell/shell_route.dart owns owner/session gated entry; apps/features/workout owns feature workflows and screens.
- Read repository AGENTS.md, apps/features/AGENTS.md, .ai/workflow.md and feature approval, Core theme README, ADR-0015 and canonical Routine contract.

## Owner-approved confirmation UI refinement (2026-10-17)
- Approval: "go next yes sahi h botton ka height chhota rakhe", following the explicit request for a screen-centered popup card in place of the Delete confirmation bottom sheet.
- **Only Routine Delete** uses a compact center Dialog with existing `TioCard.elevated`, `TioButton.destructive`/`TioButton.secondary` and theme typography. The owner subsequently requested a narrower card: max width changed from `TioSize.dp480` to new governed `TioSize.dp320` (320dp); it still shrinks for narrow mobile viewports. Scoped action visual minimum remains `TioSize.dp38`, preserving Material's accessible padded tap target and text growth.
- Do NOT change showTioConfirmationBottomSheet globally, other confirmations, global button height, Delete RPC/security/session checks, backend, and existing Routine options bottom sheet.
- Validation: visible Dialog (not BottomSheet), compact button theme/tap targets, cancellation and confirm results, dark + narrow + large text, identical one-write/no-retry semantics.
- GitHub CI `39012457115` initially failed **only** the Core visual-ownership guard because the new Dialog used raw `Colors.transparent`; Flutter Analyze and app-workout tests passed. Corrected to `TioPalette.transparent` and added explicit width assertion and governed primitive; subsequent exact-head CI is the authoritative gate. Preserve and disposition the four existing PR review findings independently (including prior owner title and stale modal privacy risks); successful CI alone is not sufficient merge evidence.

## Approved behavior
- Fresh owner/Program/Routine revision inspect BEFORE showing confirmation; cancel sends no RPC.
- App container owns one in-process RoutineDeleteAttemptGate across repository recreation and login cycles. Fail closed on missing Supabase/auth/bootstrap or changing owner/cycle.
- Use existing Core destructive confirmation. After explicit confirmation dispatch exactly one owner-scoped version-CAS RPC, never direct DELETE or retry. Only RPC boolean true is confirmed.
- Timeout/ambiguous readback remains unknown; show truthful messaging and refresh current-owner views without fake optimistic removal. Sanitize DB/provider errors.
- Reuse existing onDelete card capability in Program Detail and expanded Library. Single-flight across both entry surfaces; guarded list reload.

## Explicit non-goals
- No migrations, Supabase deploy, privileged table grants, Move Routine #569, Program Delete #567, media, Play, Workout Start, broad UI redesign, watch or backend services.
- In-memory unresolved guard DOES NOT survive OS process restart. No claim of durable exactly-once. Any persistent idempotency needs a separate data decision.
- No app-store release or device QA claim in this repository slice.

## Execution
- [x] Provider/gate with auth/login cycle scope; no fake fallback.
- [x] Feature-owned confirmation and typed result/unknown workflow.
- [x] Both Routine surfaces and refresh bridge.
- [x] Focused Flutter tests and exact-source-head CI at `aa22d47682ac3483995f8bed551984313b154ef7`: [Flutter CI #39010679343](https://github.com/im-tnyx/tio-world/actions/runs/39010679343), all 5 jobs SUCCESS. This handoff docs commit requires its own exact-head check.
- [ ] Manual security/code review disposition, owner merge gate and device QA. No autonomous merge.

**Validation:** GitHub Flutter CI run `39010679343` at implementation commit `aa22d47682ac3483995f8bed551984313b154ef7` completed SUCCESS: Analyze Flutter and Dart / test Dart, Test Flutter (core-wear), Test Flutter (app-workout), Test Flutter (nutrition-onboarding), aggregate Analyze and test. Prior failed runs were caused by the new Program Detail wrapper removing the existing read-only route and by Dart nullability/analyzer errors; both were corrected without weakening destructive authorization. No local Windows Flutter execution/device QA verified.
**Review focus:** stale on-screen confirmation after account switch, safe snackbar placement under nested Navigator, partial auth revocation and app restart semantics; do not treat process-local single-flight as durable persistence.
**Final status:** REVIEW; branch unmerged. Keep GitHub #526 and Linear W4 open.