import os
import time

import pya


def _get_bool(name, default):
    raw = globals().get(name, default)
    if isinstance(raw, str):
        return raw.strip().lower() in ("1", "true", "yes", "on")
    return bool(raw)


def _get_int(name, default):
    raw = globals().get(name, default)
    try:
        return int(float(raw))
    except Exception:
        return int(default)


gds_file = str(globals().get("preview_gds_file", ""))
refresh_ms = max(20, _get_int("preview_refresh_ms", 120))
zoom_fit = _get_bool("preview_zoom_fit", True)
show_all = _get_bool("preview_show_all", True)
ready_file = str(globals().get("preview_ready_file", ""))

if gds_file == "":
    raise RuntimeError("preview_gds_file is required.")

app = pya.Application.instance()
mw = app.main_window()
if mw is None:
    raise RuntimeError("KLayout preview bridge requires GUI mode.")

opts = pya.LoadLayoutOptions()
cv = mw.load_layout(gds_file, opts, "", 1)
view = mw.current_view()
cv_index = cv.index()

if view is not None:
    if show_all:
        view.show_all_cells()
    if zoom_fit:
        view.zoom_fit()

if ready_file != "":
    try:
        with open(ready_file, "w", encoding="utf-8") as f:
            f.write("ready\n")
    except Exception:
        pass

last_mtime = -1.0
if os.path.isfile(gds_file):
    last_mtime = os.path.getmtime(gds_file)

while True:
    app.process_events()
    time.sleep(refresh_ms / 1000.0)

    if not os.path.isfile(gds_file):
        continue

    mtime = os.path.getmtime(gds_file)
    if mtime <= last_mtime:
        continue
    last_mtime = mtime

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
        cv = mw.load_layout(gds_file, opts, "", 0)
        view = mw.current_view()
        cv_index = cv.index()
