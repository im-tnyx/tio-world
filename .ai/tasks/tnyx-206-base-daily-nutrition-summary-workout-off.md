# TNYX-206 — N3A Base Daily Nutrition Summary (workout OFF)

**Status:** In progress  
**Primary owner:** `apps/features/nutrition`  
**Affected platforms:** Flutter phone Meal Diary

## Owner Approval and Scope Boundary

**Approval status:** Approved  
**Initial approval:** Owner said `go` after TNYX-205 PR #266 was squash-merged and local `main == origin/main == 2866ded8a963b64a99e41b5007da4753a922c7cc` with a clean worktree.  
**Approved N3A boundary:** selected-day Daily Nutrition Summary, workout-OFF `Target - Eaten = Remaining`, Carbs/Protein/Fat/Fiber status, and a calendar calorie-progress ring derived from the same canonical budget/MealLog truth.  
**Owner-approved visual refinements during implementation:** compact screenshot-like card; no extra title/divider/large metric boxes; lighter text weights; all four nutrient cells remain visible even when data is unavailable; resolved card sits close to the calendar instead of leaving the handle-clearance void; calendar rings enlarged one step; progress is the outer ring, selection is smaller inside with zero decorative gap; progress and selection use distinct semantic colors.  
**Explicit non-goals:** no Workout calorie term/N10 policy, no full N11 schedule/eating-style UI, no TNYX-207 AI/text logging, no Supabase table/column/migration/RLS change, no persisted daily-total cache, no unrelated Diary redesign.

## Active Handoff

**Planning owner:** ChatGPT  
**Implementation owner:** ChatGPT  
**Review owner:** None active until final exact-head validation/review handoff  
**Branch:** `tnyx/tnyx-206-n3a-base-daily-nutrition-summary-workout-off`  
**Base:** `main@2866ded8a963b64a99e41b5007da4753a922c7cc`  
**Draft PR:** #267  
**Tracker:** Linear TNYX-206 — In Progress  
**Repository state:** connector/API session; no local worktree state is claimed.  
**Pre-handoff source/docs head:** `171883ed3bb284733cbb764f990f4c53329da06d`; this brief refresh creates the next governance head.  
**Validation state:** earlier heads have produced green and failed/superseded CI during implementation. Final exact-head CI must be rerun after this governance commit; do not treat an earlier green run as final evidence.  
**Merge state:** Draft PR; merge is not authorized.

## Global UI / Design-System Guardrail

Read and followed before the visual changes:

- `AGENTS.md`
- `apps/features/AGENTS.md`
- `.ai/FEATURE_DEVELOPMENT.md`
- `apps/core/lib/src/theme/README.md`

Nutrition owns summary meaning and composition. Core remains domain-agnostic: its calendar receives only generic `TioDateDecoration` presentation values. The bounded Core change is visual only and reuses existing semantic roles (`primary`, `progress`, governed stroke/size values); no Nutrition color/domain meaning was moved into Core and no feature-local token bag was introduced.

## 1. Discovery

### User Outcome

A reader browsing any selectable Meal Diary date can see that date's calorie target/eaten/remaining, see Carbs/Protein/Fat/Fiber status in a compact stable card, and understand calorie progress directly on the calendar without losing selection clarity.

### Success Criteria

- Selected date is the only summary date identity; historical browsing never silently substitutes Today.
- Calories are `Target - Eaten = Remaining`; Workout is absent.
- Target calories come from selected-date `DailyNutritionBudget.strategyAdjustedTarget`.
- Eaten comes only from canonical MealLog rows for that persisted local date.
- Remaining stays signed; over-target may be negative.
- Carbs/Protein/Fat/Fiber cells are always visible. Missing consumed or target truth renders `—`, never fake zero or a fabricated partial total. Progress bar renders only when both sides exist and target is positive.
- A successful empty MealLog read is known zero consumption.
- Calendar ring uses the same Eaten/Target truth, with visual progress clamped to `0..1` while raw summary truth stays intact.
- Visible calendar dates use a bounded range read, not one network read per day.
- Calendar progress is the outer ring; selection is a smaller inner ring; the rings touch without decorative gap.
- Progress and selection are visually distinct in light/dark themes: progress uses semantic `progress`, selection/fill use `primary`.
- Resolved summary card stays compactly near the calendar while the handle retains its 48dp hit target.

## 2. Verified Runtime / Architecture Evidence

- TNYX-205 already owns `DailyNutritionBudget(date)` and canonical target validation.
- `NutritionTargetsRepository` remains the target owner; N3A does not persist duplicate daily targets.
- `MealLogRepository` remains canonical actual-entry truth.
- `MealDiaryHistoryReadModel` is presentation/category grouping and is not used as the daily nutrient truth owner.
- `NutritionSnapshot` distinguishes absent from known zero.
- Quick Add requires Calories; Carbs/Protein/Fat are optional; Fiber is not captured by current Quick Add. Therefore hiding nutrient cells based on data availability made the UI unstable and could hide Protein/Fat merely because a target was absent.
- `TioDateCalendar` already owns a generic progress decoration layer and an independent selection layer.
- Calendar handle geometry reserves a 42dp transparent band beneath the visible surface to maintain a 48dp touch target; that reserved band caused the visually large calendar-to-summary gap.
- `TioColors` already owns distinct semantic `primary` and `progress` roles, so no new color literal/token/API was needed.

