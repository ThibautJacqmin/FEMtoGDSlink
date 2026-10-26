"""Common base for geometrical features."""

from .selection import Selection


class GeometryObject:
    """Common project/layer ownership for geometry objects."""

    def __init__(self, project, layer, *, selections=()):
        if project.layers.get(layer.name) is not layer:
            raise ValueError("The layer must belong to this project.")
        self.project = project
        self.layer = layer
        self.inputs = ()
        self.keep = False
        self.tag = None
        self.selections = tuple(selections)
        self.validate_selections()
        self.selections = tuple(dict.fromkeys(self.selections))

    def validate_selections(self):
        for selection in self.selections:
            if (not isinstance(selection, Selection) or selection.project is not self.project
                    or self.project.selections.get(selection.name) is not selection):
                raise ValueError("Object selections must belong to this project.")

    def rotate(self, *, angle=0, origin=(0, 0), keep=False,
               selections=(), propagate_selections=True):
        """Return a new Rotate feature in the same project and layer."""
        from .transforms import Rotate
        return Rotate(self, angle=angle, origin=origin, keep=keep,
                      selections=selections, propagate_selections=propagate_selections)

    def parameter_values(self):
        """Scalar inputs to inspect for named parameters and dependencies."""
        return ()

    def to_comsol(self, workplane_geometry, tag):
        """Create the feature in the 2D workplane of the project's 3D geometry."""
        raise NotImplementedError

    def to_klayout(self):
        """Return floating geometry in um; the project applies the final GDS grid."""
        raise NotImplementedError
