#!/bin/bash
# Project Map — restore-layout.sh
# Reads ~/.project-map/layout.json and reopens every VS Code window
# on the correct desktop with the correct size. Runs at login via LaunchAgent.

LAYOUT_FILE="$HOME/.project-map/layout.json"
OPEN_DELAY=5

if [ ! -f "$LAYOUT_FILE" ]; then
    echo "[project-map] No layout file found at $LAYOUT_FILE — skipping restore."
    exit 0
fi

# Desktop switching and window positioning both need Accessibility permission
# granted to osascript. Without it they fail silently — surface that clearly.
if ! osascript -e 'tell application "System Events" to keystroke ""' 2>/tmp/projectmap-ax-check.err; then
    echo "[project-map] ⚠ ACCESSIBILITY PERMISSION MISSING for osascript — desktop switching and"
    echo "    window positioning will fail silently. Grant it once at:"
    echo "    System Settings → Privacy & Security → Accessibility → add /usr/bin/osascript"
fi

python3 - "$LAYOUT_FILE" <<'PYEOF'
import json, os, subprocess, sys, time

layout_file = sys.argv[1]
with open(layout_file) as f:
    layout = json.load(f)

desktops = layout.get("desktops", {})
if not desktops:
    print("[project-map] Layout is empty — nothing to restore.")
    sys.exit(0)

KEY_CODES = {1:18, 2:19, 3:20, 4:21, 5:23, 6:22, 7:26, 8:28, 9:25, 10:29}

def switch_desktop(n):
    kc = KEY_CODES.get(int(n))
    if kc:
        subprocess.run(["osascript", "-e",
            f'tell application "System Events" to key code {kc} using {{control down}}'],
            capture_output=True)
        time.sleep(0.9)

def open_and_position(path, x, y, w, h):
    # -n + --new-window forces a genuinely separate window instead of
    # merging this folder into an already-open window's workspace.
    subprocess.run(["open", "-n", "-a", "Visual Studio Code", "--args", "--new-window", path])
    time.sleep(int(os.environ.get("OPEN_DELAY", 5)))
    script = f"""
tell application "System Events"
    tell process "Code"
        set frontmost to true
        delay 0.4
        set position of front window to {{{x}, {y}}}
        set size of front window to {{{w}, {h}}}
    end tell
end tell
"""
    subprocess.run(["osascript", "-e", script])

print(f"[project-map] Restoring {sum(len(v) for v in desktops.values())} windows across {len(desktops)} desktops...")

for desktop_num in sorted(desktops.keys(), key=int):
    windows = desktops[desktop_num]
    if not windows:
        continue
    switch_desktop(desktop_num)
    for win in windows:
        name = os.path.basename(win["path"].rstrip("/"))
        print(f"  Desktop {desktop_num}: opening {name}")
        open_and_position(win["path"], win["x"], win["y"], win["w"], win["h"])

# Return to first desktop
first = sorted(desktops.keys(), key=int)[0]
switch_desktop(first)
print("[project-map] Restore complete.")
PYEOF
