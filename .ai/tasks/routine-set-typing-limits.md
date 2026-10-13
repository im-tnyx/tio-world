# Routine Set typing limits

**Status:** In progress, owner-approved in the 2026-10-13 conversation ("text field par max type limit hona chahiye"; "go next").
**Planning owner:** Linear TNYX-81 W4 umbrella; no new standalone Linear issue authorized.
**Implementation owner:** This connected GitHub session, exclusively `tnyx/routine-set-input-typing-limits`, child of Draft #546.
**Review owner:** Independent Codex on the child Draft PR.
**Ownership transition:** Not applicable; new bounded child scope, never edit #533/#537/#541/#544/#546 branches.
**Repo state last verified:** GitHub connected branch `tnyx/routine-set-input-typing-limits` at `759d21a84bd79ae7774a254a8a2a365372c8150c` (from #546); local worktree unavailable via connector.
**Affected platform:** Flutter Workout Create/Edit Set input rows and advanced Set editor only.

## Approval and concrete contract
- User requests **max typed input limits**, not a new database constraint or a redesigned UI. Apply to Set Reps, Range min/max, Weight KG/LB and optional advanced Rest seconds. Routine name, nutrition, active session, watch and backend outside scope.
- Live Tio Supabase `user_workout_routine_sets.reps/rest_seconds` are signed int32, `load_kg` is double precision (no business maximum). Do **not** add Supabase DDL. Reps/Rest inputs accept digits 0..2147483647 with 10-character maximum; actual Reps still require >0 and Range max ≥ min before Save.
- Weight KG/LB accepts **at most 6 whole digits and 3 fractional digits**, one decimal separator, no minus/exponents or multiple dots, preserving blank and in-progress `.` transient input and existing canonical kg when displayed rounded lb is unchanged. This is UI typing hygiene only, *not* a max approved lifting weight in the domain/database.
- Reuse feature-owned input formatters for both inline `RoutineSetInputRow` and `RoutineSetEditorSheet`. No Core API change, new theme tokens, geometry/spacing change or new service.
- Invalid overlimit keyboard/paste input stays out of field. Previously valid input and Save gating preserved. Important: PR #546 currently has separate unresolved Codex P1 re stale inline controllers after advanced details sheet editing and P2 Create options sheet auth revocation; DO NOT attempt to resolve or claim readiness under this child.

## Evidence and dependencies
- Root `AGENTS.md`, `apps/features/AGENTS.md`, Core theme README, .ai/task template read. Current Draft #546 HEAD `759d21a84bd79ae7774a254a8a2a365372c8150c`, #544/#541/#537/#533 unmerged. TNYX-81 Backlog blocked by TNYX-78/TNYX-80.
- Existing `TioInput.compactNumber` and `TioInput.numericEditor` already forward `inputFormatters`; source has digitsOnly or dot-allow inline and no input typing bounds in advanced sheet. Canonical SetPrescription validates Reps and Rest and nonnegative finite Weight; use existing.
- Dedicated formatter unit tests (typed/edit/paste/leading zero, int32 boundaries, max fractional digits) and one live RoutineSetInputRow widget typing test; keep existing first-Set blank/Save behavior intact.
- **Gates:** CI evidence for exact child source, independent review, known ancestor #546 P1/P2 and #544 long-press/Create tests, #537 old route tests, physical device 320dp keyboard checks. Do not merge/deploy; no Supabase mutation.

## Handoff
Implementation and validation not yet complete.
