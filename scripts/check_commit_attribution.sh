#!/usr/bin/env bash
# Detect prohibited commit attribution in a commit range.
#
# Usage:
#   check_commit_attribution.sh <base-sha> <head-sha>
#   check_commit_attribution.sh <base-sha> <head-sha> <pr-number> <exception-pr>
#
# Inspects every commit in base..head. Rejects:
# - any Co-authored-by trailer, in any case, whoever it names
# - any other message trailer, author, or committer that matches a known
#   AI/agent name or provider email domain
#
# A human author whose name merely resembles a provider (for example a
# person named Claude) is not rejected. Agent names written inside task
# files are not commit metadata and are not scanned.
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
  "cursor.com"
  "cursoragent.com"
)

# Known AI display identities (exact, case-insensitive). Deliberately does
# NOT include a bare "claude" or "codex" first name, so a human author is
# not rejected only because their name resembles a provider. "cursor" and
# "cursor agent" match those display names exactly.
ai_names=(
  "anthropic"
  "codex"
  "openai"
  "openai codex"
  "claude code"
  "claude sonnet"
  "claude opus"
  "claude haiku"
  "cursor"
  "cursor agent"
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

# Prints a reason and returns 0 when the identity is a known AI/agent.
# Returns 1 for a human or empty identity.
identity_violation_reason() {
  local name="$1" email="$2"
  local domain="" name_lc email_lc
  name_lc="$(to_lower "$name")"
  email_lc="$(to_lower "$email")"
  if [[ "$email_lc" == *"@"* ]]; then
    domain="${email_lc##*@}"
  fi
  if [ -n "$domain" ] && is_ai_domain "$domain"; then
    printf 'provider-domain identity (%s)' "$domain"
    return 0
  fi
  if [ -n "$name_lc" ] && is_ai_name "$name_lc"; then
    printf 'known AI display identity (%s)' "$name"
    return 0
  fi
  return 1
}

commit_list="$(git rev-list --reverse "${base_sha}..${head_sha}")"

found_violation=0

if [ -n "$commit_list" ]; then
  while IFS= read -r sha; do
    [ -z "$sha" ] && continue

    message="$(git show -s --format=%B "$sha")"
    short_sha="$(git rev-parse --short "$sha")"
    author_name="$(git show -s --format='%an' "$sha")"
    author_email="$(git show -s --format='%ae' "$sha")"
    committer_name="$(git show -s --format='%cn' "$sha")"
    committer_email="$(git show -s --format='%ce' "$sha")"

    if reason="$(identity_violation_reason "$author_name" "$author_email")"; then
      found_violation=1
      echo "PROHIBITED ATTRIBUTION: commit ${short_sha} -- author ${author_name} <${author_email}> (${reason})"
    fi
    if reason="$(identity_violation_reason "$committer_name" "$committer_email")"; then
      found_violation=1
      echo "PROHIBITED ATTRIBUTION: commit ${short_sha} -- committer ${committer_name} <${committer_email}> (${reason})"
    fi

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

    parsed_coauthor=0
    if [ -n "$trailers" ]; then
      while IFS= read -r trailer_line; do
        [ -z "$trailer_line" ] && continue

        key="${trailer_line%%:*}"
        value="${trailer_line#*:}"
        value="$(printf '%s' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        key_lc="$(to_lower "$key")"

        if [ "$key_lc" = "co-authored-by" ]; then
          parsed_coauthor=1
          found_violation=1
          echo "PROHIBITED ATTRIBUTION: commit ${short_sha} -- Co-authored-by trailer (${value})"
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

        if reason="$(identity_violation_reason "$name" "$email")"; then
          found_violation=1
          echo "PROHIBITED ATTRIBUTION: commit ${short_sha} -- ${key}: ${value} (${reason})"
        fi
      done <<<"$trailers"
    fi

    # A Co-authored-by line outside the formal trailer block is still a
    # trailer. Skip this when the parser already reported one, so a normal
    # trailer is not printed twice.
    if [ "$parsed_coauthor" -eq 0 ] && printf '%s\n' "$message" | grep -qiE '^[[:space:]]*co-authored-by[[:space:]]*:'; then
      found_violation=1
      raw_line="$(printf '%s\n' "$message" | grep -iE '^[[:space:]]*co-authored-by[[:space:]]*:' | head -n 1)"
      echo "PROHIBITED ATTRIBUTION: commit ${short_sha} -- Co-authored-by trailer (${raw_line})"
    fi
  done <<<"$commit_list"
fi

if [ "$found_violation" -eq 0 ]; then
  echo "check_commit_attribution: no prohibited attribution found in ${base_sha}..${head_sha}."
  exit 0
fi

if [ -n "$pr_number" ] && [ -n "$exception_pr" ] && [ "$pr_number" = "$exception_pr" ]; then
  echo "check_commit_attribution: prohibited AI attribution WAS detected, but an explicit owner-approved exception is active for PR #${pr_number} via the AI_ATTRIBUTION_EXCEPTION_PR repository variable."
  echo "check_commit_attribution: treat this exception as temporary; clear/change AI_ATTRIBUTION_EXCEPTION_PR once this PR is done so it cannot silently apply to a later PR."
  exit 0
fi

echo "check_commit_attribution: prohibited attribution detected in ${base_sha}..${head_sha}."
exit 1
