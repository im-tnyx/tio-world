-- PR #717 P3: Note UUID identity is scoped to its authenticated owner.
-- This prevents the create RPC from revealing another user's UUID existence.
-- The public RoutineNote shape is unchanged; id remains a stable UUID per user.

alter table public.user_workout_routine_notes
  drop constraint user_workout_routine_notes_pkey;

alter table public.user_workout_routine_notes
  add constraint user_workout_routine_notes_pkey
    primary key (user_id, id);
