#!/bin/bash
# Project Map — enable-shortcuts.sh
# Enables Ctrl+1 through Ctrl+10 Mission Control "Switch to Desktop" shortcuts.
# Run once during install. Requires logout/login to fully activate.

echo "[project-map] Enabling Ctrl+1–10 desktop shortcuts..."

python3 <<'PYEOF'
import plistlib, os, shutil

plist_path = os.path.expanduser('~/Library/Preferences/com.apple.symbolichotkeys.plist')
backup     = plist_path + '.project-map-backup'
shutil.copy2(plist_path, backup)

with open(plist_path, 'rb') as f:
    plist = plistlib.load(f)

hotkeys = plist.setdefault('AppleSymbolicHotKeys', {})

# (symbolic_id, char_code, key_code) — Ctrl+1 through Ctrl+0 (Desktop 10)
shortcuts = [
    ('118', 49, 18), ('119', 50, 19), ('120', 51, 20),
    ('121', 52, 21), ('122', 53, 23), ('123', 54, 22),
    ('124', 55, 26), ('125', 56, 28), ('126', 57, 25),
    ('127', 48, 29),
]

for hk_id, char, kc in shortcuts:
    hotkeys[hk_id] = {
        'enabled': True,
        'value': {'parameters': [char, kc, 262144], 'type': 'standard'}
    }

with open(plist_path, 'wb') as f:
    plistlib.dump(plist, f, fmt=plistlib.FMT_BINARY)

print(f'  Shortcuts written. Backup saved to {backup}')
PYEOF

/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
echo "[project-map] Done. Log out and back in for shortcuts to activate."
