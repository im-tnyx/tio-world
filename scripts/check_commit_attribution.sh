#!/usr/bin/env bash
# Detect prohibited AI Co-Authored-By trailers in a commit range.
#
# Usage:
#   check_commit_attribution.sh <base-sha> <head-sha>
#   check_commit_attribution.sh <base-sha> <head-sha> <pr-number> <exception-pr>
#
# Inspects every commit in base..head, parses each commit message's
# trailers with `git interpret-trailers`, and rejects any Co-Authored-By
# trailer that identifies a known AI provider (by trailer email domain or
# by an exact known AI display name). Ordinary human co-authors, including
# a human whose first name happens to be "Claude", are left untouched.
#
# The optional 4-argument form carries the owner-approved exception
# decision inside this tested script rather than in untested workflow
# YAML: a detected violation is only forgiven when <pr-number> and
# <exception-pr> are both non-empty and equal. The exception can NEVER
# turn a technical/invocation failure (exit 2) into success -- ref
# validation and detection always run first, and the exception is only
# ever consulted after a genuine attribution violation (exit-1 case) has
# already been found.
#
# Exit 0: no prohibited AI attribution found, OR a violation was found but
#         explicitly exempted for the exact matching PR number.
# Exit 1: prohibited AI attribution found and no matching exception applies.
# Exit 2: usage/invocation error -- invalid argument count, invalid base/head
#         ref, or a technical failure while parsing a commit's trailers.
#         Never bypassed by the exception, by design.

set -euo pipefail

print_usage() {
  echo "Usage: $0 <base-sha> <head-sha> [<pr-number> <exception-pr>]" >&2
}

if [ "$#" -eq 2 ]; then
  base_sha="$1"
  head_sha="$2"
  pr_number=""
  exception_pr=""
elif [ "$#" -eq 4 ]; then
  base_sha="$1"
  head_sha="$2"
  pr_number="$3"
  exception_pr="$4"
else
  print_usage
  exit 2
fi

for sha in "$base_sha" "$head_sha"; do
  if ! git cat-file -e "${sha}^{commit}" 2>/dev/null; then
    echo "check_commit_attribution: error: '${sha}' is not a valid commit in this repository." >&2
    exit 2
  fi
done

# Known AI provider email domains (checked as an exact domain or subdomain match).
ai_domains=(
  "anthropic.com"
  "openai.com"
)

# Known AI display identities (checked as an exact, case-insensitive match on
# the trailer's name field). Deliberately does NOT include a bare "claude" or
# "codex" first-name match, so a real human co-author is never rejected only
# because their name resembles a provider name.
ai_names=(
  "anthropic"
  "codex"
  "openai"
  "openai codex"
  "claude code"
  "claude sonnet"
  "claude opus"
  "claude haiku"
)

to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

is_ai_domain() {
  local domain_lc="$1" d
  for d in "${ai_domains[@]}"; do
    if [ "$domain_lc" = "$d" ] || [[ "$domain_lc" == *".$d" ]]; then
      return 0
    fi
  done
  return 1
}

is_ai_name() {
  local name_lc="$1" n
  for n in "${ai_names[@]}"; do
    if [ "$name_lc" = "$n" ]; then
      return 0
    fi
  done
  return 1
}

commit_list="$(git rev-list --reverse "${base_sha}..${head_sha}")"

found_violation=0

if [ -n "$commit_list" ]; then
  while IFS= read -r sha; do
    [ -z "$sha" ] && continue

    message="$(git show -s --format=%B "$sha")"

    # Trailer parsing must fail CLOSED: a genuine `git interpret-trailers`
    # failure is a technical error (exit 2), never silently treated as "no
    # trailers found". An empty (but successful) parse is the normal case
    # for a commit with no trailers at all and is not an error.
    set +e
    trailers="$(printf '%s\n' "$message" | git interpret-trailers --parse)"
    trailer_rc=$?
    set -e

    if [ "$trailer_rc" -ne 0 ]; then
      echo "check_commit_attribution: error: git interpret-trailers failed for commit ${sha} (exit ${trailer_rc})." >&2
      exit 2
    fi

    [ -z "$trailers" ] && continue

    while IFS= read -r trailer_line; do
      [ -z "$trailer_line" ] && continue

      key="${trailer_line%%:*}"
      value="${trailer_line#*:}"
      value="$(printf '%s' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      key_lc="$(to_lower "$key")"

      if [ "$key_lc" != "co-authored-by" ]; then
        continue
      fi

      name="$value"
      email=""
      if [[ "$value" == *"<"*">"* ]]; then
        email="${value##*<}"
        email="${email%%>*}"
        name="${value%%<*}"
        name="$(printf '%s' "$name" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      fi

      domain=""
      if [[ "$email" == *"@"* ]]; then
        domain="${email##*@}"
      fi

      violation=0
      reason=""
      if [ -n "$domain" ] && is_ai_domain "$(to_lower "$domain")"; then
        violation=1
        reason="provider-domain identity (${domain})"
      elif [ -n "$name" ] && is_ai_name "$(to_lower "$name")"; then
        violation=1
        reason="known AI display identity (${name})"
      fi

      if [ "$violation" -eq 1 ]; then
        found_violation=1
        short_sha="$(git rev-parse --short "$sha")"
        echo "PROHIBITED AI ATTRIBUTION: commit ${short_sha} -- Co-Authored-By: ${name} <${email}> (${reason})"
      fi
    done <<<"$trailers"
  done <<<"$commit_list"
fi

if [ "$found_violation" -eq 0 ]; then
  echo "check_commit_attribution: no prohibited AI attribution found in ${base_sha}..${head_sha}."
  exit 0
fi

if [ -n "$pr_number" ] && [ -n "$exception_pr" ] && [ "$pr_number" = "$exception_pr" ]; then
  echo "check_commit_attribution: prohibited AI attribution WAS detected, but an explicit owner-approved exception is active for PR #${pr_number} via the AI_ATTRIBUTION_EXCEPTION_PR repository variable."
  echo "check_commit_attribution: treat this exception as temporary; clear/change AI_ATTRIBUTION_EXCEPTION_PR once this PR is done so it cannot silently apply to a later PR."
  exit 0
fi

echo "check_commit_attribution: prohibited AI Co-Authored-By attribution detected in ${base_sha}..${head_sha}."
exit 1
