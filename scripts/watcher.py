#!/usr/bin/env python3
"""
Project Map — watcher.py
Runs silently in the background. On system shutdown or restart,
catches SIGTERM and saves the current VS Code layout before exiting.
Does absolutely nothing during normal operation.
"""

import os, signal, subprocess, sys, time

SAVE_SCRIPT = os.path.join(os.path.dirname(__file__), "save-layout.py")


def on_shutdown(signum, frame):
    subprocess.run([sys.executable, SAVE_SCRIPT], timeout=120)
    sys.exit(0)


signal.signal(signal.SIGTERM, on_shutdown)
signal.signal(signal.SIGINT, on_shutdown)

while True:
    time.sleep(3600)
