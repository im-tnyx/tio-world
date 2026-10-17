# GitHub #526 — Flutter Routine Delete Slice B

**Status:** In progress (owner approved 2026-10-17)
**Implementation owner:** GitHub-connected implementation session (single owner).
**Scope approval:** User: “go next slice b @GitHub @Linear @Supabase” after Slice A merge.

## Verified source and trackers
- GitHub main baseline 965b5873ccafc15253c129ce59165560112d1bb3 (merged #586). Github #526 open; Linear TNYX-81 broad W4 Backlog/blocked by TNYX-78 and TNYX-80.
- Supabase Tio-world ACTIVE_HEALTHY, 62 migrations applied; authenticated EXECUTE for delete_user_workout_routine(uuid,uuid,bigint) true, anon/PUBLIC false. No DDL/deploy planned.
- Program Detail and expanded Library use same RoutineMetadataCard with nullable onDelete. Core exposes showTioConfirmationBottomSheet destructive mode.
- apps/app composition/workout_providers.dart has no Delete wiring; apps/app/routing/shell/shell_route.dart owns owner/session gated entry; apps/features/workout owns feature workflows and screens.
- Read repository AGENTS.md, apps/features/AGENTS.md, .ai/workflow.md and feature approval, Core theme README, ADR-0015 and canonical Routine contract.

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
- [ ] Provider/gate with auth/login cycle scope; no fake fallback.
- [ ] Feature-owned confirmation and typed result/unknown workflow.
- [ ] Both Routine surfaces and refresh bridge.
- [ ] Focused Flutter tests and exact-head CI.
- [ ] Security/code review, handoff, owner merge gate.

**Validation:** No Slice B CI yet; GitHub connector cannot inspect Windows working tree or run the owner's SDK.
**Final status:** In progress; keep GitHub #526 and Linear W4 open.