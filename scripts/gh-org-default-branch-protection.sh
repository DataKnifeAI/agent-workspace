#!/usr/bin/env bash
# Align default-branch protection across all repos in a GitHub org using gh.
# Settings are taken from the majority of existing protected branches in DataKnifeAI.
#
# Usage:
#   ORG=DataKnifeAI bash scripts/gh-org-default-branch-protection.sh          # dry-run
#   ORG=DataKnifeAI bash scripts/gh-org-default-branch-protection.sh --apply # write changes
#
# Private repos on GitHub Free cannot use branch protection via API; the script skips them.

set -euo pipefail

ORG="${ORG:-DataKnifeAI}"
APPLY=0
if [[ "${1:-}" == "--apply" ]]; then
  APPLY=1
fi

# Majority-aligned settings (public repos with existing protection)
BODY='{"required_status_checks":{"strict":true,"checks":[]},"enforce_admins":true,"required_pull_request_reviews":{"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"required_approving_review_count":0},"restrictions":null,"required_linear_history":true,"allow_force_pushes":false,"allow_deletions":false,"required_conversation_resolution":true}'

log() { printf '%s\n' "$*"; }

already_aligned() {
  local json="$1"
  python3 -c "
import json, sys
d = json.loads(sys.argv[1])
pr = d.get('required_pull_request_reviews') or {}
conv = (d.get('required_conversation_resolution') or {}).get('enabled')
checks = (d.get('required_status_checks') or {})
if d.get('enforce_admins', {}).get('enabled') is not True: sys.exit(1)
if d.get('required_linear_history', {}).get('enabled') is not True: sys.exit(1)
if pr.get('dismiss_stale_reviews') is not True: sys.exit(1)
if pr.get('required_approving_review_count') != 0: sys.exit(1)
if checks.get('strict') is not True: sys.exit(1)
if conv is not True: sys.exit(1)
if (d.get('allow_force_pushes') or {}).get('enabled') is True: sys.exit(1)
if (d.get('allow_deletions') or {}).get('enabled') is True: sys.exit(1)
sys.exit(0)
" "$json"
}

while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  priv=$(gh api "repos/${ORG}/${name}" -q .private)
  db=$(gh api "repos/${ORG}/${name}" -q .default_branch)

  if [[ "$priv" == "true" ]]; then
    log "SKIP (private; branch protection needs GitHub Team/Enterprise or a public repo): ${ORG}/${name} default=${db}"
    continue
  fi

  raw=""
  if raw=$(gh api "repos/${ORG}/${name}/branches/${db}/protection" 2>/dev/null); then :; else raw=""; fi

  if [[ -z "$raw" ]]; then
    log "MISSING protection: ${ORG}/${name} default=${db}"
    if [[ "$APPLY" -eq 1 ]]; then
      printf '%s' "$BODY" | gh api -X PUT "repos/${ORG}/${name}/branches/${db}/protection" --input - >/dev/null
      log "  -> applied"
    fi
    continue
  fi

  if already_aligned "$raw"; then
    log "OK (already aligned): ${ORG}/${name} default=${db}"
    continue
  fi

  log "DRIFT: ${ORG}/${name} default=${db} (will align to org standard)"
  if [[ "$APPLY" -eq 1 ]]; then
    printf '%s' "$BODY" | gh api -X PUT "repos/${ORG}/${name}/branches/${db}/protection" --input - >/dev/null
    log "  -> applied"
  fi
done < <(gh api "orgs/${ORG}/repos" --paginate -q '.[].name' | sort)

log "Done. Dry-run only unless --apply was passed."
