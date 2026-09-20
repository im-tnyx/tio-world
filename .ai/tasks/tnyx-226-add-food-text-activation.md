# TNYX-226 — Activate Add Food natural-language submit → Meal Editor handoff

**Status:** In progress
**Primary owner:** ChatGPT
**Affected platforms:** Flutter phone app / Nutrition

## Owner Approval and Scope Boundary

**Approval status:** Approved
**Approval evidence:** Owner said `go` after the exact source slice was stated: activate the existing `What did you eat?` surface using the existing approved geometry, wire keyboard/Mic/Send behavior to `MealTextParseController`, hand successful `MealLoggingDraft` into the existing Meal Editor, and preserve explicit `Log Meal` persistence.
**Approved product/UI/data-shape boundaries:** Existing Add Food describe-meal surface only; existing Meal Editor only; no redesign.
**Explicit non-changes:** No voice/photo/search/saved/recent activation. No Edge Function/provider/schema/RLS/RPC/migration change. No direct provider calls from Flutter. No services/api. No auto-save after parse. No Gemini fix in this slice.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** ChatGPT
**Repository state last verified:** `main@1f409e3039fc3d7945e94c2c007ba23b865b2ce4`
**Branch:** `tnyx/tnyx-226-add-food-text-activation`
**Linear:** TNYX-226 In Progress; no hard blockers. TNYX-229 remains production release/readiness gate. TNYX-239 owns deferred Gemini 503 follow-up.
**Live parser:** ACTIVE v36, `verify_jwt=true`, bundle `98b79e40c0613db0a2cfc523d42ff6068d8c1a669aed0a8c2db779e647dd8274`.
**Runtime provider note:** OpenAI fallback is working. `MEAL_INTERPRETER_PRIMARY=openai` has not been changed through this session because the connected Supabase surface exposes no secret/env write action.

## 1. Discovery

### User Outcome

From Meal Diary → Add Food, the existing primary `What did you eat?` surface becomes a real text entry. The user can submit natural-language meal text, see bounded processing/failure state, receive a provider-neutral parsed draft, review/correct it in the existing Meal Editor, and create durable history only by explicitly pressing `Log Meal`.

### Success Criteria

- existing Add Food hierarchy/geometry remains recognizable and governed;
- left keyboard icon remains permanently visible and only toggles focus/software keyboard visibility;
- blank trimmed input shows the existing Mic action and cannot submit;
- nonblank input changes only the right action to Next/Send;
- IME and visible Send use one canonical submit handler;
- duplicate in-flight submission remains suppressed by `MealTextParseController`;
- recoverable failures preserve entered text and allow retry;
- success returns canonical `MealLoggingDraft` only;
- Meal Editor opens with a real category/date-time context and existing detailed-create repository;
- explicit `Log Meal` is the only durable write;
- successful create invalidates the affected diary date;
- no provider DTO/secret leaks into Flutter/domain.

## 2. Codebase Exploration

Verified on current main:
- `AddFoodSheet` still renders describe-meal as inert/unavailable and only returns Quick Add.
- `MealTextParseRepository`, `SupabaseMealTextParseRepository`, app `mealTextParseRepositoryProvider`, and `MealTextParseController` already exist.
- `MealTextParseController` owns trim/blank guard, processing, duplicate suppression, safe failure mapping, retry, and text-capture draft enforcement.
- `MealEditorCreatePage` + `MealEditorDetailedCreateController` already own review/edit and explicit durable detailed create.
- canonical `mealLogRepositoryProvider` concrete implementations support `DetailedMealLogCreateRepository`.
- Meal Diary already owns selected date and diary invalidation.
- canonical meal categories and `suggestedMealCategoryId(...)` are already implemented.
- no DB/backend source change is required.

## 3. Clarification

### Initial date/time contract

The Add Food action is diary-level, not category-row-level. TNYX-207 requires preserving selected Diary date intentionally.

