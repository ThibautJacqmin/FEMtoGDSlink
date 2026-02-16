"""MATLAB-safe bridge for JPype-backed COMSOL objects from the mph package."""

from __future__ import annotations


class JavaHandle:
    """Light wrapper that keeps JPype objects on the Python side."""

    def __init__(self, obj):
        self._obj = obj

    def __getattr__(self, name):
        target = getattr(self._obj, name)
        if callable(target):

            def _call(*args):
                raw_args = [_unwrap(arg) for arg in args]
                result = target(*raw_args)
                return _wrap(result)

            return _call
        return _wrap(target)

    def __str__(self):
        return str(self._obj)

    def __repr__(self):
        return f"JavaHandle({self._obj!r})"


def model_java_handle(model):
    """Return a MATLAB-safe proxy over `mph.Model.java`."""
    return JavaHandle(model.java)


def attach_existing_client(mph_mod, host, port):
    """
    Attach to an already running MPh/JPype client in the current Python process.
    """
    from com.comsol.model.util import ModelUtil as java

    try:
        java.tags()
    except Exception:
        java.connect(str(host), int(port))

    client_cls = mph_mod.Client
    client = client_cls.__new__(client_cls)
    client.version = "attached"
    client.standalone = False
    client.port = int(port)
    client.host = str(host)
    client.java = java
    return client


def _unwrap(value):
    if isinstance(value, JavaHandle):
        return value._obj
    if isinstance(value, list):
        return [_unwrap(item) for item in value]
    if isinstance(value, tuple):
        return tuple(_unwrap(item) for item in value)
    return value


def _wrap(value):
    if value is None:
        return None
    if isinstance(value, JavaHandle):
        return value
    if isinstance(value, (str, bytes, int, float, bool)):
        return value
    if isinstance(value, (list, tuple, dict)):
        return value
    return JavaHandle(value)
