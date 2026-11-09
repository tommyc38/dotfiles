#!/bin/bash
#
# Claude Code: the CLI, user-level plugins, and user-level MCP servers. Safe to re-run — every piece is
# checked first. Settings (~/.claude/settings.json) are NOT written here: they're linked from the vault
# (vault-key/claude/settings.json) by the symlinks step, and projects override them with their own
# .claude/settings.json / settings.local.json.
#
# What's installed for every project:
#   plugin  nx@nx-claude-plugins  Nx skills, CI-monitor subagent and the nx-mcp server (marketplace
#                                 nrwl/nx-ai-agents-config; enabled in settings.json too)
#   mcp     atlassian             Jira + Confluence (remote, OAuth: run /mcp once to sign in)
#   mcp     playwright            drive a real browser to check UI work (local, via npx)
#   mcp     context7              current library/framework docs (remote; works without an API key)

set -uo pipefail

export PATH="$HOME/.local/bin:$PATH"
rc=0

# --- CLI ------------------------------------------------------------------------------------------
if command -v claude >/dev/null 2>&1; then
  echo "Claude Code $(claude --version 2>/dev/null | cut -d' ' -f1) already installed (auto-updates itself)"
else
  echo "Installing Claude Code (native installer → ~/.local/bin/claude)..."
  curl -fsSL https://claude.ai/install.sh | bash || { echo "Claude Code install failed" >&2; exit 1; }
fi

# --- Plugins (user scope) -------------------------------------------------------------------------
installed="$HOME/.claude/plugins/installed_plugins.json"
known="$HOME/.claude/plugins/known_marketplaces.json"

if [ -f "$known" ] && jq -e '."nx-claude-plugins"' "$known" >/dev/null 2>&1; then
  echo "Marketplace nx-claude-plugins already known"
else
  claude plugin marketplace add nrwl/nx-ai-agents-config || rc=1
fi
if [ -f "$installed" ] && jq -e '.plugins["nx@nx-claude-plugins"][]? | select(.scope == "user")' "$installed" >/dev/null 2>&1; then
  echo "Plugin nx@nx-claude-plugins already installed (user)"
else
  claude plugin install nx@nx-claude-plugins --scope user || rc=1
fi

# --- MCP servers (user scope, stored in ~/.claude.json) -------------------------------------------
have_mcp() { [ -f "$HOME/.claude.json" ] && jq -e --arg n "$1" '.mcpServers[$n]' "$HOME/.claude.json" >/dev/null 2>&1; }
add_mcp() {
  local name="$1"; shift
  if have_mcp "$name"; then
    echo "MCP server $name already configured (user)"
  else
    claude mcp add "$@" || rc=1
  fi
}
add_mcp atlassian  --transport http --scope user atlassian https://mcp.atlassian.com/v1/mcp
add_mcp playwright --scope user playwright -- npx @playwright/mcp@latest
add_mcp context7   --transport http --scope user context7 https://mcp.context7.com/mcp

echo
echo "Next (once per machine): run 'claude', then /mcp → atlassian → authenticate (browser OAuth)."
exit $rc
