"""COMSOL transformations returning new geometry objects.

Rotate is implemented in COMSOL and KLayout. Other transforms are reserved.
Lengths are in um, angles in degrees, and positive angles turn anticlockwise.
"""

from .geometry import GeometryObject
from .parameters import comsol_expression, evaluate
from .vertices import Vertices, coordinate_pair

__all__ = ["Array", "Copy", "Mirror", "Move", "Rotate", "Scale"]


class Rotate(GeometryObject):
    """Rotate a feature around ``origin`` without modifying its parameters.

    ``keep=False`` consumes the input geometry, as COMSOL does by default.
    Use ``keep=True`` to retain the input for display or later transformations.
    This first implementation accepts one input and one rotation angle.
    The angle and origin coordinates accept parameters or expressions.
    """

    tag_prefix = "rot"

    def __init__(self, target, *, angle=0, origin=(0, 0), keep=False,
                 selections=(), propagate_selections=True):
        if not isinstance(target, GeometryObject):
            raise TypeError("Rotate.target must be a geometry object.")
        super().__init__(target.project, target.layer, selections=selections)
        self.inputs = (target,)
        self.angle = angle
        self.origin = origin if isinstance(origin, Vertices) else tuple(origin)
        self.keep = keep
        self.propagate_selections = propagate_selections
        self.validate()
        self.project.add(self)

    @property
    def target(self):
        return self.inputs[0]

    def validate(self):
        evaluate(self.angle, "deg")
        coordinate_pair(self.origin)
        if not isinstance(self.keep, bool):
            raise ValueError("Rotate.keep must be a boolean.")
        if not isinstance(self.propagate_selections, bool):
            raise ValueError("Rotate.propagate_selections must be a boolean.")

    def parameter_values(self):
        return (self.angle, *coordinate_pair(self.origin))

    def to_comsol(self, workplane_geometry, tag):
        if tag not in list(workplane_geometry.feature().tags()):
            workplane_geometry.create(tag, "Rotate")
        feature = workplane_geometry.feature(tag)
        feature.label(f"{self.layer.name}: {tag}")
        feature.selection("input").set([self.target.tag])
        feature.set("rot", comsol_expression(self.angle, "deg"))
        feature.set("pos", [comsol_expression(value, "um") for value in coordinate_pair(self.origin)])
        feature.set("keep", "on" if self.keep else "off")
        feature.set("propagatesel", "on" if self.propagate_selections else "off")

    def to_klayout(self):
        import klayout.db as kdb

        x, y = (evaluate(value, "um") for value in coordinate_pair(self.origin))
        transform = (kdb.DCplxTrans(x, y)
                     * kdb.DCplxTrans(1, evaluate(self.angle, "deg"), False, 0, 0)
                     * kdb.DCplxTrans(-x, -y))
        return self.target.to_klayout().transformed(transform)


class _PendingTransform(GeometryObject):
    def __init__(self, *args, **kwargs):
        raise NotImplementedError(f"{type(self).__name__} is not implemented yet.")


class Array(_PendingTransform):
    """Reserved for COMSOL Array and its GDS representation."""


class Copy(_PendingTransform):
    """Reserved for COMSOL Copy and its GDS representation."""


class Mirror(_PendingTransform):
    """Reserved for COMSOL Mirror and its GDS representation."""


class Move(_PendingTransform):
    """Reserved for COMSOL Move and its GDS representation."""


class Scale(_PendingTransform):
    """Reserved for COMSOL Scale and its GDS representation."""
