#!/usr/bin/env python3
"""
Project Map — watcher.py  (v2)

Snapshots the VS Code layout every SNAPSHOT_INTERVAL seconds AND on shutdown
(SIGTERM/SIGINT). save-layout.py v2 only reads VS Code's own storage.json (no
Mission Control automation), so periodic snapshots are cheap and invisible —
the saved layout is always fresh even when the shutdown signal window is too
short to finish anything. (v1 only tried to save on SIGTERM and never
completed, which is why the layout stayed frozen.)
"""

import os
import signal
import subprocess
import sys
import time

SAVE_SCRIPT = os.path.join(os.path.dirname(__file__), "save-layout.py")
SNAPSHOT_INTERVAL = 300  # seconds (5 minutes)


def snapshot():
    try:
        subprocess.run([sys.executable, SAVE_SCRIPT], timeout=60)
    except Exception as e:
        print(f"[project-map] snapshot failed: {e}", flush=True)


def on_shutdown(signum, frame):
    snapshot()
    sys.exit(0)


signal.signal(signal.SIGTERM, on_shutdown)
signal.signal(signal.SIGINT, on_shutdown)

# One snapshot on start, then every interval.
snapshot()
while True:
    time.sleep(SNAPSHOT_INTERVAL)
    snapshot()
