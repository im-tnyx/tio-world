# Task Files

Task files are compact, durable briefs for work that is active, blocked on one decision, or ready to hand off. They are not a backlog dump or a replacement for GitHub Issues when external tracking is needed.

## Current Tasks

Validated pre-P9 #563/#582 handoffs are in the [archive](../archive/README.md); current source and live GitHub/Linear trackers govern remaining #250 acceptance and any P9 decision.

Completed #569 B3e UNKNOWN Move feedback regression is [archived](../archive/2026-10-issue-569-m3d3b3e-unknown-ui-lifecycle-regression.md) after merged [PR #616](https://github.com/im-tnyx/tio-world/pull/616) and verified 5/5 post-merge CI. Parent [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569) remains open and Linear TNYX-81 remains Backlog; production Move release is OFF.

| Task | Status | Primary owner | Read before |
|---|---|---|---|
| [iOS free physical-device UI testing foundation](ios-free-device-ui-testing.md) | Review gate — owner approves merge before physical testing; manual QA-login build, Windows signing and iPhone smoke are unverified post-merge acceptance | Flutter phone platform / repository CI | Manual-only workflow, client-safe QA Secrets, post-merge iPhone acceptance; no automatic builds or production release scope |
| [#569 — Routine Move M1 existing-owned Program RPC](issue-569-routine-move-existing-program-db.md) | **Merged PR #588, hosted M1 deployed** (verified 64/64 applied on 2026-10-17); Move RPC exists but authenticated EXECUTE remains revoked | Supabase/Postgres | Stable Routine/child IDs, owner/revision CAS; Flutter adapter/UI and separate EXECUTE grant remain gated |
| [#569 — Routine Move M2 Legacy Rename Compatibility](issue-569-m2-legacy-rename-compatibility.md) | **Merged PR #591** (squash `main@c12ea127`), post-merge [Flutter CI #39038295713](https://github.com/im-tnyx/tio-world/actions/runs/39038295713) **SUCCESS** (5/5), 4/4 inline threads resolved; owner-directed manual review was documented (no independent GitHub `APPROVED`). **M2C old-client cutoff is completed in hosted Supabase (64/64 migrations); Move client EXECUTE and UI activation remain NO-GO** | Workout metadata repository/controller + app Auth; later Supabase | Current-client protected Rename code merged, not app-store released. Hosted M1 Move RPC and M2C direct-Rename grant retirement are applied; Move EXECUTE remains revoked, so integration, review and release/activation are separately gated |
| [#569 — M2C Legacy Rename retirement preflight](issue-569-m2c-legacy-rename-retirement-preflight.md) | **Merged PR #593** (`main@1188346d`); temporary preflight succeeded before permanent cutoff branch | Supabase/Postgres tests and CI | Historical CI-only preflight, not a hosted deployment; see cutoff task below |
| [#569 — M2C permanent Rename cutoff](issue-569-m2c-legacy-rename-cutoff.md) | **Merged PR #594 and hosted cutoff deployed**; verified 64/64 SQL migrations, direct `authenticated UPDATE(name)` denied and protected Update RPC executable | Supabase/Postgres + CI | Legacy direct Rename retired; Move EXECUTE still revoked, no UI activation |
| [#569 — M3A Move existing-owned Program adapter](issue-569-m3-existing-program-move-adapter.md) | **Merged PR #595**, squash main@59a21ba3, post-merge Flutter CI #39055475888 SUCCESS 5/5; Move grant still revoked | Workout domain/data | Owner/session-bound one-use RPC adapter, no UI activation |
| [#569 — M3B1 existing-Program Move destination controller](issue-569-m3b-existing-program-move-flow.md) | **Merged PR #597** squash `main@f58fbc34` (2026-10-17 UTC); exact PR-head CI #39059188853 SUCCESS 7/7 and post-merge [CI #39060837742](https://github.com/im-tnyx/tio-world/actions/runs/39060837742) SUCCESS 5/5; both P2 threads resolved | Workout presentation (merged) | Owner/list and one-use confirmed dispatch, post-confirmation destination revalidation/cancel race guarded. Client Move EXECUTE and app-shell activation remain OFF |
| [#569 — M3B1 existing-owned Program Move selector/confirmation](issue-569-m3b1-existing-program-move-flow.md) | **PR #598 review gate verified** against protected `main@f58fbc34` (current open/merged status: GitHub PR source); exact source+test `63917766` [CI #39062399593](https://github.com/im-tnyx/tio-world/actions/runs/39062399593) **7/7 PASS** (Workout 737 tests, 10 Move widgets), follow-on handoff HEAD `dbb9bbc3` [CI #39062866583](https://github.com/im-tnyx/tio-world/actions/runs/39062866583) **7/7 PASS**; reconciliation 0 behind, five owned files. Any subsequent handoff-only SHA requires its own CI | Workout presentation UI | Dormant existing-Program selector/confirmation consumes merged controller #597; P2 corrected and handoff drift documented. `+ New Program`/atomic Create & Move P3, #568 identity, app-shell Auth/operation coordination and client Move grant strictly block activation |
| [#569 — M3B2B1 dormant New Program Move UI](issue-569-m3b2b-dormant-new-program-selector.md) | **Merged PR #600** squash `main@55ef926e` (2026-10-18 UTC), exact PR-head Flutter CI #39105354552 **7/7 PASS**; post-merge Flutter checks separate | Workout presentation (merged) | Canonical Create Program name editor + optional New Program selector, edited-name/final-cancel tests; still no apps/app Move callback, hosted grant, deployment or activation |
| [#569 — M3D2B1 dormant app-shell Move integration](issue-569-m3d2b1-dormant-shell-move.md) | **Merged PR #604**, protected `main@d3753bcd`; [post-merge Flutter CI #39141831465](https://github.com/im-tnyx/tio-world/actions/runs/39141831465) **SUCCESS**, exact PR-head 7/7 PASS; 1 review coverage note deferred to M3D3 and dispositioned | apps/app shell (merged) | Auth-guarded common existing/atomic MoveFlow; release provider OFF, no hosted RPC/client grant or UI activation |
| [#569 — M3D3A real app-shell Move OFF regression](issue-569-m3d3a-move-release-off-route-tests.md) | **Merged [PR #605](https://github.com/im-tnyx/tio-world/pull/605)**, protected `main@bd55f80e` (2026-10-18 UTC). Exact pre-merge HEAD `c9100cea` Flutter 5/5 and attribution 2/2 PASS; Codex 2/2 P1 docs findings resolved; post-merge main checks were still in progress at task-start audit | apps/app widget tests (merged) | Authenticated real Program Detail + expanded Library action sheets prove Move remains hidden while production release provider OFF |
| [#569 — M3D3B1 enabled-test Move Auth-cycle revocation](issue-569-m3d3b1-move-auth-revocation.md) | **Merged [PR #606](https://github.com/im-tnyx/tio-world/pull/606)**, protected `main@e08d547b` 2026-10-18 UTC. Exact PR-head `ce84bf58` [Flutter CI #39147910659](https://github.com/im-tnyx/tio-world/actions/runs/39147910659) **5/5 PASS** + attribution **2/2 PASS**, Codex no findings, 0 threads; separate independent APPROVED review absent, owner explicitly directed merge. Post-merge CI was in progress at M3D3C task start | apps/app widget tests (merged) | Test-only enabled Move selector auth-cycle dismissal on both surfaces; production release OFF |
| [#569 — M3D3C debug-only Move Routine UI preview](issue-569-m3d3c-debug-move-ui-preview.md) | **Merged [PR #607](https://github.com/im-tnyx/tio-world/pull/607)**, protected `main@a69bc824`, post-merge [Flutter CI #39156079698](https://github.com/im-tnyx/tio-world/actions/runs/39156079698) **5/5 PASS**; exact PR-head Flutter 5/5 and attribution 2/2 PASS, Codex no findings, owner phone UI PASS | Workout feature presentation + app shell/tests (merged) | Debug opt-in owner-scoped Move selector, `New Program`/divider/confirmation, 42dp local buttons, five-second floating preview Undo (dismiss only). Zero writes; release OFF; no hosted grants; owner device UI PASS verified separately (no new agent build) |
| [#569 — M3D3B2a Move/Delete cross-operation arbitration](issue-569-m3d3b2a-move-delete-arbitration.md) | **Merged [PR #609](https://github.com/im-tnyx/tio-world/pull/609)**, protected `main@7801502a`, exact PR-head Flutter 5/5 + attribution 2/2 PASS, Codex no findings; [post-merge Flutter CI #39202873606](https://github.com/im-tnyx/tio-world/actions/runs/39202873606) **SUCCESS 5/5** | Workout data adapters + app composition/tests (merged) | Shared same-Routine owner-keyed Move↔Delete in-flight, stale token and UNKNOWN guard; production Move OFF and grants revoked |
| [#569 — M3D3B2b1 Edit versus Move/Delete arbitration](issue-569-m3d3b2b1-edit-move-arbitration.md) | **Merged [PR #610](https://github.com/im-tnyx/tio-world/pull/610)**, protected `main@d758f665`, [post-merge Flutter CI #39207704722](https://github.com/im-tnyx/tio-world/actions/runs/39207704722) SUCCESS 5/5; exact PR-head Flutter 5/5 and attribution 2/2 PASS; Codex P2 superseded CAS fix tested and thread resolved | Workout data adapters + app providers/tests | Same owner/Routine shared guard across composition Save, atomic Name+Sets Edit and metadata Rename; production Move OFF |
| [#569 — M3D3B2b2 pending Create Program vs Move preflight](issue-569-m3d3b2b2-pending-create-move-preflight.md) | **Merged [PR #611](https://github.com/im-tnyx/tio-world/pull/611)** protected `main@948ad092`, [post-merge Flutter CI #39214261385](https://github.com/im-tnyx/tio-world/actions/runs/39214261385) **SUCCESS 5/5**; reviewed PR HEAD `05357447` Flutter 5/5 + attribution 2/2 PASS; Codex P2 fix `3b5d3fb8` + 4 tests `e86e55df`, thread resolved | Workout Move data adapter, Create pending gate, app provider and tests | Owner+Program pending Create blocks both Move RPC dispatches; same-Routine UNKNOWN/stale priority preserved; production Move OFF |
| [#569 — M3D3B3a owner-cycle Move refresh fan-out](issue-569-m3d3b3a-owner-move-refresh-fanout.md) | **Merged [PR #612](https://github.com/im-tnyx/tio-world/pull/612)**, protected `main@4b9404f4`; post-merge [Flutter CI #39222970364](https://github.com/im-tnyx/tio-world/actions/runs/39222970364) SUCCESS 5/5. Exact PR-head CI/attribution PASS, Codex P2 collapsed-Program regression fixed and thread resolved; no formal independent APPROVED | Workout feature-owned list invalidation + app shell (merged) | Move refreshes both expanded Program Routine lists, atomic Create+Move rereads persisted Programs; UNKNOWN remains unconfirmed, Move release OFF |
| [#569 — M3D3B3b owner-safe UNKNOWN Move mutation verification](issue-569-m3d3b3b-unknown-mutation-verification.md) | **Merged [PR #613](https://github.com/im-tnyx/tio-world/pull/613)** into protected `main@a892e2db`; [post-merge Flutter CI #39229765962](https://github.com/im-tnyx/tio-world/actions/runs/39229765962) **SUCCESS 5/5**, prior exact-HEAD Flutter/attribution PASS, both P3 handoff threads resolved; Codex review quota-blocked, not falsely claimed PASS | Workout domain/data + focused tests (merged) | Original UNKNOWN mutation UUID/revision/destination readback; does not auto-retry or turn generic list refresh into success; production release OFF |
| [#569 — M3D3B3c UNKNOWN Move feedback reconciliation](issue-569-m3d3b3c-unknown-feedback-reconciliation.md) | **Merged [PR #614](https://github.com/im-tnyx/tio-world/pull/614)** to protected `main@428e2c65`; [post-merge Flutter CI #39238953843](https://github.com/im-tnyx/tio-world/actions/runs/39238953843) **SUCCESS 5/5**; exact PR-head Flutter/attribution PASS and Codex code review completed with no findings, 0 inline threads; no independent APPROVED claim | Workout domain/data/presentation + tests (merged) | Existing and atomic UNKNOWN verification requires the originating command UUID plus owner-cycle/revision/destination receipt; false success from a prior UNKNOWN prevented; preview and release OFF |
| [#569 — M3D3B3d cross-path UNKNOWN receipt regression](issue-569-m3d3b3d-cross-path-receipt-regression.md) | **Merged [PR #615](https://github.com/im-tnyx/tio-world/pull/615)**, protected `main@173b5d97`; [post-merge Flutter CI #39242585331](https://github.com/im-tnyx/tio-world/actions/runs/39242585331) **SUCCESS 5/5**, exact-head CI/attribution PASS, Codex code-review 0 findings, 0 inline threads; author manual COMMENT not formal independent APPROVED | Workout repository regression tests (merged) | Atomic UNKNOWN→existing and existing UNKNOWN→atomic second pre-dispatch rejected; different mutation UUID cannot adopt an earlier server receipt; zero production source change |
| [#569 — M3D2A dormant Move callback plumbing](issue-569-m3d2a-dormant-move-callbacks.md) | **Merged PR #603**, protected `main@11d5324f`, [post-merge Flutter CI #39138469849](https://github.com/im-tnyx/tio-world/actions/runs/39138469849) **5/5 PASS**, exact PR-head 7/7 PASS, 2/2 inline threads resolved | Workout feature presentation | Nullable Move on Program Detail/Library; source list refresh request only, no app-shell activation |
| [#569 — M3D1 dormant authenticated Move providers](issue-569-m3d1-move-app-providers.md) | **Merged PR #602**, protected `main@bbe255c0`, post-merge [Flutter CI #39132061631](https://github.com/im-tnyx/tio-world/actions/runs/39132061631) SUCCESS 5/5 | apps/app composition | Shared owner/login-cycle-pinned Move gate and existing/atomic adapter aliases; no onMove app-shell hookup |
| [#569 — M3C dormant atomic Create Program + Move Flutter adapter](issue-569-m3c-atomic-create-move-flutter-adapter.md) | **Merged PR #601**, squash `main@b53c3303`, exact-head CI 7/7 PASS, post-merge [Flutter CI #39124293736](https://github.com/im-tnyx/tio-world/actions/runs/39124293736) SUCCESS 5/5 | Workout domain/data | Shared protected existing/atomic Move adapter; hosted atomic RPC and EXECUTE grants still gated |
| [#569 — M3B2 atomic New Program + Move server contract](issue-569-m3b2-atomic-create-program-and-move-db.md) | **Source merged [PR #599](https://github.com/im-tnyx/tio-world/pull/599)** on 2026-10-18 as `main@2c5a2638`, reviewed source `165c19e6` [DB CI #39098735021](https://github.com/im-tnyx/tio-world/actions/runs/39098735021) SUCCESS, final PR HEAD `6deb44f8` [DB CI #39099130126](https://github.com/im-tnyx/tio-world/actions/runs/39099130126) and [attribution #39099128104](https://github.com/im-tnyx/tio-world/actions/runs/39099128104) SUCCESS, Codex source review zero findings, all 4 threads resolved. **Dormant hosted rollout APPLIED (2026-10-19):** owner Windows Supabase CLI applied only `20261018100000`; independently verified live **65/65 migrations** and atomic RPC `SECURITY DEFINER` with empty `search_path`, `PUBLIC/anon/authenticated/service_role EXECUTE=false`; existing Move RPC remains equally denied, RLS on Program/Routine tables preserved. **Client grants / UI activation / real Undo / production release remain separately gated**; SQL deployment does not activate Move | Supabase/Postgres source merged + dormant hosted SQL deployed; application activation not authorized | Protected atomic Program INSERT + Routine CAS Move **function exists on hosted**, but no client role can EXECUTE it; no live Move writes or end-user activation verified. W1/W3/#568, Auth/unknown/race QA and owner activation gates remain; [canonical Supabase strategy](../../docs/data/SUPABASE_STRATEGY.md) and [Routine screen contract](../../docs/screens/routine-library.md) contain older status snapshots; reconciliation owned by [Pre-P9 Supabase strategy task](pre-p9-supabase-strategy-current-status.md) and Workout screen docs/#569 respectively. DO NOT GRANT EXECUTE OR ENABLE production Move from this docs reconciliation |
| [Pre-P9 — Supabase strategy current-status reconciliation](pre-p9-supabase-strategy-current-status.md) | In progress — read-only 62/62 live migration + merged Workout source audit; docs-only PR review/merge pending | Supabase data docs + repository governance | Update only stale migration/Flutter status assertions; preserve platform architecture, protected-service boundary and deferred Workout features |
| [Pre-P9 — Supabase public schema inventory reconciliation](pre-p9-supabase-schema-inventory.md) | In progress — 62/62 repo-to-live migration metadata and public catalog verified; docs-only PR review/merge gated | Supabase data docs + repository governance | 2026-10-17 19 public tables, 190 columns, 129 constraints; six new CHECKs (one NOT VALID), four Routine RPCs. GitHub #250 acceptance and P9 separately gated |
| [#526 — Flutter Routine Delete adapter, Slice A](issue-526-routine-delete-flutter-adapter.md) | Merged PR #586 (`main@965b5873`); Delete UI still separate | Workout repository/data | Owner/login-cycle/revision CAS RPC adapter with mandatory shared in-process attempt gate; no UI/DB changes |
| [#526 — Flutter Routine Delete, Slice B](issue-526-routine-delete-slice-b.md) | Merge gate — owner UI PASS; implementation CI #39016018752 5/5 PASS; final handoff HEAD CI and explicit merge authorization pending | Workout feature + app composition | Program/Library Delete, centered 320dp Core card, owner/cycle-safe 3-dot sheet and confirmation; 6 review threads resolved, no Supabase changes |
| [#526/#564/#569 — Routine actions bottom sheet](issue-526-routine-actions-bottom-sheet.md) | Merged PR #581; Edit wired, Move/Delete separate secure slices | Workout feature presentation | Replace Routine anchored popup with Core sheet, capability-gated three-action target; no fake options or DB changes |
| [GitHub #571 — Parallel Flutter CI](issue-571-parallel-flutter-ci.md) | Merged PR #573 (`main@42af17a6`); remaining performance follow-up is separately gated | Repository CI / GitHub Actions | 3 independent Flutter test shards, fail-closed package inventory, unchanged trusted guard and stable Analyze and test aggregate |
| [#538 — Set Type sheet color parity](issue-538-set-type-sheet-color-parity.md) | In review — Draft PR #574; compact Core outlined-card / red trash icon refinement pending exact-head CI, independent review and owner device QA | Workout presentation | Single semantic Set badge in row + both sheets; no schema/persistence impact |
| [GitHub #564 — Routine composer/Detail UI parity](issue-564-routine-ui-parity.md) | UI-only sub-slice merged PR #570 (`main@7f05def9`); atomic Name+composition Update and 3-dot full Edit separately gated | Workout feature presentation | Top Save/Update parity; Detail Exercises-row Edit including ready-empty; focused tests, review and CI |
| [GitHub #564 — Flutter Routine Name Edit/Update](issue-564-edit-routine-name-atomic-flutter.md) | Draft PR #577 — name+composition RPC deployed via #576; Flutter editor and 3-dot direct Edit integrating, CI/review pending; Delete #526 separate | Workout + app shell | Owner-scoped name prefill, one atomic Update, unknown-result read verification, existing popup preserved |
| [GitHub #529 — Program empty-state and overflow Add Routine](issue-529-program-add-routine.md) | Merged in PR #566 (`main@5aec6ef1`); owner device QA not independently checked; Program Delete remains separate #567 | Workout Library + app Create route | Selected Program canonical Create; Tio bottom sheet keeps Edit Program/Rename and adds Add Routine; no unsafe Delete |
| [W4 Flutter consolidated integration / single PR gate](workout-routine-w4-integration.md) | Historical handoff — consolidated PR #551 merged; broader W4/TNYX-81 acceptance and rollout remain separately gated | Workout UI + app auth + shared model + Core variants | Use live `main` and current trackers; do not treat former stacked Draft PR descriptions as active work |
| [Routine Set boxed Create/Edit fields + compact Add Set](routine-set-boxed-inputs-compact-add-set.md) | In progress — owner-approved visual child of Draft #549; outlined numeric cells and governed compact Add Set | Workout presentation | Validate at exact head; inherited parent review/CI blockers remain |
| [Routine Set typing limits](routine-set-typing-limits.md) | In progress — new child of Draft #546; workout Reps/Range/Weight/Rest input formatters | Workout feature presentation | Restrict excessive typing without schema or visual geometry changes |
| [Routine Detail / Edit reference Set tables](routine-detail-edit-reference-set-tables.md) | In progress — approved read-only Detail table + Edit inline grid child of Draft #544 | Workout feature | Align SET/KG/REPS and Edit PREVIOUS/inline fields without fabricated history |
| [Create Routine header drag/menu + blank Reps](create-routine-exercise-controls-blank-reps.md) | In progress — owner-approved Create-only UI refinements, child of Draft #541 | Workout Create UI | Long-press Exercise reorder, overflow removal, initial blank Reps + Save gating |
| [#538/#539 — Flutter Routine Set metadata UI](issues-538-539-routine-set-client.md) | In progress — approved client model/read/write + type/range selectors, stacked on Draft #537; DB Draft #540 not deployed | Shared + Workout feature | Set type/Rep Range canonical model, sheet, read/write, tests |
| [GitHub #535 — Create Routine UI + default Set 1](issue-535-create-routine-ui.md) | In progress — approved, stacked on Draft #533; depends on Draft #536 atomic Create RPC, not deployed; no device QA | Workout feature + app composition | Reference-inspired full Create UI; auto Set 1; Save requires an Exercise |
| [GitHub #532 — W4B1 Routine Editor](issue-532-w4b1-routine-editor.md) | In progress — source CI #38373650044 green, all 6 Codex P2 threads author-resolved; exact-head independent review blocked by Codex usage limit, physical QA pending, #534 server race separate; Draft/unmerged | Workout feature + app composition | Two-screen Detail → Editor; fixed-reps/weight/rest, no schema |
| [#538/#539 — Routine Set type + Rep Range DB](issues-538-539-routine-set-metadata-db.md) | In progress — two additive approved columns, separate DB-only source/test PR; no production deploy | Supabase migration/RPC | Enriched Set payload compatibility, legacy overwrite prevention, SQL matrix |

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
| [GitHub #24 Phase #24-B — Nutrition numeric input migration](issue-24b-nutrition-numeric-input-migration.md) | Validated | `apps/core` input contract + Nutrition presentation | Runtime/review validated; PR #195 remains open for final exact-head CI and merge gates |
| [TNYX-257 — Meal Diary positive-only calendar progress ring](tnyx-257-meal-diary-positive-progress-ring.md) | In progress | `apps/features/nutrition` | GitHub #317; hide progress decoration for `progress <= 0`, preserve Core null-vs-zero semantics |
| [Product Onboarding card variant cleanup](onboarding-card-variant-cleanup.md) | Validated | `apps/features/onboarding` presentation | Removed unreachable placeholder and validated approved Health/Sleep elevated card variants |
| [App Mode foundation](app-mode-foundation.md) | Historical/validated implementation detail | `apps/shared`, `apps/app`, onboarding, Settings, `user_app_preferences` | O1 App Mode is complete (#11 / TNYX-6); preserve implementation evidence, but use source/canonical docs/live trackers for current work |
| [Product Onboarding Slice 1 — identities](product-onboarding-slice-1-identities.md) | Validated | `apps/features/onboarding` | Stable future section/step identity + draft codec foundation validated by CI #945 |
| [Product Onboarding Slice 2B — Target Weight + Goal Pace](product-onboarding-slice-2b-target-weight-goal-pace.md) | In progress | `apps/features/onboarding` | O1–O11 onboarding lane is complete/frozen; this brief remains only for its independently tracked picker/recommendation follow-ups |
| [Canonical Supabase Owner Migration](canonical-supabase-owner-migration.md) | In progress | Supabase + domain repositories | Body foundation + P1 `user_profiles`/`user_app_preferences`/`email_verified_at` are live |
| [Account / Profile / App Preferences Canonical Split](account-profile-app-preferences-canonical-split.md) | In progress | Supabase + Account/Profile/App Mode composition | P1 schema and Product Onboarding O1–O11 are complete; retain only independently open post-onboarding Account/Settings/runtime follow-ups |
| [Profile & Account Data Persistence](profile-account-data-persistence.md) | In progress | `users` account root + Profile/Settings/Auth adapter | Independent A1: real email/mobile add/change/verify; required for account/settings acceptance but not an O1 onboarding blocker |
| [Canonical Body Owner Repository Cutover](canonical-body-owner-repository-cutover.md) | In progress | `apps/features/progress` + onboarding/Profile/Settings composition | Body A + B1 validated (#1135/#1153); final Profile/Settings mirror shutdown follows canonical Profile cutover |
| [Adaptive navigation and action entry](adaptive-navigation-and-actions.md) | Ready | `apps/shared`, `apps/core`, `apps/app`, Settings, affected features | Designing custom tabs, Home composition, or feature action placement |
| [Material 3 Expressive foundation](material-3-expressive.md) | In progress | `apps/core`, `apps/app` | Changing shared theme, navigation, buttons, motion, or accessibility behavior |
| [Screen catalog and module plan](screen-catalog-and-module-plan.md) | Ready | `apps/app`, `apps/core`, `apps/shared`, affected features | Starting a screen or module vertical slice |

## Product Onboarding execution state

The historical O1–O11 delivery sequence is **COMPLETE / FROZEN** in GitHub #40. O1 App Mode is complete in GitHub #11 / Linear TNYX-6. The former canonical execution brief is archived as Superseded/Historical and is not current sequencing authority.

For any new onboarding slice, reconcile current source/runtime, canonical onboarding docs, and live GitHub/Linear trackers. Do not infer a next onboarding step from the historical O1–O11 order.

Independent post-onboarding Account/Settings/runtime work may continue under its own live trackers; GitHub #44 remains the broader canonical-ownership umbrella.

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

- **Planning owner:** shapes scope, decisions, and the implementation approach. This role may update task records for scope, evidence, decisions, or handoff state, but must not modify implementation/source files unless it also becomes the recorded Implementation owner.
- **Implementation owner:** the only active role permitted to modify implementation/source files for the current task slice.
- **Review owner:** inspects the implementation and may update task/review records with findings, evidence, or review status. This role must receive Implementation ownership before modifying implementation/source files to resolve a finding.

At most one active `Implementation owner` may own a task slice at a time. Other agents may inspect, reason, review, identify risks, propose or record findings, and update task/review governance records without modifying implementation/source files for that slice. Changing the Implementation owner is execution coordination, not product approval, and does not trigger the Owner Approval Gate when the same approved scope continues.

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
