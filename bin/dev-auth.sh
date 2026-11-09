#!/bin/bash
#
# Check — and, where needed, log in to — every code host and work tool this machine talks to:
#
#   github     gh CLI on github.com (personal + printix org) and tungstencloud.ghe.com (Tungsten Cloud)
#   jira       Atlassian CLI (acli) on tungstenautomation.atlassian.net
#   bitbucket  SSH for git, plus an optional API token for REST calls (bitbucket.org/tom-conley)
#   aws        AWS CLI SSO session for the personal AWS org (vault-key/personal/aws-config)
#
# SSH keys themselves come from the vault (see bin/ssh-setup.sh); this script only verifies them.
# Safe to re-run: anything already authenticated is left alone.

set -uo pipefail

script="$(basename "$0")"

# --- Defaults (override with env vars) ------------------------------------------------------------
GH_HOSTS="${GH_HOSTS:-github.com tungstencloud.ghe.com}"
JIRA_SITE="${JIRA_SITE:-tungstenautomation.atlassian.net}"
JIRA_EMAIL="${JIRA_EMAIL:-tom.conley@tungstenautomation.com}"
# Optional, for non-interactive logins. Keep these in a vault-key/*.env file, never in this repo.
#   JIRA_API_TOKEN       https://id.atlassian.com/manage-profile/security/api-tokens
#   BITBUCKET_EMAIL      Atlassian account email for bitbucket.org
#   BITBUCKET_API_TOKEN  https://id.atlassian.com/manage-profile/security/api-tokens (Bitbucket scopes)
# ---------------------------------------------------------------------------------------------------

check_only=
only=
failures=0

if [ -t 1 ]; then G=$'\e[32m' R=$'\e[31m' Y=$'\e[33m' B=$'\e[1m' N=$'\e[0m'; else G='' R='' Y='' B='' N=''; fi
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
bad()  { printf '  %s✗%s %s\n' "$R" "$N" "$*"; failures=$((failures + 1)); }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
info() { printf '    %s\n' "$*"; }
step() { printf '\n%s%s%s\n' "$B" "$*" "$N"; }

usage() {
  cat <<EOF
Usage:
  $script [--check] [--only <list>] [-h|--help]

Verify authentication for GitHub (gh), Jira (acli), Bitbucket and AWS SSO, and log in to anything
that isn't authenticated yet. Logins open a browser (OAuth) unless an API token env var is set.

Options:
  -c, --check         Report status only; never start a login.
  -o, --only <list>   Comma-separated subset of: github,jira,bitbucket,aws
  -h, --help          Show this help.

Environment:
  GH_HOSTS            Hosts for gh            (default: "$GH_HOSTS")
  JIRA_SITE           Atlassian site for acli (default: $JIRA_SITE)
  JIRA_EMAIL          Email for token login   (default: $JIRA_EMAIL)
  JIRA_API_TOKEN      If set, acli logs in with this token instead of the browser
  BITBUCKET_EMAIL     \ If both set, the Bitbucket REST API is verified with them
  BITBUCKET_API_TOKEN /

Examples:
  $script                     # check everything, log in where needed
  $script --check             # status report only (also run by bin/validate-install.sh)
  $script --only github,jira
EOF
}

wanted() { [ -z "$only" ] || [[ ",$only," == *",$1,"* ]]; }
interactive() { [ -z "$check_only" ] && [ -t 0 ]; }

# ssh -T never gives a shell on these hosts, so the exit code is useless; the greeting tells us.
ssh_check() {
  local target="$1" expect="$2" out
  # accept-new: on a fresh machine known_hosts is empty; still refuses a CHANGED host key.
  out="$(ssh -T -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "$target" 2>&1)"
  if grep -qiE "$expect" <<<"$out" && ! grep -qi 'permission denied' <<<"$out"; then
    ok "ssh $target"
  else
    bad "ssh $target — $(tail -1 <<<"$out")"
    info "Is the key in ~/.ssh and listed in vault-key/ssh-keys.txt? Try: $DOTFILES_BIN/ssh-setup.sh"
  fi
}

# --- GitHub ---------------------------------------------------------------------------------------
check_github() {
  step "GitHub (gh)"
  if ! command -v gh >/dev/null; then bad "gh not installed (brew install gh)"; return; fi

  local host
  for host in $GH_HOSTS; do
    if gh auth status --hostname "$host" >/dev/null 2>&1; then
      ok "gh logged in to $host as $(gh api --hostname "$host" user --jq .login 2>/dev/null || echo '?')"
    elif interactive; then
      warn "gh is not logged in to $host — opening browser login"
      if gh auth login --hostname "$host" --git-protocol ssh --skip-ssh-key --web; then
        ok "gh logged in to $host"
      else
        bad "gh login to $host failed"
      fi
    else
      bad "gh not logged in to $host — run: gh auth login --hostname $host --git-protocol ssh --web"
    fi
  done

  ssh_check git@github.com "successfully authenticated"
  [[ " $GH_HOSTS " == *" tungstencloud.ghe.com "* ]] &&
    ssh_check tungstencloud@tungstencloud.ghe.com "successfully authenticated"
}

