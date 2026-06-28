#!/usr/bin/env python3
"""
Project Map — save-layout.py
Scans every macOS desktop from left to right, captures all VS Code windows
(project path, position, size, desktop number) and saves to layout.json.

Triggered automatically on shutdown by the watcher. Can also be run manually:
    python3 scripts/save-layout.py
"""

import json, os, subprocess, time, urllib.parse
from datetime import datetime

LAYOUT_FILE = os.path.expanduser("~/.project-map/layout.json")
MAX_DESKTOPS = 16
SWITCH_DELAY = 0.9


def load_layout():
    if os.path.exists(LAYOUT_FILE):
        with open(LAYOUT_FILE) as f:
            return json.load(f)
    return {"scan_desktops": list(range(1, 11)), "desktops": {}}


def save_layout(data):
    os.makedirs(os.path.dirname(LAYOUT_FILE), exist_ok=True)
    data["saved_at"] = datetime.now().isoformat(timespec="seconds")
    with open(LAYOUT_FILE, "w") as f:
        json.dump(data, f, indent=2)


def press_key(key_code):
    subprocess.run(
        ["osascript", "-e",
         f'tell application "System Events" to key code {key_code} using {{control down}}'],
        capture_output=True
    )


def go_to_desktop_1():
    for _ in range(MAX_DESKTOPS + 2):
        press_key(123)   # Ctrl+Left
        time.sleep(0.12)
    time.sleep(0.6)


def get_vscode_windows():
    script = '''
tell application "System Events"
    set output to ""
    if not (exists process "Code") then return output
    repeat with win in windows of process "Code"
        try
            set t to title of win
            set pos to position of win
            set sz to size of win
            if (item 1 of sz) > 100 then
                set output to output & t & "|" & (item 1 of pos) & "|" & (item 2 of pos) & "|" & (item 1 of sz) & "|" & (item 2 of sz) & "\\n"
            end if
        end try
    end repeat
    return output
end tell
'''
    result = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
    windows = []
    for line in result.stdout.strip().splitlines():
        parts = line.strip().split("|")
        if len(parts) == 5:
            try:
                windows.append({
                    "title": parts[0].strip(),
                    "x": int(parts[1]), "y": int(parts[2]),
                    "w": int(parts[3]), "h": int(parts[4])
                })
            except ValueError:
                continue
    return windows


def build_title_to_path_map():
    state_path = os.path.expanduser(
        "~/Library/Application Support/Code/User/globalStorage/storage.json"
    )
    try:
        with open(state_path) as f:
            data = json.load(f)
    except Exception:
        return {}

    mapping = {}
    ws = data.get("windowsState", {})
    windows = list(ws.get("openedWindows", []))
    last = ws.get("lastActiveWindow")
    if last:
        windows.insert(0, last)

    for win in windows:
        folder_uri = win.get("folder", "")
        if not folder_uri:
            continue
        path = urllib.parse.unquote(folder_uri.replace("file://", ""))
        name = os.path.basename(path.rstrip("/"))
        mapping[name] = path
    return mapping


def match_title(title, title_to_path):
    project_name = title.split(" — ")[-1].strip() if " — " in title else title.strip()
    for name, path in title_to_path.items():
        if project_name.rstrip() == name.rstrip():
            return path
    for name, path in title_to_path.items():
        if project_name.lower() in name.lower() or name.lower() in project_name.lower():
            return path
    return None


def main():
    layout = load_layout()
    title_to_path = build_title_to_path_map()
    captured = {}
    seen_paths = set()
    empty_streak = 0

    print("[project-map] Scanning desktops...")
    go_to_desktop_1()

    for i in range(MAX_DESKTOPS):
        desktop_num = i + 1
        windows = get_vscode_windows()

        entries = []
        for win in windows:
            path = match_title(win["title"], title_to_path)
            if path and path not in seen_paths:
                seen_paths.add(path)
                entries.append({
                    "path": path,
                    "x": win["x"], "y": win["y"],
                    "w": win["w"], "h": win["h"]
                })

        if entries:
            captured[str(desktop_num)] = entries
            empty_streak = 0
            names = [os.path.basename(e["path"].rstrip("/")) for e in entries]
            print(f"  Desktop {desktop_num}: {', '.join(names)}")
        else:
            empty_streak += 1
            if desktop_num > 5 and empty_streak >= 3:
                break

        if i < MAX_DESKTOPS - 1:
            press_key(124)   # Ctrl+Right
            time.sleep(SWITCH_DELAY)

    if captured:
        layout["desktops"] = captured
        save_layout(layout)
        total = sum(len(v) for v in captured.values())
        print(f"[project-map] Saved {total} windows across {len(captured)} desktops → {LAYOUT_FILE}")
    else:
        print("[project-map] No VS Code windows found. Layout unchanged.")


if __name__ == "__main__":
    main()
