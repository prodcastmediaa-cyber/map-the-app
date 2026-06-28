# 🗺️ Project Map

**Stop your apps from getting lost across desktops. Forever.**

> Built out of pure frustration — Chrome windows drifting to random desktops, VS Code sessions disappearing after every restart, macOS quietly reshuffling your carefully arranged spaces. Project Map locks everything in place.

---

## The Problem

You set up your Mac perfectly:
- Desktop 1 → Slack + WhatsApp
- Desktop 2 → VS Code (project A + project B, side by side)
- Desktop 3 → VS Code (project C + project D)
- Desktop 5 → Chrome (your work profile)
- Desktop 6 → Chrome (client profile) + Creative Cloud

Then you restart. Or click a Dock icon. Or macOS decides to "helpfully" rearrange things.

**Everything. Is. Gone.**

---

## What Project Map Does

```
┌─────────────────────────────────────────────────────────────┐
│                    YOUR MAC DESKTOP                         │
├──────────┬──────────┬──────────┬──────────┬──────────┬─────┤
│Desktop 1 │Desktop 2 │Desktop 3 │Desktop 4 │Desktop 5 │ ... │
│          │          │          │          │          │     │
│ Slack    │ VS Code  │ VS Code  │ Finder   │ Chrome   │     │
│ WhatsApp │ [Proj A] │ [Proj C] │          │ [Work]   │     │
│          │ [Proj B] │ [Proj D] │          │          │     │
└──────────┴──────────┴──────────┴──────────┴──────────┴─────┘
         ↑ Project Map keeps this EXACTLY like this, always.
```

### On every shutdown → saves layout
### On every boot → restores layout

---

## How It Works

```mermaid
flowchart TD
    A([🖥️ Mac Starts Up]) --> B[LaunchAgent: restore-layout.sh]
    B --> C{layout.json exists?}
    C -- Yes --> D[Switch to each Desktop\nCtrl+1, Ctrl+2, Ctrl+3...]
    D --> E[Open VS Code projects\nin exact positions]
    E --> F([✅ Your layout is back])
    C -- No --> G([Skip — first run])

    H([🔴 Mac Shutting Down]) --> I[watcher.py receives SIGTERM]
    I --> J[save-layout.py runs]
    J --> K[Navigate Desktop 1 → 2 → 3...]
    K --> L[Capture every VS Code window\nproject path + x,y,width,height]
    L --> M[Save to ~/.project-map/layout.json]
    M --> N([✅ Layout captured])

    O([⚙️ macOS Settings]) --> P[mru-spaces = OFF\nSpaces never auto-rearrange]
    O --> Q[workspaces-auto-swoosh = OFF\nClicking apps stays on current desktop]
    O --> R[Ctrl+1–10 enabled\nJump to any desktop instantly]
```

---

## Requirements

- **macOS only** (Ventura 13+ recommended, works on Monterey 12+)
- **Apple Silicon or Intel Mac** — both work
- **Visual Studio Code** installed at `/Applications/Visual Studio Code.app`
- **Python 3** (ships with macOS — no install needed)
- Accessibility permissions for Terminal/your shell (System Settings → Privacy → Accessibility)

---

## Install

```bash
git clone https://github.com/prodcastmediaa-cyber/project-map.git
cd project-map
bash install.sh
```

That's it. The installer handles everything automatically.

---

## What the Installer Does (Automated)

| Step | What happens |
|------|-------------|
| Lock desktop order | `mru-spaces = false` — macOS stops reshuffling your spaces |
| Fix app switching | `workspaces-auto-swoosh = false` — clicking Dock icons stays on current desktop |
| Enable shortcuts | `Ctrl+1` through `Ctrl+10` — jump to any desktop instantly |
| Save current layout | Scans all open VS Code windows, saves positions to `~/.project-map/layout.json` |
| Boot restore agent | LaunchAgent that reopens VS Code windows on the right desktops at login |
| Shutdown watcher | Background process that saves your layout every time you shut down |

---

## Manual Steps (2 only — takes 60 seconds)

### Step 1 — Log out and back in once
After install, log out and log back in. This activates the `Ctrl+1–10` keyboard shortcuts. You only do this once.

### Step 2 — Pin single-window apps to their desktop
For apps like Slack, WhatsApp, Messages that live on one specific desktop:

1. Go to that desktop
2. Right-click the app icon in the Dock
3. **Options → This Desktop**

> Skip Chrome — if you have multiple Chrome profiles open across desktops, you can't pin it to one. That's by design.

---

## After Install

| What you want | How |
|--------------|-----|
| Jump to Desktop 3 | `Ctrl+3` |
| See your saved layout | `cat ~/.project-map/layout.json` |
| Manually save layout now | `python3 scripts/save-layout.py` |
| Check restore logs | `cat ~/Library/Logs/project-map-restore.log` |
| Uninstall | `bash uninstall.sh` |

---

## File Structure

```
project-map/
├── install.sh                          # One-command installer
├── uninstall.sh                        # Clean removal
├── scripts/
│   ├── save-layout.py                  # Scans desktops → saves layout.json
│   ├── restore-layout.sh               # Reads layout.json → restores windows
│   ├── watcher.py                      # Catches shutdown signal → triggers save
│   └── enable-shortcuts.sh             # Enables Ctrl+1–10 in Mission Control
├── launchagents/
│   ├── com.projectmap.restore.plist    # Runs restore at login
│   └── com.projectmap.watcher.plist    # Runs watcher in background
└── CLAUDE.md                           # AI assistant installation guide
```

---

## Limitations

- **VS Code only** — other apps (Chrome, Slack) need the manual Dock pin (Step 2)
- **Desktops 1–10 supported** — Ctrl+1 through Ctrl+10 covers most setups
- **Window positions** are saved in logical pixels — if you change screen resolution, re-run `save-layout.py`
- **No Windows support** — Mac only for now

---

## Built By

[@prodcastmediaa](https://github.com/prodcastmediaa-cyber) — built this after one too many times losing Chrome to Desktop 6.

---

## License

MIT — use it, fork it, do whatever.
