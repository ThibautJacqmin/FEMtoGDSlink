"""Build the same simple objects in COMSOL and KLayout."""

from math import isfinite
from pathlib import Path
import os
import shutil
import subprocess

from ._comsol import get_client
from .layer import Layer
from .parameters import DependentParameter, Parameter, collect_parameters
from .selection import Selection

_viewers = {}


class Project:
    """Draw in a workplane inside a 3D COMSOL geometry.

    ``live=False`` waits for an explicit build().

    Lengths and ``dbu`` are in um. The default GDS grid is 0.001 um (1 nm).
    Projects reuse one MPh connection within the Python session.
    An existing MPh ``client`` can also be supplied explicitly.
    The project never clears existing COMSOL models or stops the server.
    """

    def __init__(self, *, live=False, output="output/square", dbu=0.001,
                 host="localhost", port=2036, client=None):
        self.live = bool(live)
        self.output = Path(output).resolve()
        self._mph_path = self.output.with_suffix(".mph")
        self.dbu = float(dbu)
        if not isfinite(self.dbu) or self.dbu <= 0:
            raise ValueError("Project.dbu must be a finite positive length in um.")
        self.host, self.port = (client.host, client.port) if client is not None else (host, port)
        self.layers = {}
        self.selections = {}
        self.objects = []
        self._explicit_parameters = []
        self.client = client
        self.model = None
        self.geometry = None
        self.workplane = None
        self.layout = None
        self._gui_processes = _viewers.setdefault((self.output, self.host, self.port), {})

    @property
    def gds_path(self):
        return self.output.with_suffix(".gds")

    @property
    def mph_path(self):
        """Actual saved path; a numbered name is used if another model holds the file."""
        return self._mph_path

    @property
    def parameters(self):
        """Used and explicitly registered parameters, dependencies before dependants.

        The returned dictionary is rebuilt from the current object attributes.
        Change a parameter's value, then call build(), including in live mode.
        """
        return self._parameters_for(self.objects)

    def _parameters_for(self, objects, extra=()):
        values = list(self._explicit_parameters) + list(extra)
        values.extend(value for obj in objects for value in obj.parameter_values())
        return collect_parameters(values)

    def add_parameter(self, parameter):
        """Include a named parameter even when no geometry refers to it yet.

        Dependencies are included too. Registration does not connect to COMSOL;
        the definition is sent at build(), when a COMSOL layer is enabled.
        """
        if not isinstance(parameter, (Parameter, DependentParameter)):
            raise TypeError("add_parameter expects a named Parameter or DependentParameter.")
        self._parameters_for(self.objects, extra=(parameter,))
        parameter.definition  # Validate before changing the registry.
        if parameter not in self._explicit_parameters:
            self._explicit_parameters.append(parameter)
        return parameter

    def add_layer(self, name, *, comsol=True, gds=True,
                  gds_layer=1, gds_datatype=0):
        if name in self.layers:
            raise ValueError(f"Layer {name!r} already exists.")
        layer = Layer(name, comsol, gds, gds_layer, gds_datatype)
        self.layers[name] = layer
        return layer

    def add_selection(self, name, *, entity="boundary"):
        """Create a named FEM group, independent of the drawing layers."""
        return Selection(self, name, entity=entity)

    def add(self, obj):
        if obj.project is not self or self.layers.get(obj.layer.name) is not obj.layer:
            raise ValueError("The object and its layer must belong to this project.")
        if obj in self.objects:
            raise ValueError("This object is already in the project.")
        obj.validate_selections()
        self._final_objects(self.objects + [obj])
        self._parameters_for(self.objects + [obj])
        obj.tag = f"{obj.tag_prefix}{len(self.objects) + 1}"
        self.objects.append(obj)
        if self.live:
            self.build()

    @staticmethod
    def _final_objects(objects):
        """Follow COMSOL's sequence: a transform consumes inputs unless kept."""
        available = set()
        for obj in objects:
            for source in obj.inputs:
                if source not in available:
                    raise ValueError(
                        "Transformation input is missing or already consumed. "
                        "Use keep=True on the earlier transformation to reuse it."
                    )
                if source.project is not obj.project or source.layer is not obj.layer:
                    raise ValueError("A transformation must share its input's project and layer.")
            if not obj.keep:
                available.difference_update(obj.inputs)
            available.add(obj)
        return [obj for obj in objects if obj in available]

    def _connect_comsol(self):
        if self.model is not None:
            return
        self.client = get_client(self.host, self.port, self.client)

        from jpype import JClass
        # Allow the Desktop to finish a short request before our next command.
        self.client.java.setServerBusyHandler(
            JClass("com.comsol.model.util.ServerBusyHandler")(5000))
        self.model = self.client.create(self.output.name)
        # Component (3D) > Geometry (3D) > Work Plane (2D) > planar features.
        component = self.model.java.component().create("comp1", True)
        self.geometry = component.geom().create("geom1", 3)
        self.geometry.lengthUnit("um")
        self.geometry.angularUnit("deg")
        self.workplane = self.geometry.create("wp1", "WorkPlane")
        self.workplane.set("unite", True)
        self.workplane.set("selplaneshow", "on")

    def _build_gds(self):
        import klayout.db as kdb

        layout = kdb.Layout()
        layout.dbu = self.dbu
        cell = layout.create_cell("TOP")
        for obj in self._final_objects(self.objects):
            if obj.layer.gds:
                layer_index = layout.layer(obj.layer.gds_layer, obj.layer.gds_datatype)
                polygon = obj.to_klayout().to_itype(self.dbu)
                if polygon.area() == 0:
                    raise ValueError(
                        f"{type(obj).__name__} is too small for the GDS grid; reduce Project.dbu."
                    )
                cell.shapes(layer_index).insert(polygon)
        # The Desktop reads either the old complete file or the new complete file.
        temporary = self.output.with_name(self.output.name + ".writing.gds")
        layout.write(str(temporary))
        os.replace(temporary, self.gds_path)
        self.layout = layout

    def _save_comsol(self):
        """Export without tying the server model to a file that blocks the next Run."""
        path = self.mph_path
        requested = self.output.with_suffix(".mph")
        number = 2
        while True:
            try:
                self.model.java.save(str(path), True)  # COMSOL's documented save-copy option.
                break
            except Exception as error:
                if "locked by another model" not in str(error).lower():
                    raise
                # Preserve an open model's file. Other save errors remain visible.
                path = requested.with_name(f"{requested.stem}_{number}.mph")
                while path.exists():
                    number += 1
                    path = requested.with_name(f"{requested.stem}_{number}.mph")
                number += 1
        if path != self.mph_path:
            print(f"COMSOL output is in use; saved the new model to {path}")
            self._mph_path = path

    def build(self):
        """Build/save enabled layers; repeated calls do not duplicate features.

        GDS is also produced if COMSOL is unavailable. The COMSOL exception still
        propagates: a GDS file alone must not be mistaken for a complete build.
        Changing object attributes or parameter values requires build() again.
        Python values overwrite this geometry's COMSOL parameter definitions.
        """
        # Check dependencies/names before changing either output or connecting.
        self._parameters_for(self.objects)
        for obj in self.objects:
            obj.validate()
            obj.validate_selections()
        self._final_objects(self.objects)
        comsol_parameters = self._parameters_for(
            obj for obj in self.objects if obj.layer.comsol)
        definitions = [(parameter.name, parameter.definition, parameter.description)
                       for parameter in comsol_parameters.values()]
        self.output.parent.mkdir(parents=True, exist_ok=True)
        if any(layer.gds for layer in self.layers.values()):
            self._build_gds()
        if any(layer.comsol for layer in self.layers.values()):
            self._connect_comsol()
            for name, expression, description in definitions:
                self.model.java.param().set(name, expression, description)
            workplane_geometry = self.workplane.geom()
            for obj in self.objects:
                if obj.layer.comsol:
                    obj.to_comsol(workplane_geometry, obj.tag)
                    feature = workplane_geometry.feature(obj.tag)
                    feature.set("selresult", "on")
                    feature.set("selresultshow", "all")
            self.geometry.run()
            component = self.model.java.component("comp1")
            for selection in self.selections.values():
                selection.to_comsol(component)
            self._save_comsol()
        return self

    def show(self, *, comsol_exe=None, klayout_exe=None):
        """Open Desktop viewers, also before the first square in live mode.

        In COMSOL, select this model once with Import Application from Server.
        KLayout reloads the GDS automatically. Executable paths can be supplied
        explicitly when they are not on PATH or in the defaults below.
        """
        self.output.parent.mkdir(parents=True, exist_ok=True)
        for backend, process in list(self._gui_processes.items()):
            if process.poll() is not None:
                del self._gui_processes[backend]
        if (any(layer.comsol for layer in self.layers.values())
                and self.client is not None and not self.client.port):
            raise ValueError("Shared COMSOL Desktop requires a client connected to a server.")
        if any(layer.gds for layer in self.layers.values()) and "gds" not in self._gui_processes:
            self._build_gds()
            exe = self._executable(klayout_exe, "klayout", r"C:\Program Files\KLayout\klayout_app.exe")
            script = Path(__file__).resolve().parent.parent / "klayout_preview.py"
            self._gui_processes["gds"] = subprocess.Popen(
                [exe, "-rr", str(script), "-rd", f"gds_file={self.gds_path}"])
        if any(layer.comsol for layer in self.layers.values()):
            self._connect_comsol()
            if "comsol" not in self._gui_processes:
                exe = self._executable(comsol_exe, "comsolmphclient",
                                      r"C:\Program Files\COMSOL\COMSOL64\Multiphysics\bin\win64\comsolmphclient.exe")
                self._gui_processes["comsol"] = subprocess.Popen(
                    [exe, "-server", self.host, "-port", str(self.port)])
            print(f"COMSOL model: {self.model.name()} (tag: {self.model.java.tag()})")
            print("Desktop: File > COMSOL Multiphysics Server > Import Application from Server.")
        return self

    @staticmethod
    def _executable(explicit, command, windows_default):
        candidate = str(explicit) if explicit else shutil.which(command)
        if not candidate and os.name == "nt":
            candidate = windows_default
        if not candidate or not Path(candidate).is_file():
            raise FileNotFoundError(f"Specify the path to the {command} Desktop executable.")
        return candidate
