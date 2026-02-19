"""Live-reload bridge script for standalone KLayout preview.

This script is launched by `core.GdsModeler.launch_external_preview(...)` using
KLayout's `-rr` option. It opens the provided GDS file in the desktop view and
keeps reloading when the file timestamp changes.

Runtime globals (passed via `-rd`) expected by this script:
- `preview_gds_file` (required): path to the GDS file to watch.
- `preview_refresh_ms` (optional): poll period in milliseconds (minimum 20).
- `preview_zoom_fit` (optional): whether to call `zoom_fit()` on startup.
- `preview_show_all` (optional): whether to call `show_all_cells()` on reload.
- `preview_ready_file` (optional): file path touched when initial load is done.
"""

import os
import time

import pya


def _get_bool(name, default):
    """Parse one script global variable as a boolean."""
    raw = globals().get(name, default)
    if isinstance(raw, str):
        return raw.strip().lower() in ("1", "true", "yes", "on")
    return bool(raw)


def _get_int(name, default):
    """Parse one script global variable as an integer with fallback."""
    raw = globals().get(name, default)
    try:
        return int(float(raw))
    except Exception:
        return int(default)


# Launch/runtime options injected by GdsModeler.
gds_file = str(globals().get("preview_gds_file", ""))
refresh_ms = max(20, _get_int("preview_refresh_ms", 20))
zoom_fit = _get_bool("preview_zoom_fit", True)
show_all = _get_bool("preview_show_all", True)
ready_file = str(globals().get("preview_ready_file", ""))

if gds_file == "":
    raise RuntimeError("preview_gds_file is required.")

app = pya.Application.instance()
mw = app.main_window()
if mw is None:
    raise RuntimeError("KLayout preview bridge requires GUI mode.")

# Initial load into current KLayout desktop window.
opts = pya.LoadLayoutOptions()
cv = mw.load_layout(gds_file, opts, "", 1)
view = mw.current_view()
cv_index = cv.index()

# Optional initial view setup.
if view is not None:
    if show_all:
        view.show_all_cells()
    if zoom_fit:
        view.zoom_fit()

# Signal readiness to the caller when requested.
if ready_file != "":
    try:
        with open(ready_file, "w", encoding="utf-8") as f:
            f.write("ready\n")
    except Exception:
        pass

# Track modification timestamp so we only reload on updates.
last_mtime = -1.0
if os.path.isfile(gds_file):
    last_mtime = os.path.getmtime(gds_file)

# Main watch loop: keep the GUI responsive and reload on file change.
while True:
    app.process_events()
    time.sleep(refresh_ms / 1000.0)

    if not os.path.isfile(gds_file):
        continue

    mtime = os.path.getmtime(gds_file)
    if mtime <= last_mtime:
        continue
    last_mtime = mtime

    # Reuse current view when possible, otherwise load a fresh layout.
    try:
        view = mw.current_view()
        if view is None:
            cv = mw.load_layout(gds_file, opts, "", 1)
            view = mw.current_view()
            cv_index = cv.index()
        else:
            view.reload_layout(cv_index)
        if show_all:
            view.show_all_cells()
    except Exception:
        # Last-resort recovery path if reload API shape differs by version.
        cv = mw.load_layout(gds_file, opts, "", 0)
        view = mw.current_view()
        cv_index = cv.index()
