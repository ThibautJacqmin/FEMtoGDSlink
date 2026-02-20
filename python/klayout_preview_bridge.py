"""Live-reload bridge script for standalone KLayout preview.

This script is launched by `core.GdsModeler.launch_external_preview(...)` using
KLayout's `-rr` option. It opens the provided GDS file in the desktop view and
keeps reloading when the file content changes.

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


def _file_signature(path):
    """Return one high-resolution signature tuple for change detection."""
    try:
        st = os.stat(path)
    except Exception:
        return None

    # Prefer nanosecond precision where available. Include size to catch
    # changes on filesystems with coarse timestamp granularity.
    mtime_ns = getattr(st, "st_mtime_ns", int(st.st_mtime * 1e9))
    ctime_ns = getattr(st, "st_ctime_ns", int(st.st_ctime * 1e9))
    return (int(mtime_ns), int(ctime_ns), int(st.st_size))


# Launch/runtime options injected by GdsModeler.
gds_file = str(globals().get("preview_gds_file", ""))
refresh_ms = max(20, _get_int("preview_refresh_ms", 20))
zoom_fit = _get_bool("preview_zoom_fit", True)
show_all = _get_bool("preview_show_all", True)
ready_file = str(globals().get("preview_ready_file", ""))
# Require this many identical signatures before reloading.
# This avoids reloading while the writer is still flushing a new file.
stable_samples_required = 2

if gds_file == "":
    raise RuntimeError("preview_gds_file is required.")

app = pya.Application.instance()
mw = app.main_window()
if mw is None:
    raise RuntimeError("KLayout preview bridge requires GUI mode.")

# Initial load into current KLayout desktop window.
opts = pya.LoadLayoutOptions()
# Initial load can race with writer startup on some systems.
initial_deadline = time.time() + 2.0
while True:
    try:
        cv = mw.load_layout(gds_file, opts, "", 1)
        break
    except Exception:
        if time.time() >= initial_deadline:
            raise
        app.process_events()
        time.sleep(max(0.05, refresh_ms / 1000.0))
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

# Track file signature state so we only reload settled content updates.
last_applied_sig = _file_signature(gds_file)
pending_sig = last_applied_sig
pending_count = 0

# Main watch loop: keep the GUI responsive and reload on file change.
while True:
    app.process_events()
    time.sleep(refresh_ms / 1000.0)

    if not os.path.isfile(gds_file):
        continue

    sig = _file_signature(gds_file)
    if sig is None:
        continue

    if sig == pending_sig:
        pending_count += 1
    else:
        pending_sig = sig
        pending_count = 1

    if pending_sig == last_applied_sig:
        continue
    if pending_count < stable_samples_required:
        continue

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
        if zoom_fit:
            # Keep camera synced with new content, especially when the
            # initial file was empty and geometry appears later.
            view.zoom_fit()
        last_applied_sig = pending_sig
    except Exception:
        # Last-resort recovery path if reload API shape differs by version.
        # If both reload paths fail, assume we hit an in-flight write and
        # retry on the next loop once the file stabilizes.
        try:
            cv = mw.load_layout(gds_file, opts, "", 0)
            view = mw.current_view()
            cv_index = cv.index()
            if view is not None:
                if show_all:
                    view.show_all_cells()
                if zoom_fit:
                    view.zoom_fit()
            last_applied_sig = pending_sig
        except Exception:
            continue
