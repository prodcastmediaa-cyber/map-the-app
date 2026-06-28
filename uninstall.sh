#!/bin/bash
# Project Map — uninstall.sh
# Cleanly removes Project Map from your system.

echo "[project-map] Uninstalling..."

# Unload LaunchAgents
launchctl unload ~/Library/LaunchAgents/com.projectmap.restore.plist 2>/dev/null && \
    echo "✓ Restore agent unloaded"
launchctl unload ~/Library/LaunchAgents/com.projectmap.watcher.plist 2>/dev/null && \
    echo "✓ Watcher agent unloaded"

# Remove plist files
rm -f ~/Library/LaunchAgents/com.projectmap.restore.plist
rm -f ~/Library/LaunchAgents/com.projectmap.watcher.plist
echo "✓ LaunchAgents removed"

# Restore Dock settings to macOS defaults
defaults delete com.apple.dock mru-spaces 2>/dev/null || true
defaults delete com.apple.dock workspaces-auto-swoosh 2>/dev/null || true
killall Dock
echo "✓ Dock settings restored to macOS defaults"

echo ""
echo "Project Map uninstalled."
echo "Your layout file is kept at ~/.project-map/layout.json"
echo "Delete it manually if you want: rm -rf ~/.project-map"
