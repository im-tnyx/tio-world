# Supabase migration-lineage reconciliation (tio-world)

**Status:** Awaiting review
**Scope:** Repository only. No hosted mutation of any kind.
**Hosted project:** `oykupyiitspujzpwwvuj` (tio-world)

## Owner Approval and Scope Boundary

**Approval status:** Approved, decisions frozen 2026-09-03.
**Approved boundaries:** Edit two early migration files, rename eight drifted
migration files to the versions hosted already recorded, update repository
documentation that the renames would otherwise falsify.
**Explicit non-changes:** No hosted DDL. No `supabase db push`. No
`supabase migration repair`. No ledger mutation. No production data change. No
RLS/RPC/policy change. No change to PR #202 or its branch. The TNYX-141
migration `20260902041627_add_nutrition_additional_nutrient_goals.sql` does not
exist on `main` and therefore cannot be, and was not, touched here.

## 1. Why the early files were inconsistent with hosted history

The hosted ledger holds 26 rows and begins at `20260817090811`. The repository
holds 37 migrations. Comparing them by *logical name* rather than by version
gives three distinct groups:

| Group | Count | Meaning |
|---|---|---|
| Exact version match | 18 | file and ledger agree |
| Version drift | 8 | same logical migration, different timestamp |
| No ledger row at all | 11 | the `20260814000001`-`20260816000004` range |

An earlier audit recorded only **3** drifted migrations. Re-reading both ledgers
fresh found **8**. The five previously missed are
`create_username_availability_rpc`, `harden_username_policy`,
`refine_username_impersonation_policy`, `cleanup_legacy_canonical_mirrors` and
`provision_account_root_from_auth_users`. This is not cosmetic: `supabase db
push` selects work by **version**, so before this reconciliation it would have
treated 20 migrations as pending, not 12.

### The replay hazard was silent, not loud

The natural assumption is that replaying the 11 unrecorded migrations would
fail noisily against existing objects. It would not. Every one is idempotent —
`IF NOT EXISTS`, `DROP POLICY IF EXISTS` before each `CREATE POLICY`,
`CREATE OR REPLACE FUNCTION`, guarded `DO` blocks. They would **succeed**, and
in succeeding would undo later, deliberate decisions. That is the whole reason
this reconciliation edits files rather than simply marking them applied.

## 2. Why two legacy tables are retired

`public.user_targets` and `public.user_workout_preferences` were created only by
`20260814000001_create_onboarding_owner_tables.sql`. Neither exists on hosted,
and **no migration anywhere in this repository drops them** — so their absence
is not the result of a recorded retirement, and replaying the file as written
would have *created* two dead tables in an environment that has never had them.

Their current replacements are `public.user_nutrition_targets`,
`public.user_wellness_targets` and `public.user_workout_targets`, introduced by
`20260821161923_create_canonical_owner_tables.sql`.

Per the frozen owner decision, both blocks (tables, RLS, policies and their
indexes) are removed from that migration, and its header now states that a
fresh database built from this directory must not recreate them. Nothing
replaces them.

## 3. Why the avatars bucket stays at 10 MB

`20260814000002_create_profile_storage_bucket.sql` inserted the `avatars` bucket
with `file_size_limit = 5242880` (5 MB) **and an `ON CONFLICT (id) DO UPDATE`
that re-asserts it**. Hosted has long been `10485760` (10 MB).

Because of the `DO UPDATE`, this is an overwrite rather than a no-op: replaying
the file would have downgraded a live production bucket from 10 MB to 5 MB with
no error and no warning. Both the INSERT and the ON CONFLICT path are now
`10485760`. Allowed mime types and the four ownership policies are deliberately
left untouched — fresh inspection found no defect in them.

## 4. Why `app_build` INTEGER is still a real pending migration

`20260816000004_reconcile_user_devices_app_build_type.sql` converts
`public.user_devices.app_build` from `TEXT` to `INTEGER` inside a guarded `DO`
block. Hosted inspection confirms the column is **still `text`**.

That makes this the one legacy migration whose physical effect is genuinely
absent. It is deliberately **left semantically unchanged** and is **not** to be
marked applied: doing so would permanently strand a real schema change. It must
eventually be executed. Its guard means it is safe to run more than once and a
no-op once the column is already `integer`.

## 5. The eight timestamp mappings

Repo-side rename was chosen over ledger repair because it needs **zero hosted
mutation**; repairing both sides would have meant 8 inserts plus 8 deletes
against the production ledger to reach the same 1:1 state.

| Repo (was) | Repo (now) = hosted | Logical migration |
|---|---|---|
| 20260817000001 | **20260817090811** | create_username_availability_rpc |
| 20260817000002 | **20260817100424** | harden_username_policy |
| 20260817000003 | **20260817101532** | refine_username_impersonation_policy |
| 20260824070300 | **20260824070233** | cleanup_legacy_canonical_mirrors |
| 20260824180400 | **20260824180611** | provision_account_root_from_auth_users |
| 20260826072000 | **20260826075218** | refine_username_suggestions |
| 20260830055341 | **20260830074411** | set_active_body_goal_rpc |
| 20260831064500 | **20260831064841** | add_nutrition_other_free_text |

Only `20260824070233` moves *earlier* than its old repo version; the ordering of
the directory is still strictly ascending, and no target version collided with
an existing file.

### Bodies were verified, not assumed

`supabase_migrations.schema_migrations` stores the applied SQL in a `statements`
column, so each renamed file was compared against **what hosted actually ran**.

A first comparison reported 6 of 8 as differing. That was a fault in the
comparison, not in the files: the hosted-side expression produced no leading
whitespace while the local side did, and the hosted `statements` array has the
leading `--` header comments already stripped. Under a normalization that
strips comment-only lines, folds whitespace and ignores spacing around `( ) , ;`
— the last of which matters because hosted stores
`reason( p_username text, p_user_id uuid )` where the repo has
`reason(p_username text, p_user_id uuid)` — **all eight match exactly**.

The eight bodies are therefore semantically identical to what production ran,
and the hashes were re-verified after the header comment inside
`20260817090811` was corrected. No SQL body was altered by this pass.

## 6. Lineage note

The sibling Supabase project `tnyx-hub` (`hmxylzecbsleovcmbdhm`) is a **separate
project** and was not inspected for mutation or modified in any way. Several of
the 11 unrecorded migrations carry names from that lineage (for example
`create_tnyxhub_canonical_tables`, `create_user_devices_table`,
`add_plan_to_users_table`), which is the most likely explanation for why the
tio-world ledger simply begins after them.

## 7. Result

- Repository migrations: 37, strictly ascending, **0 duplicate versions**.
- The newest 26 now map **1:1** onto the 26 hosted ledger rows.
- Exactly the 11 known-unrecorded legacy migrations remain unmatched, which is
  the expected and intended end state of a repo-only pass.

## 8. Hosted Supabase was NOT mutated

No DDL, no `db push`, no `migration repair`, no ledger write, no data change, no
RLS or RPC change. Hosted reads during this work were `SELECT`-only.

## 9. Next step requires explicit owner authorization

This branch makes the *repository* honest. It does not make hosted consistent.
Still outstanding, and all owner-gated:

1. Decide the disposition of the 11 unrecorded migrations — 8 are verified
   physically present and are repair-as-applied candidates; `20260814000001` and
   `20260814000002` are now safe to repair **because** this pass corrected them;
   `20260816000004` must be **executed**, not marked.
2. Repair the ledger.
3. Apply the TNYX-141 migration (PR #202), which remains Draft and unchanged.

No hosted step is authorized by this task.
