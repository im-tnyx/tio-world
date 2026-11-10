-- Pin name resolution for the trigger helper without replacing its body or
-- changing its owner, invoker mode, ACL, signature, or trigger binding.
alter function public.trg_fn_validate_workout_session_snapshot()
  set search_path = '';