Chosen initial text-meal context:
- date = currently selected Meal Diary date;
- clock time = one local clock snapshot taken when the text flow succeeds/opens the editor;
- combine them into one local `DateTime`;
- category suggestion = existing `suggestedMealCategoryId` against active canonical categories using that combined local date-time;
- if the suggested canonical category is unavailable, keep category unresolved rather than inventing a fallback category;
- Meal Editor remains the correction/review boundary.

This differs intentionally from legacy Quick Add behavior, whose current tests snapshot today's full local datetime; TNYX-226 has an explicit selected-diary-date preservation requirement.

### Navigation/ownership

- App composition injects `MealTextParseRepository?` into `MealDiaryPage`.
- Nutrition feature owns presentation/controller orchestration.
- Add Food modal returns either Quick Add or a parsed draft result; it does not persist.
- Meal Diary opens the existing Meal Editor and supplies the existing detailed-create repository capability.

## 4. Architecture Design

```text
Meal Diary selected date
→ Add Food
→ editable What did you eat?
→ MealTextParseController
→ MealTextParseRepository
→ Supabase Edge Function
→ MealLoggingDraft
→ Add Food result
→ Meal Diary resolves selected-date + clock + category suggestion
→ existing MealEditorCreatePage
→ explicit Log Meal
→ DetailedMealLogCreateRepository
→ canonical MealLogEntry
→ invalidate affected diary date
```

Provider selection remains server-side and invisible to Flutter.

## 5. Implementation Plan

- [x] Introduce a typed Add Food result that can carry Quick Add or parsed text draft.
- [x] Convert only the describe-meal surface to a stateful editable interaction.
- [x] Preserve leading keyboard icon; implement focus/keyboard toggle.
- [x] Preserve Mic for blank input; show Send for nonblank input.
- [x] Wire IME + visible Send to one submit function.
- [x] Render safe processing/failure/retry state without raw provider details.
- [x] Inject parser repository from app composition into Meal Diary.
- [x] On parsed success, derive selected-date + local-clock context and canonical category suggestion.
- [x] Open existing Meal Editor with canonical draft and detailed-create repository.
- [x] Invalidate diary state after explicit successful create.
- [x] Keep Quick Add behavior unchanged.
- [x] Update focused widget/integration tests.
- [x] Run Flutter CI and complete diff review.
- [x] Draft PR → review-ready only; no merge without separate authorization.

## 6. Quality Review

- Source head reviewed: `d4b4d403723c3aa313443c05d3db59965153002c`.
- Flutter CI #2674 passed on that exact source head.
- Flutter analyze: PASS.
- Dart analyze: PASS.
- Flutter tests: PASS.
- Dart tests: PASS.
- Prior CI failures were bounded to analyzer promotion/lint findings and widget-test assumptions; all were fixed before the passing run.
- Final diff remains limited to eight TNYX-226-owned files.
- No unresolved PR review threads.
- No backend/Supabase/provider/config/secret mutation.
- No blocking review finding.

## 7. Final Handoff

Implementation is complete for this approved source slice and is ready for review.

Validated behavior:
- Add Food text entry activates only when a parser repository is supplied.
- blank text keeps unavailable Mic; nonblank text exposes Send;
- keyboard affordance changes focus/software-keyboard visibility only;
- visible Send and IME Send converge on the same parser submit path;
- recoverable parse failure preserves the user's text and retries through the existing controller;
- successful parse hands only `MealLoggingDraft` into the existing Meal Editor;
- initial editor context preserves selected Diary date plus one current-local clock snapshot;
- existing category suggestion and existing category/date pickers remain the correction boundary;
- persistence occurs only through explicit `Log Meal`;
- successful create invalidates the affected diary date;
- Quick Add remains unchanged;
- voice/photo/search/saved/recent remain outside this slice.

PR: #300.

Stop gate: do not merge without separate owner authorization. No Supabase deploy/config/provider mutation belongs to this PR.
