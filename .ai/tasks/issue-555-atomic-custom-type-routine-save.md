# #555 bounded atomic Custom Exercise type / Routine Save security fix

**Status:** in review and exact-head disposable validation; no source merge, hosted DDL or app release.
**Implementation owner:** Supabase DB for this branch; Flutter model/adapter/controller parity belongs to consolidated W4 PR #551.
**Owner direction:** 2026-10-15 “सही करके आगे बढ़ें” after independent Codex identified the type TOCTOU P2 on PR #551.
**Base:** PR #561 `security/issue-534-archive-routine-save`; this is a **separate stacked DB-only PR #562**, not a change to #534's archive-status scope.

## Observed defect
The Custom Exercise's `exercise_type` is owner-editable. Flutter #551 validates an Exercise Type before network Save/Create, but another device for the *same owner* can UPDATE the type before the transaction's row lock. Before this fix the DB checked only owner+active status, allowing an old KG/REPS Set after type changed to Duration/KM/TIME. Historical type changes **after** a completed Save still need separate product/read policy; this bounded fix does not make Exercise definitions immutable.

## Approved bounded engineering decision
1. Reuse the existing owner-scoped `FOR SHARE` lock from #534 inside the Save RPC. Read locked `exercise_type` and check the optional **preflighted Custom type** supplied per Exercise entry via `expected_exercise_type`, including explicit JSON null. The canonical eleven storage tokens remain from W3D2.
2. **No new table/column/RLS/grants/function signature, UI layout, step-count or external service.** Save's JSON entry whitelist now permits only this one additional *unpersisted* hint. Ignore the hint in normalized revision/idempotency content: a **same-token replay succeeds ahead of any new type check**, even after a later legitimate type change/archive.
3. For legacy clients that do not send a hint, reject Set target shapes incompatible with the **currently locked type**: Duration prohibits reps/repsMax/load/distance; Distance/Duration prohibits reps/repsMax/load; REPS/untyped prohibits distance/duration. STEPS/TIME has no canonical step-count storage and cannot newly Save even with blank Sets.
4. The archived Custom historical entry still permits only identical original ID/reference and ordered entire Set payload; unrelated edits/removal permitted. Do not silently migrate historical metric data, change Custom editor type edit semantics, or break user ownership checks.
5. Flutter W4 supplies the hint only for fresh owner-verified active Custom entries. An archived historical reference has no type expectation and is protected by #534's historical identity rule. Legacy omitted hint remains accepted when targets fit current type.

## Tests and validation
- Disposable SQL `tnyx_555_atomic_custom_type_save.test.sql`: new matching type and duration targets, stale preflight type after update, legacy mismatched targets, unchanged revision/Set IDs after rejection, same-token replay, atomic Create rejection/success, unsupported STEPS.
- Real two-session race `tnyx_555_atomic_custom_type_concurrency.sh`: UPDATE-type-first vs Save-first, row lock wait, strict transaction ordering and rollback.
- Existing #534 nullable-metric fixture now declares its canonical distance/duration type so the new guard has meaningful historical provenance.
- Existing DB CI replay+lint/security matrices remain mandatory; fresh GitHub Actions results must be inspected before Ready for Review or merge. Flutter PR #551 CI must confirm serialization, Create forwarding, A→B→A pending owner protection and existing W4 regressions.
- Separate #559 hosted migration and 4–5-device old/new-client owner QA; **no automatic hosted migration**. When #561 merges, rebase/retarget this stacked PR onto updated main using non-destructive operations only.

## Decision boundaries / rejected alternative
Do not freeze Custom Exercise type permanently whenever referenced: that changes Custom editor user-visible product behavior and historical semantics and needs independent owner decision. Do not introduce a step-count column or guessed Reps conversion (future #555 STEPS feature). The bounded alternative is transaction-time typed expectation plus legacy target-shape guard, with current historical-edit behavior preserved.

## Merge gate
#561 → #562 DB-only follow-up → #551 consolidated Flutter. Independent Codex review and exact-head CI required; AGENTS.md security review and branch rules before merge; explicit owner instruction before source merge. Hosted migrations and APK rollout require distinct authorization.
