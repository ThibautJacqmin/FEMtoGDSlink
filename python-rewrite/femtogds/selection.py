"""Named FEM selections, independent of drawing layers."""


class Selection:
    """Group feature results at one entity level of the final 3D geometry.

    Membership refers to feature outputs, so COMSOL can propagate it through
    later transformations. GDS-only members remain Python metadata and are
    omitted from the COMSOL group. Creating a selection never connects to COMSOL.
    """

    def __init__(self, project, name, *, entity="boundary"):
        if not isinstance(name, str) or not name.strip():
            raise ValueError("A selection needs a nonempty name.")
        if name in project.selections:
            raise ValueError(f"Selection {name!r} already exists.")
        dimensions = {"domain": 3, "boundary": 2, "edge": 1, "point": 0}
        if not isinstance(entity, str) or entity not in dimensions:
            raise ValueError("Selection.entity must be domain, boundary, edge, or point.")
        self.project = project
        self.name = name
        self.entity = entity
        self.dimension = dimensions[entity]
        self.tag = f"sel{len(project.selections) + 1}"
        project.selections[name] = self

    @property
    def members(self):
        """Explicit members; inherited membership is tracked by COMSOL."""
        return tuple(obj for obj in self.project.objects if self in obj.selections)

    def _validate_objects(self, objects):
        from .geometry import GeometryObject

        for obj in objects:
            if (not isinstance(obj, GeometryObject) or obj.project is not self.project
                    or obj not in self.project.objects):
                raise ValueError("Selection members must be registered objects of this project.")

    def add(self, *objects):
        """Add existing primitives or transforms; rebuild immediately in live mode."""
        self._validate_objects(objects)
        changed = False
        for obj in objects:
            if self not in obj.selections:
                obj.selections += (self,)
                changed = True
        if changed and self.project.live:
            self.project.build()
        return self

    def remove(self, *objects):
        """Remove direct membership; upstream selections may still propagate."""
        self._validate_objects(objects)
        changed = False
        for obj in objects:
            if self in obj.selections:
                obj.selections = tuple(group for group in obj.selections if group is not self)
                changed = True
        if changed and self.project.live:
            self.project.build()
        return self

    def to_comsol(self, component):
        """Union the native output selections, without storing entity numbers."""
        from jpype import JArray, JInt, JString

        inputs = []
        # Plane-geometry features have no componentSelection() of their own.
        # The parent WorkPlane exposes their promoted selections in 3D.
        workplane = self.project.workplane
        prefix = f"{self.project.geometry.tag()}_{workplane.tag()}_"
        tags = [str(tag) for tag in workplane.componentSelection()]
        for obj in self.members:
            if not obj.layer.comsol:
                continue
            matches = [tag for tag in tags
                       if tag.startswith(f"{prefix}{obj.tag}_")
                       and component.selection(tag).dim() == self.dimension]
            if not matches:
                raise ValueError(
                    f"Selection {self.name!r}: {type(obj).__name__} {obj.tag} has no "
                    f"{self.entity} selection in the final 3D geometry. "
                    "Planar shapes provide boundaries, edges, and points, not volumes."
                )
            inputs.extend(matches)
        if self.tag not in list(component.selection().tags()):
            component.selection().create(self.tag, "Union")
        selection = component.selection(self.tag)
        selection.label(self.name)
        selection.set("entitydim", JInt(self.dimension))
        # An explicitly typed array also handles an empty group unambiguously.
        selection.set("input", JArray(JString)(list(dict.fromkeys(inputs))))

    def entities(self):
        """Read current COMSOL entity numbers after build(), for inspection only."""
        if self.project.model is None:
            raise RuntimeError("Build this selection in COMSOL before reading its entities.")
        component = self.project.model.java.component("comp1")
        if self.tag not in list(component.selection().tags()):
            raise RuntimeError("Build this selection in COMSOL before reading its entities.")
        return list(component.selection(self.tag).entities())
