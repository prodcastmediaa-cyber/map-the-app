#!/usr/bin/env python3
"""
Project Map — save-layout.py  (v2)

Captures which VS Code folders are currently open by reading VS Code's OWN
persisted state (globalStorage/storage.json). No Mission Control / osascript
automation, so it runs instantly and reliably — including inside the short
window macOS gives login agents at shutdown.

(v1 scanned every desktop with osascript at shutdown; macOS force-quits login
agents within a few seconds, so that scan never finished and layout.json stayed
frozen at its first-ever snapshot. That is the "restore reopens old sessions"
bug — fixed here by reading VS Code's own state instead of scanning desktops.)

Desktop assignment comes from a persistent path->desktop map stored inside
layout.json under "path_desktop_map"; unknown folders go to DEFAULT_DESKTOP.
Window bounds come straight from VS Code's own uiState.

Run manually any time:  python3 scripts/save-layout.py
"""

import json
import os
import urllib.parse
from datetime import datetime

LAYOUT_FILE = os.path.expanduser("~/.project-map/layout.json")
STORAGE_FILE = os.path.expanduser(
    "~/Library/Application Support/Code/User/globalStorage/storage.json"
)
DEFAULT_DESKTOP = "2"
DEFAULT_BOUNDS = {"x": 0, "y": 33, "w": 751, "h": 876}


def load_json(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return default


def uri_to_path(folder_uri):
    return urllib.parse.unquote(folder_uri.replace("file://", ""))


def get_open_windows():
    """Read VS Code's own window state -> [{path, x, y, w, h}] for open folders."""
    data = load_json(STORAGE_FILE, {})
    ws = data.get("windowsState", {})
    entries = list(ws.get("openedWindows", []))
    last = ws.get("lastActiveWindow")
    if last:
        entries.append(last)

    windows, seen = [], set()
    for w in entries:
        folder = w.get("folder")
        if not folder:
            continue  # skip empty windows / bare files
        path = uri_to_path(folder)
        if path in seen:
            continue
        seen.add(path)
        ui = w.get("uiState", {})
        windows.append({
            "path": path,
            "x": ui.get("x", DEFAULT_BOUNDS["x"]),
            "y": ui.get("y", DEFAULT_BOUNDS["y"]),
            "w": ui.get("width", DEFAULT_BOUNDS["w"]),
            "h": ui.get("height", DEFAULT_BOUNDS["h"]),
        })
    return windows


def build_path_desktop_map(prev):
    """Persistent path->desktop map: explicit map wins, else infer from the
    previous 'desktops' layout so existing assignments are preserved."""
    m = dict(prev.get("path_desktop_map", {}))
    for desktop_num, wins in prev.get("desktops", {}).items():
        for w in wins:
            m.setdefault(w["path"], desktop_num)
    return m


def save_layout(data):
    os.makedirs(os.path.dirname(LAYOUT_FILE), exist_ok=True)
    with open(LAYOUT_FILE, "w") as f:
        json.dump(data, f, indent=2)


def main():
    prev = load_json(LAYOUT_FILE, {})
    path_desktop = build_path_desktop_map(prev)
    windows = get_open_windows()

    if not windows:
        # Never clobber a good layout with an empty capture (VS Code not running).
        print("[project-map] storage.json shows no open VS Code folders — layout unchanged.")
        return

    desktops = {}
    for w in windows:
        d = str(path_desktop.get(w["path"], DEFAULT_DESKTOP))
        desktops.setdefault(d, []).append(w)
        path_desktop.setdefault(w["path"], d)

    out = dict(prev)
    out["desktops"] = {k: desktops[k] for k in sorted(desktops, key=int)}
    out["path_desktop_map"] = path_desktop
    out["source"] = "storage.json"
    out["saved_at"] = datetime.now().isoformat(timespec="seconds")
    save_layout(out)

    print(f"[project-map] Saved {len(windows)} open folder(s) across "
          f"{len(desktops)} desktop(s) → {LAYOUT_FILE}")
    for d in sorted(desktops, key=int):
        names = [os.path.basename(w["path"].rstrip("/")) for w in desktops[d]]
        print(f"  Desktop {d}: {names}")


if __name__ == "__main__":
    main()
