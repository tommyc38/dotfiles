#!/bin/bash
#
# Check — and, where needed, log in to — every code host and work tool this machine talks to:
#
#   github     gh CLI on github.com (personal + printix org) and tungstencloud.ghe.com (Tungsten Cloud)
#   jira       Atlassian CLI (acli) on tungstenautomation.atlassian.net
#   bitbucket  SSH for git, plus an optional API token for REST calls (bitbucket.org/tom-conley)
#   azure      az CLI + azure-devops extension, and SSH to ssh.dev.azure.com
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

Verify authentication for GitHub (gh), Jira (acli), Bitbucket and Azure DevOps, and log in to anything
that isn't authenticated yet. Logins open a browser (OAuth) unless an API token env var is set.

Options:
  -c, --check         Report status only; never start a login.
  -o, --only <list>   Comma-separated subset of: github,jira,bitbucket,azure
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
  out="$(ssh -T -o BatchMode=yes -o ConnectTimeout=10 "$target" 2>&1)"
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
  step "Bitbucket (bitbucket.org)"
  ssh_check git@bitbucket.org "you can use git"

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

# --- Azure DevOps ---------------------------------------------------------------------------------
check_azure() {
  step "Azure DevOps (az)"
  if ! command -v az >/dev/null; then bad "az not installed (brew install azure-cli)"; return; fi

  if az extension show --name azure-devops >/dev/null 2>&1; then
    ok "azure-devops extension installed"
  elif [ -z "$check_only" ]; then
    az extension add --name azure-devops --only-show-errors && ok "azure-devops extension installed"
  else
    bad "azure-devops extension missing — run: az extension add --name azure-devops"
  fi

  if az account show >/dev/null 2>&1; then
    ok "az logged in as $(az account show --query user.name -o tsv 2>/dev/null)"
  elif interactive; then
    warn "az is not logged in — opening browser login"
    az login --only-show-errors >/dev/null && ok "az logged in" || bad "az login failed"
  else
    bad "az not logged in — run: az login"
  fi

  # Azure DevOps closes the channel after auth ("shell request failed"); only a key failure is fatal.
  ssh_check git@ssh.dev.azure.com "shell request failed|not supported"
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

  wanted github && check_github
  wanted jira && check_jira
  wanted bitbucket && check_bitbucket
  wanted azure && check_azure

  echo
  if [ "$failures" -eq 0 ]; then
    printf '%sAll authenticated.%s\n' "$G" "$N"
  else
    printf '%s%d problem(s) above.%s\n' "$R" "$failures" "$N"
    exit 1
  fi
}

main "$@"