## 3. Locked Decisions

| Decision | Locked behavior |
|---|---|
| Summary source | Canonical MealLogs + `DailyNutritionBudget`; never derive from section presentation totals. |
| Empty day | Complete successful empty read = known zero consumption. |
| Partial nutrient data | Any logged row missing a nutrient makes that daily consumed aggregate unavailable; never partial-sum it as complete. |
| Macro/fiber target | `DailyNutritionBudget.baseTarget` in N3A. |
| Calorie target | `strategyAdjustedTarget.caloriesKcal`. |
| Remaining | Signed `target - eaten`. |
| Nutrient presentation | Carbs/Protein/Fat/Fiber always visible; unknown side = `—`; no fake progress bar. |
| Summary geometry | Compact equation row + one horizontal nutrient row; no extra heading, divider, or large metric tiles. |
| Calendar-summary spacing | Resolved read-only card overlaps 32dp of the calendar's transparent handle-clearance band, leaving about 10dp visible gap. The card is pointer-transparent so the full handle target remains usable. Loading/error states do not overlap because Retry is interactive. |
| Ring geometry | 30dp normal-scale date circle; progress outer, selection inner/smaller, zero decorative gap. |
| Ring colors | Progress arc = semantic `colors.progress`; selection/fill = semantic `colors.primary`. |
| Range reads | Bounded inclusive local-date range capability; production Supabase path paginates the range. |
| Persistence | No new schema/table/RLS/daily-total persistence. |

## 4. Chosen Architecture

```text
explicit MealLogLocalDate
  + DailyNutritionBudgetResolver
  + canonical MealLog actual rows
        ↓
DailyNutritionSummary (derived, never persisted)
        ↓
MealDiaryPage
  ├─ compact Nutrition-owned summary card
  └─ generic TioDateCalendar decorationBuilder
       ├─ progress: normalized calorie ratio
       └─ semanticsLabel: Nutrition-owned meaning
```

Calendar visible week/month resolution uses one bounded MealLog range read plus shared canonical target resolution. Core never imports Nutrition.

## 5. Implemented Scope

- [x] Optional inclusive `MealLogRangeReadRepository` capability.
- [x] In-memory and Supabase range-read implementations.
- [x] Paged production Supabase range gateway to avoid truncation at backend row limits.
- [x] `DailyNutritionBudgetResolver.resolveMany(...)` sharing one canonical target read.
- [x] `DailyNutritionSummary` model/resolver with unavailable-vs-zero and signed Remaining rules.
- [x] Selected-day and visible-range Riverpod providers.
- [x] Nutrition Targets repository change signal so mounted summary/rings refresh after target saves.
- [x] Selected-date summary + calendar ring wiring in `MealDiaryPage`.
- [x] Quick Add/Edit targeted invalidation for history, selected summary and visible range.
- [x] Retry action for Daily Nutrition read errors.
- [x] Compact owner-approved summary card geometry and lighter typography.
- [x] Carbs/Protein/Fat/Fiber cells always visible with `—` for unavailable truth.
- [x] Compact calendar-to-summary spacing while retaining handle interaction.
- [x] Core ring geometry: enlarged 30dp circle, outer progress + inner selection, touching edges.
- [x] Core ring semantic color separation (`progress` vs `primary`).
- [x] Focused domain/data/widget/integration/Core geometry regressions.
- [x] `docs/screens/meal-diary.md` reconciled with current behavior.

## 6. Review / Validation History

Implementation self-review fixed early compile/design issues including the optimistic-conflict variable typo, invalid `TioSize.dp360` reference and a missing contract import.

Codex review on an earlier validated head reported three actionable findings; all were addressed in this branch:

| ID | Severity | Resolution |
|---|---|---|
| TNYX-206-R1 | P1 | Target repository successful writes publish a change revision; mounted selected/range summary providers re-read canonical target truth. |
| TNYX-206-R2 | P2 | Daily Nutrition error surface includes Retry, invalidating selected + range summary providers. |
| TNYX-206-R3 | P2 | Production Supabase range gateway drains pages instead of trusting one capped response. |

Subsequent owner visual review additionally locked compact card geometry, always-visible nutrient cells, reduced calendar/card gap, larger concentric ring geometry and separate progress/selection semantic colors.

### Final validation still required

- exact final branch HEAD Flutter analyze
- Dart analyze
- Flutter tests
- Dart tests
- fresh scope compare against `main@2866ded8...`
- fresh review-thread audit / Codex re-review
- PR body and Linear handoff reconciliation

## 7. Current Changed Families

Expected task-owned families now include:

- `.ai/tasks/tnyx-206-base-daily-nutrition-summary-workout-off.md`
- thin `apps/app` repository composition
- `apps/features/nutrition` data/domain/Meal Diary source + focused tests
- bounded reusable Core calendar visual source/test/docs touched only for the explicitly owner-approved ring geometry/color refinement
- `docs/screens/meal-diary.md`

Still out of scope and untouched by intent: Supabase schema/RLS/migrations, Workout implementation, TNYX-207, generated/lock artifacts, unrelated features.

## 8. Next Exact Action

Run and inspect final exact-head CI. If green, perform fresh scope/thread/Codex review, reconcile Draft PR #267 + Linear TNYX-206 to review-ready truth, and stop for explicit owner merge authorization. Do not merge on `go`/`next`.
