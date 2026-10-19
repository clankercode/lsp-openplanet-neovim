#!/usr/bin/env python3
"""Capture a real Neovim window in an isolated Xvfb/kitty session (Linux)."""
import os
from pathlib import Path
import subprocess
import time

root = Path(__file__).resolve().parent.parent
os.chdir(root)
artifacts = root / "artifacts"
artifacts.mkdir(exist_ok=True)
ready = artifacts / "screenshot-ready"
ready.unlink(missing_ok=True)
read_fd, write_fd = os.pipe()
xvfb = subprocess.Popen(["Xvfb", "-displayfd", str(write_fd), "-screen", "0", "1360x480x24", "-nolisten", "tcp"], pass_fds=(write_fd,), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
os.close(write_fd)
terminal = None
try:
    with os.fdopen(read_fd) as stream:
        display = ":" + stream.readline().strip()
    env = dict(os.environ, DISPLAY=display, LIBGL_ALWAYS_SOFTWARE="1")
    with (artifacts / "screenshot-terminal.log").open("w") as log:
        terminal = subprocess.Popen(["kitty", "--class", "openplanet-capture", "--override", "font_size=15", "--override", "initial_window_width=1360", "--override", "initial_window_height=480", "--override", "remember_window_size=no", "--override", "enable_audio_bell=no", "nvim", "-u", "tests/screenshot.lua"], env=env, stdout=log, stderr=log)
        deadline = time.monotonic() + 30
        while not ready.exists() and time.monotonic() < deadline:
            if terminal.poll() is not None:
                raise RuntimeError("Terminal exited: see artifacts/screenshot-terminal.log")
            time.sleep(0.1)
        if not ready.exists():
            raise RuntimeError("Neovim did not receive real diagnostics in 30s")
        time.sleep(1)
        subprocess.run(["import", "-window", "root", "docs/assets/neovim.png"], env=env, check=True)
        print("Captured docs/assets/neovim.png from real Neovim in kitty/Xvfb")
finally:
    if terminal is not None:
        terminal.terminate()
        try:
            terminal.wait(timeout=5)
        except subprocess.TimeoutExpired:
            terminal.kill()
            terminal.wait()
    xvfb.terminate()
    xvfb.wait(timeout=5)
