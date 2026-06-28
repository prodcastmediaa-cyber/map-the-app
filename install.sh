#!/bin/bash
# Project Map — install.sh
# One-command installer for macOS.
# Usage: bash install.sh

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.project-map"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║         Project Map Installer        ║"
echo "║     macOS Desktop Layout Manager     ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 1. Create config directory ─────────────────────────────────────────────
mkdir -p "$CONFIG_DIR"
echo "✓ Config directory: $CONFIG_DIR"

# ── 2. Make scripts executable ─────────────────────────────────────────────
chmod +x "$REPO_DIR/scripts/"*.sh "$REPO_DIR/scripts/"*.py
ln -sf "$REPO_DIR/scripts/restart-clean.sh" "$HOME/Desktop/restart-clean.command" 2>/dev/null || true
echo "✓ Scripts made executable"
echo "✓ restart-clean.command linked to Desktop (saves layout before restart)"

# ── 3. Freeze desktop order (stop macOS shuffling spaces) ──────────────────
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock workspaces-auto-swoosh -bool false
killall Dock
echo "✓ Desktop order locked (mru-spaces + workspaces-auto-swoosh disabled)"

# ── 4. Enable Ctrl+1–10 desktop shortcuts ──────────────────────────────────
bash "$REPO_DIR/scripts/enable-shortcuts.sh"

# ── 5. Install LaunchAgents (restore on boot + watcher on shutdown) ─────────
for plist in restore watcher; do
    SRC="$REPO_DIR/launchagents/com.projectmap.$plist.plist"
    DST="$LAUNCH_AGENTS/com.projectmap.$plist.plist"

    # Replace placeholders with real paths
    sed \
        -e "s|INSTALL_PATH_PLACEHOLDER|$REPO_DIR|g" \
        -e "s|HOME_PLACEHOLDER|$HOME|g" \
        "$SRC" > "$DST"

    # Unload if already running, then reload
    launchctl unload "$DST" 2>/dev/null || true
    launchctl load   "$DST"
    echo "✓ LaunchAgent loaded: com.projectmap.$plist"
done

# ── 6. Save current layout snapshot ────────────────────────────────────────
echo ""
echo "Scanning current VS Code layout..."
python3 "$REPO_DIR/scripts/save-layout.py"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║         Installation Complete!       ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "✅ Automated (done):"
echo "   • Desktop order frozen — spaces never shuffle again"
echo "   • App-switching stays on current desktop"
echo "   • Ctrl+1–10 shortcuts enabled"
echo "   • VS Code layout saves on every shutdown"
echo "   • VS Code layout restores on every boot"
echo "   • restart-clean.command on Desktop — saves layout then does a clean restart"
echo ""
echo "⚠️  Manual steps (2 quick ones — do these now):"
echo ""
echo "   STEP 1 — Log out and back in once:"
echo "   Apple menu → Log Out → Log back in"
echo "   (activates Ctrl+1–10 keyboard shortcuts)"
echo ""
echo "   STEP 2 — Pin single-window apps to their desktop:"
echo "   Go to each desktop → right-click the app in Dock"
echo "   → Options → 'This Desktop'"
echo "   Recommended: Slack, WhatsApp, Messages on Desktop 1"
echo "   (Skip Chrome — it runs on multiple desktops)"
echo ""
echo "   Layout saved to: $CONFIG_DIR/layout.json"
echo "   Logs at: ~/Library/Logs/project-map-*.log"
echo ""
