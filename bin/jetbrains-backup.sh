#!/bin/bash
#
# Snapshot portable WebStorm settings into ~/dotfiles/webstorm/settings/ (a backup that doesn't depend on
# your JetBrains account). Day to day, JetBrains Settings Sync is what keeps machines in sync.
#
#   jetbrains-backup.sh                 # export from the newest WebStorm* config dir
#   jetbrains-backup.sh WebStorm2025.3  # export from a specific one
#
# Restore on a new machine (IDE closed):
#   cp -R ~/dotfiles/webstorm/settings/* ~/Library/Application\ Support/JetBrains/<WebStormYYYY.N>/
# and reinstall plugins from webstorm/settings/plugins.txt (Settings → Plugins).
#
# Only allowlisted, non-secret files are copied: no tokens, licenses, recent projects or caches.

set -euo pipefail

JB="$HOME/Library/Application Support/JetBrains"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/webstorm/settings"

if [ $# -gt 0 ]; then
  SRC="$JB/$1"
else
  SRC="$(ls -d "$JB"/WebStorm* 2>/dev/null | sort -V | tail -1)"
fi
[ -d "$SRC" ] || { echo "No WebStorm config directory found (looked for: ${SRC:-$JB/WebStorm*})" >&2; exit 1; }

DIRS=(keymaps codestyles colors templates fileTemplates inspection)
OPTIONS=(
  editor.xml editor-font.xml console-font.xml terminal-font.xml terminal.xml colors.scheme.xml
  laf.xml ui.lnf.xml keymapFlags.xml vim_settings.xml filetypes.xml advancedSettings.xml
  ide.general.xml project.default.xml markdown.xml diff.xml find.xml
)

rm -rf "$DEST"
mkdir -p "$DEST/options"
for d in "${DIRS[@]}"; do
  [ -d "$SRC/$d" ] && cp -R "$SRC/$d" "$DEST/"
done
for f in "${OPTIONS[@]}"; do
  [ -f "$SRC/options/$f" ] && cp "$SRC/options/$f" "$DEST/options/"
done
# Plugin-generated live-template packs are huge and reinstall with their plugin.
rm -f "$DEST"/templates/font-awesome*.xml
[ -f "$SRC/disabled_plugins.txt" ] && cp "$SRC/disabled_plugins.txt" "$DEST/"
# Installed (non-bundled) plugins, by directory name.
ls "$SRC/plugins" 2>/dev/null | sort > "$DEST/plugins.txt" || true

echo "Exported $(basename "$SRC") settings to ${DEST/#$HOME/~}"
echo "Review with: git -C ${DEST%/webstorm/settings} status webstorm/"