# --- Jira -----------------------------------------------------------------------------------------
check_jira() {
  step "Jira (acli → $JIRA_SITE)"
  if ! command -v acli >/dev/null; then bad "acli not installed (brew install atlassian/acli/acli)"; return; fi

  if acli jira auth status >/dev/null 2>&1; then
    ok "acli jira authenticated"
    return
  fi
  if [ -n "$check_only" ]; then
    bad "acli jira not authenticated — run: $script --only jira"
    return
  fi

  if [ -n "${JIRA_API_TOKEN:-}" ]; then
    printf '%s' "$JIRA_API_TOKEN" |
      acli jira auth login --site "$JIRA_SITE" --email "$JIRA_EMAIL" --token >/dev/null 2>&1
  elif interactive; then
    warn "acli jira is not authenticated — opening browser login (pick $JIRA_SITE)"
    acli jira auth login --web
  fi

  if acli jira auth status >/dev/null 2>&1; then
    ok "acli jira authenticated"
  else
    bad "acli jira login failed — set JIRA_API_TOKEN or run: acli jira auth login --web"
  fi
}

# --- Bitbucket ------------------------------------------------------------------------------------
check_bitbucket() {
  step "Bitbucket (ssh.bitbucket.org)"
  # Bitbucket Cloud's SSH host (bitbucket.org itself is HTTPS-only after Atlassian's 2026 cutoff).
  ssh_check git@ssh.bitbucket.org "you can use git"

  if [ -n "${BITBUCKET_EMAIL:-}" ] && [ -n "${BITBUCKET_API_TOKEN:-}" ]; then
    local status
    status="$(curl -s -o /dev/null -w '%{http_code}' -u "$BITBUCKET_EMAIL:$BITBUCKET_API_TOKEN" \
      https://api.bitbucket.org/2.0/user)"
    if [ "$status" = 200 ]; then
      ok "Bitbucket API token works ($BITBUCKET_EMAIL)"
    else
      bad "Bitbucket API token rejected (HTTP $status)"
    fi
  else
    warn "No Bitbucket API token (only needed for REST/API use; git uses SSH)"
    info "Create one at https://id.atlassian.com/manage-profile/security/api-tokens (Bitbucket scopes),"
    info "then add BITBUCKET_EMAIL / BITBUCKET_API_TOKEN to a vault-key/*.env and run 'vault -e'."
  fi
}

# --- AWS (personal org, IAM Identity Center) ------------------------------------------------------
check_aws() {
  step "AWS SSO (personal org)"
  if ! command -v aws >/dev/null; then bad "aws not installed (brew install awscli)"; return; fi
  # Use the personal profiles even when run from a Tungsten folder.
  local config="$DOTFILES_ROOT/vault-key/personal/aws-config" arn
  if [ ! -f "$config" ]; then warn "no vault-key/personal/aws-config (run the vault step)"; return; fi
  arn="$(AWS_CONFIG_FILE="$config" aws sts get-caller-identity --profile gotomconley-sandbox --query Arn --output text 2>/dev/null)"
  if [ -n "$arn" ]; then
    ok "SSO session active (${arn##*/} via gotomconley-sandbox)"
  elif interactive; then
    warn "no active SSO session — opening the browser login"
    if AWS_CONFIG_FILE="$config" aws sso login --sso-session personal; then ok "AWS SSO logged in"; else bad "aws sso login failed"; fi
  else
    bad "no active SSO session — run: aws sso login --sso-session personal"
  fi
}

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -c|--check) check_only=true; shift ;;
      -o|--only) only="${2:-}"; shift 2 ;;
      --only=*) only="${1#*=}"; shift ;;
      -h|--help) usage; exit 0 ;;
      *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
  done

  DOTFILES_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DOTFILES_ROOT="$(cd "$DOTFILES_BIN/.." && pwd)"

  wanted github && check_github
  wanted jira && check_jira
  wanted bitbucket && check_bitbucket
  wanted aws && check_aws

  echo
  if [ "$failures" -eq 0 ]; then
    printf '%sAll authenticated.%s\n' "$G" "$N"
  else
    printf '%s%d problem(s) above.%s\n' "$R" "$failures" "$N"
    exit 1
  fi
}

main "$@"
