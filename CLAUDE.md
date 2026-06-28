# CLAUDE.md — AI Assistant Guide for Project Map

This file is for AI coding assistants (Claude Code, GitHub Copilot, Cursor, Cline, etc.)
helping a user install and configure Project Map on their Mac.

---

## What This Project Does

Project Map is a macOS desktop layout manager. It:
1. Saves VS Code window positions and which desktop they're on (on shutdown)
2. Restores them exactly on next boot
3. Stops macOS from auto-rearranging desktop order
4. Stops apps from jumping you to a different desktop when you click them

**Target user:** Mac users with multiple desktops and multiple VS Code projects open simultaneously.

---

## One-Prompt Installation

If a user says **"install project-map on my system"** or similar, run these steps in order:

```bash
# 1. Run the installer
bash install.sh

# 2. Enable shortcuts (included in installer, but can be run standalone)
bash scripts/enable-shortcuts.sh
```

Then tell the user about the 2 manual steps below.

---

## What Is Fully Automated

The installer (`bash install.sh`) handles all of this without any user interaction:

- ✅ Disables macOS auto-rearranging desktops (`mru-spaces = false`)
- ✅ Disables app-switching jumping to another desktop (`workspaces-auto-swoosh = false`)
- ✅ Enables `Ctrl+1` through `Ctrl+10` keyboard shortcuts for desktop switching
- ✅ Scans current VS Code windows and saves layout to `~/.project-map/layout.json`
- ✅ Installs LaunchAgent that restores layout on every boot
- ✅ Installs background watcher that saves layout on every shutdown

---

## What Requires Manual Action (Tell the User Exactly This)

### Manual Step 1 — Log out and back in (one time only)
This activates the `Ctrl+1–10` keyboard shortcuts. The shortcuts are written to the plist
but macOS only reads them on session start.

```
Apple menu → Log Out → Log back in
```

### Manual Step 2 — Pin single-window apps to their desktop
For apps like **Slack, WhatsApp, Messages** that the user wants on a specific desktop:

1. Go to that desktop (e.g. Desktop 1)
2. Right-click the app in the **Dock**
3. Click **Options → This Desktop**

**Important:** Skip Chrome. If the user has multiple Chrome profiles open across different
desktops, pinning Chrome via Dock will only work for one profile/window. Chrome must be
handled separately or left unpinned.

**Why you can't automate Step 2:** The Dock's right-click context menu is a `CGMenu`
(Core Graphics) — it is intentionally excluded from macOS Accessibility/AppleScript APIs.
This is a macOS security design decision, not a script limitation.

---

## Customization Tasks You Can Help With

### Add more VS Code windows to the layout
If the user opens a new VS Code project and wants it tracked:
```bash
python3 scripts/save-layout.py
```
This rescans all desktops and updates `~/.project-map/layout.json`.

### Scan more desktops (for large monitor/TV setups)
Edit `~/.project-map/layout.json` and the `MAX_DESKTOPS` constant in `scripts/save-layout.py`:
```python
MAX_DESKTOPS = 20  # or however many desktops the user has
```

### Change which desktop a project opens on
Edit `~/.project-map/layout.json` directly:
```json
{
  "desktops": {
    "3": [
      {"path": "/Users/username/projects/my-project", "x": 0, "y": 33, "w": 756, "h": 876}
    ]
  }
}
```

### Check if agents are running
```bash
launchctl list | grep projectmap
```

### View logs
```bash
cat ~/Library/Logs/project-map-restore.log
cat ~/Library/Logs/project-map-watcher.log
```

### Uninstall
```bash
bash uninstall.sh
```

---

## Common Issues and Fixes

| Problem | Cause | Fix |
|---------|-------|-----|
| `Ctrl+1` doesn't switch desktop | Manual Step 1 not done | Log out and back in |
| VS Code opens on wrong desktop | Layout saved before setup complete | Run `python3 scripts/save-layout.py` again after arranging windows |
| Nothing restores on boot | LaunchAgent not loaded | Run `launchctl load ~/Library/LaunchAgents/com.projectmap.restore.plist` |
| Save script finds 0 windows | VS Code not open when save runs | Open VS Code, arrange windows, then run save script manually |
| Accessibility permission error | Terminal not in Accessibility list | System Settings → Privacy & Security → Accessibility → add Terminal |

---

## Architecture Notes

- **save-layout.py**: Navigates Desktop 1 → right → detects VS Code windows via AppleScript
  (`System Events`). Matches window titles to project paths using VS Code's internal
  `globalStorage/storage.json`. Saves to `~/.project-map/layout.json`.

- **restore-layout.sh**: Reads `layout.json`, switches to each desktop via `Ctrl+N` key codes,
  opens VS Code with the project path, then positions the window via AppleScript.

- **watcher.py**: Long-running background process. Catches `SIGTERM` (sent by macOS on
  shutdown/restart) and triggers `save-layout.py` before exiting.

- **LaunchAgents**: `com.projectmap.restore` runs once at login (`RunAtLoad=true`).
  `com.projectmap.watcher` runs continuously (`KeepAlive=true`), restarted by launchd if it crashes.

- **Desktop switching**: Uses `Ctrl+N` symbolic hotkeys (IDs 118–127 in
  `com.apple.symbolichotkeys.plist`). These must be enabled — `enable-shortcuts.sh` handles this.

---

## macOS Version Notes

| macOS | Status |
|-------|--------|
| Ventura 13+ | ✅ Fully tested |
| Monterey 12 | ✅ Works |
| Big Sur 11 | ⚠️ Should work, not tested |
| Catalina 10.15 | ⚠️ Should work, not tested |
| Windows | ❌ Not supported |
| Linux | ❌ Not supported |
