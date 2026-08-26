-- Focused verification for private.canonical_email_identity(text).
-- Run after the migration on a disposable/dev database. No persistent data is
-- written by this script.

do $verification$
declare
  actual text;
begin
  actual := private.canonical_email_identity(' Na.Me+Fit@googlemail.com ');
  if actual is distinct from 'name@gmail.com' then
    raise exception 'googlemail alias mismatch: %', actual;
  end if;

  actual := private.canonical_email_identity('N.A.M.E+anything@GMAIL.COM');
  if actual is distinct from 'name@gmail.com' then
    raise exception 'gmail dot/plus alias mismatch: %', actual;
  end if;

  actual := private.canonical_email_identity('plain.user@gmail.com');
  if actual is distinct from 'plainuser@gmail.com' then
    raise exception 'gmail dot mismatch: %', actual;
  end if;

  actual := private.canonical_email_identity(' User+Fit@Example.com ');
  if actual is distinct from 'user+fit@example.com' then
    raise exception 'non-gmail plus tag was rewritten: %', actual;
  end if;

  actual := private.canonical_email_identity('First.Last@Example.com');
  if actual is distinct from 'first.last@example.com' then
    raise exception 'non-gmail dot was rewritten: %', actual;
  end if;

  actual := private.canonical_email_identity('');
  if actual is not null then
    raise exception 'blank input must return null: %', actual;
  end if;

  actual := private.canonical_email_identity('missing-at.example.com');
  if actual is not null then
    raise exception 'missing @ must return null: %', actual;
  end if;

  actual := private.canonical_email_identity('a@@example.com');
  if actual is not null then
    raise exception 'multiple @ must return null: %', actual;
  end if;

  actual := private.canonical_email_identity('@example.com');
  if actual is not null then
    raise exception 'missing local part must return null: %', actual;
  end if;

  actual := private.canonical_email_identity('user@');
  if actual is not null then
    raise exception 'missing domain must return null: %', actual;
  end if;

  actual := private.canonical_email_identity('user @example.com');
  if actual is not null then
    raise exception 'embedded whitespace must return null: %', actual;
  end if;

  actual := private.canonical_email_identity('+tag@gmail.com');
  if actual is not null then
    raise exception 'empty canonical gmail local part must return null: %', actual;
  end if;
end;
$verification$;
