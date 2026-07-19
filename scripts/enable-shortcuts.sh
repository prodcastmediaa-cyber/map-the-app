#!/bin/bash
# Project Map — enable-shortcuts.sh  (v2)
# Enables Ctrl+1 .. Ctrl+10 Mission Control "Switch to Desktop" shortcuts.
#
# Uses `defaults write ... -dict-add` (routes through cfprefsd) instead of
# editing the plist file directly. A direct plist edit is silently reverted by
# cfprefsd when `activateSettings -u` runs — that was the v1 bug where the
# shortcuts never actually stuck. A logout/login is still needed to activate.

set -e
echo "[project-map] Enabling Ctrl+1 .. Ctrl+10 desktop shortcuts..."

# id : char_code : key_code   (Ctrl modifier mask = 262144)
# symbolic-hotkey ids 118..127 = "Switch to Desktop 1".."Switch to Desktop 10"
rows=(
  "118:49:18"   # Ctrl+1 -> Desktop 1
  "119:50:19"   # Ctrl+2 -> Desktop 2
  "120:51:20"   # Ctrl+3 -> Desktop 3
  "121:52:21"   # Ctrl+4 -> Desktop 4
  "122:53:23"   # Ctrl+5 -> Desktop 5
  "123:54:22"   # Ctrl+6 -> Desktop 6
  "124:55:26"   # Ctrl+7 -> Desktop 7
  "125:56:28"   # Ctrl+8 -> Desktop 8
  "126:57:25"   # Ctrl+9 -> Desktop 9
  "127:48:29"   # Ctrl+0 -> Desktop 10
)

for row in "${rows[@]}"; do
  IFS=":" read -r id char kc <<< "$row"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$id" \
    "{enabled = 1; value = {type = standard; parameters = ($char, $kc, 262144);};}"
done

/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
echo "[project-map] Done. Log out and back in for the shortcuts to activate."
