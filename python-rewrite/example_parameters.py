"""Named parameters shared by COMSOL and the GDS geometry."""

from femtogds import Project, Parameter, DependentParameter
from femtogds.primitives import Square
from femtogds.transforms import Rotate

# Parameters
width = Parameter(20, "width", unit="um", description="Square side")
gap = Parameter(2, "gap", unit="um")
angle = Parameter(45, "angle", unit="deg")
pitch = DependentParameter(width + 2 * gap, "pitch")

# Project and layer — set comsol=False to work offline
project = Project(output="output/example_parameters")
metal = project.add_layer("metal", comsol=True, gds=True)

# Geometry — keep the parameter objects in dimensions, coordinates and angles
square = Square(project, layer=metal, side=width,
                position=(pitch, 0), angle=angle)
rotated = Rotate(square, angle=angle, keep=True)

# Build and display
project.build()
project.show()

# In the interactive console, try: width.value = 30; project.build()
# pitch and both squares will be recalculated from the same parameters.
