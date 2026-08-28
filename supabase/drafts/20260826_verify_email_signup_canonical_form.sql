-- Read-only verification for Email Signup canonical-form hook behavior.
-- Safe to run after the Phase 4 hook migration is applied.

with cases(name, event, expected_error) as (
  values
    (
      'canonical Gmail allowed',
      jsonb_build_object(
        'user', jsonb_build_object(
          'email', 'tnyx@gmail.com',
          'app_metadata', jsonb_build_object('provider', 'email')
        )
      ),
      false
    ),
    (
      'Gmail dotted alias rejected independent of owner',
      jsonb_build_object(
        'user', jsonb_build_object(
          'email', 'tn.yx@gmail.com',
          'app_metadata', jsonb_build_object('provider', 'email')
        )
      ),
      true
    ),
    (
      'Gmail plus alias rejected independent of owner',
      jsonb_build_object(
        'user', jsonb_build_object(
          'email', 'tnyx+fit@gmail.com',
          'app_metadata', jsonb_build_object('provider', 'email')
        )
      ),
      true
    ),
    (
      'Googlemail alias rejected independent of owner',
      jsonb_build_object(
        'user', jsonb_build_object(
          'email', 'tnyx@googlemail.com',
          'app_metadata', jsonb_build_object('provider', 'email')
        )
      ),
      true
    ),
    (
      'non-Gmail plus preserved and allowed',
      jsonb_build_object(
        'user', jsonb_build_object(
          'email', 'user.name+fit@example.com',
          'app_metadata', jsonb_build_object('provider', 'email')
        )
      ),
      false
    ),
    (
      'malformed Email rejected',
      jsonb_build_object(
        'user', jsonb_build_object(
          'email', 'not-an-email',
          'app_metadata', jsonb_build_object('provider', 'email')
        )
      ),
      true
    ),
    (
      'unrelated provider allowed',
      jsonb_build_object(
        'user', jsonb_build_object(
          'email', 'tn.yx@gmail.com',
          'app_metadata', jsonb_build_object('provider', 'github')
        )
      ),
      false
    )
), evaluated as (
  select
    name,
    expected_error,
    private.before_user_created_canonical_email_guard(event) as result
  from cases
)
select
  name,
  expected_error,
  result ? 'error' as actual_error,
  expected_error = (result ? 'error') as pass
from evaluated
order by name;
