// The same two client-safe names and validation rules as
// .github/scripts/mobile_qa_runtime_config.py. No passwords or secret keys.
const fs = require('node:fs');
const path = require('node:path');

function validateQaConfig(config) {
  if (!config || Array.isArray(config) || typeof config !== 'object') throw new Error('Invalid QA JSON.');
  const keys = Object.keys(config).sort();
  if (keys.join('|') !== 'SUPABASE_PUBLISHABLE_KEY|SUPABASE_URL') throw new Error('QA JSON must contain only the two client-safe Supabase fields.');
  if (typeof config.SUPABASE_URL !== 'string' || typeof config.SUPABASE_PUBLISHABLE_KEY !== 'string') {
    throw new Error('QA URL and publishable key must be strings.');
  }
  let url;
  try { url = new URL(config.SUPABASE_URL.trim()); } catch (_) { throw new Error('QA Supabase URL is invalid.'); }
  const canonicalHost = /^[a-z0-9][a-z0-9-]*\.supabase\.co$/i.test(url.hostname);
  if (url.protocol !== 'https:' || !canonicalHost || url.port || url.username || url.password ||
      url.pathname !== '/' || url.search || url.hash ||
      url.href !== config.SUPABASE_URL.trim().replace(/\/$/, '') + '/') {
    throw new Error('QA URL must be a canonical HTTPS Supabase project endpoint.');
  }
  if (!/^sb_publishable_[A-Za-z0-9_-]+$/.test(config.SUPABASE_PUBLISHABLE_KEY.trim())) {
    throw new Error('Only sb_publishable_ client keys are allowed.');
  }
  return true;
}

function validateQaFile(file) {
  if (!file || typeof file !== 'string') throw new Error('QA config file path required.');
  const absolute = path.resolve(file);
  const config = JSON.parse(fs.readFileSync(absolute, 'utf8'));
  validateQaConfig(config);
  return true;
}

if (require.main === module) {
  try { validateQaFile(process.argv[2]); console.log('QA client-safe config format valid (values redacted).'); }
  catch (error) { console.error('QA configuration rejected: ' + error.message); process.exitCode = 1; }
}
module.exports = { validateQaConfig, validateQaFile };
