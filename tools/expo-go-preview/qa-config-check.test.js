const test = require('node:test');
const assert = require('node:assert/strict');
const { validateQaConfig } = require('./qa-config-check');
const example = { SUPABASE_URL: 'https://tio-qa-example.supabase.co', SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_testing123' };

test('accepts minimal client-safe QA config', () => assert.equal(validateQaConfig(example), true));
for (const invalid of [
  {}, { ...example, EXTRA: 'not-allowed' },
  { ...example, SUPABASE_URL: 'http://tio-qa-example.supabase.co' },
  { ...example, SUPABASE_URL: 'https://other.example.com' },
  { ...example, SUPABASE_URL: 'https://tio-qa-example.supabase.co/other' },
  { ...example, SUPABASE_URL: 'https://tio-qa-example.supabase.co:9999' },
  { ...example, SUPABASE_PUBLISHABLE_KEY: 'sb_secret_not_allowed' },
  { ...example, SUPABASE_PUBLISHABLE_KEY: 'service_role_invalid' },
  { ...example, SUPABASE_PUBLISHABLE_KEY: '' }
]) {
  test('rejects non-QA or elevated input ' + JSON.stringify(Object.keys(invalid)), () => {
    assert.throws(() => validateQaConfig(invalid));
  });
}
