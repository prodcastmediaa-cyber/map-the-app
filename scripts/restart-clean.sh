#!/bin/bash
#
# Project Map — restart-clean.sh
# Clean macOS restart: saves VS Code layout first, then wipes session state.
#
# Usage: bash scripts/restart-clean.sh
#        (or double-click if saved as a .command file)

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

clear
echo "========================================================"
echo "   PROJECT MAP  —  CLEAN RESTART"
echo "========================================================"
echo
echo "This will:"
echo "  1. Save your current VS Code layout (all open sessions)"
echo "  2. Stop macOS from reopening apps/windows after restart"
echo "  3. Clear the saved macOS session state"
echo "  4. RESTART the Mac (force-closes all apps)"
echo
echo "  >>> SAVE YOUR WORK FIRST — browser tabs included. <<<"
echo
read -r -p "Type 'y' then Enter to continue (anything else cancels): " ok
if [ "$ok" != "y" ]; then
  echo "Cancelled. Nothing was changed."
  exit 0
fi

echo
echo ">> Caching admin rights (enter your Mac password if asked)..."
sudo -v || { echo "Could not get admin rights. Aborting."; exit 1; }

echo
echo ">> [1/4] Saving VS Code layout..."
python3 "$SCRIPTS_DIR/save-layout.py" \
  && echo "   ✓ Layout saved — all sessions will restore after reboot." \
  || echo "   ⚠ Could not save layout (VS Code may not be running — that's fine)."

echo
echo ">> [2/4] Disabling 'reopen windows after restart'..."
defaults write com.apple.loginwindow TALLogoutSavesState -bool false 2>/dev/null
defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false 2>/dev/null
defaults write -g NSQuitAlwaysKeepsWindows -bool false 2>/dev/null

echo ">> [3/4] Clearing saved application state..."
rm -rf ~/Library/Saved\ Application\ State/* 2>/dev/null
echo "   ✓ Done."

echo ">> [4/4] Restarting now. macOS will force-close every app —"
echo "   no app can block it. Close this window in 5 seconds to abort."
sleep 5

sudo shutdown -r now
