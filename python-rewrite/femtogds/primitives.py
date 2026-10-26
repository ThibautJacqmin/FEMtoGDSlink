"""Planar COMSOL primitives. Lengths in um, angles in degrees.

Square is implemented in COMSOL and KLayout. The other classes reserve the
documented primitive names and raise NotImplementedError until implemented.
"""

from math import cos, radians, sin

from .geometry import GeometryObject
from .parameters import comsol_expression, evaluate
from .vertices import Vertices, coordinate_pair

__all__ = ["Circle", "Square", "Rectangle", "CircularArc", "CubicBezier",
           "InterpolationCurve", "LineSegment", "ParametricCurve", "Point",
           "Polygon", "QuadraticBezier", "Ellipse", "BezierPolygon"]


class Square(GeometryObject):
    """A native COMSOL Square and its GDS polygon.

    ``position`` is the centre or lower-left corner, according to ``base``.
    Rotation is about this position, matching COMSOL's Square definition.
    Creation builds immediately only when ``project.live`` is true.
    Dimensions, coordinates and angles accept parameters or expressions.
    """

    tag_prefix = "sq"

    def __init__(self, project, *, layer, side, position=(0, 0),
                 base="center", angle=0, selections=()):
        super().__init__(project, layer, selections=selections)
        self.side = side
        self.position = position if isinstance(position, Vertices) else tuple(position)
        self.angle = angle
        self.base = base
        self.validate()
        project.add(self)

    def validate(self):
        if evaluate(self.side, "um") <= 0:
            raise ValueError("Square.side must be a finite positive length in um.")
        coordinate_pair(self.position)
        evaluate(self.angle, "deg")
        if self.base not in ("center", "corner"):
            raise ValueError("Square.base must be 'center' or 'corner'.")

    def parameter_values(self):
        return (self.side, *coordinate_pair(self.position), self.angle)

    def to_comsol(self, workplane_geometry, tag):
        if tag not in list(workplane_geometry.feature().tags()):
            workplane_geometry.create(tag, "Square")
        feature = workplane_geometry.feature(tag)
        feature.label(f"{self.layer.name}: {tag}")
        feature.set("type", "solid")
        feature.set("base", self.base)
        feature.set("size", comsol_expression(self.side, "um"))
        feature.set("pos", [comsol_expression(value, "um") for value in coordinate_pair(self.position)])
        feature.set("rot", comsol_expression(self.angle, "deg"))

    def to_klayout(self):
        import klayout.db as kdb

        side = evaluate(self.side, "um")
        angle = evaluate(self.angle, "deg")
        start = -side / 2 if self.base == "center" else 0
        end = start + side
        c, s = cos(radians(angle)), sin(radians(angle))
        px, py = (evaluate(value, "um") for value in coordinate_pair(self.position))
        points = [kdb.DPoint(px + c*x - s*y, py + s*x + c*y)
                  for x, y in ((start, start), (end, start), (end, end), (start, end))]
        return kdb.DPolygon(points)


class _PendingPrimitive(GeometryObject):
    def __init__(self, *args, **kwargs):
        raise NotImplementedError(f"{type(self).__name__} is not implemented yet.")


class Circle(_PendingPrimitive):
    """Reserved for COMSOL Circle and its GDS representation."""


class Rectangle(_PendingPrimitive):
    """Reserved for COMSOL Rectangle and its GDS representation."""


class CircularArc(_PendingPrimitive):
    """Reserved for COMSOL CircularArc; curve representation remains to be defined."""


class CubicBezier(_PendingPrimitive):
    """Reserved for COMSOL CubicBezier; curve representation remains to be defined."""


class InterpolationCurve(_PendingPrimitive):
    """Reserved for COMSOL InterpolationCurve."""


class LineSegment(_PendingPrimitive):
    """Reserved for COMSOL LineSegment."""


class ParametricCurve(_PendingPrimitive):
    """Reserved for COMSOL ParametricCurve."""


class Point(_PendingPrimitive):
    """Reserved for COMSOL Point; its GDS representation remains to be defined."""


class Polygon(_PendingPrimitive):
    """Reserved for COMSOL Polygon."""


class QuadraticBezier(_PendingPrimitive):
    """Reserved for COMSOL QuadraticBezier."""


class Ellipse(_PendingPrimitive):
    """Reserved for COMSOL Ellipse."""


class BezierPolygon(_PendingPrimitive):
    """Legacy COMSOL primitive, deprecated by COMSOL since 5.5."""
