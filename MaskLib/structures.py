import sympy as sp
import numpy as np
from typing import Union, Tuple, List, NamedTuple, Optional
from dataclasses import dataclass, asdict

from HFSSdrawpy import Body, Entity

from utils import get_square_x_size, get_frame_size


def isinstance_namedtuple(obj) -> bool:
    return (
        isinstance(obj, tuple) and hasattr(obj, "_asdict") and hasattr(obj, "_fields")
    )


class PhononicCrystal_params(NamedTuple):
    """Geometry of the phononic crystal"""

    bridge_width: Union[sp.Symbol, float]
    pad_radius: Union[sp.Symbol, float]

    structure_a: Union[sp.Symbol, float]

    @property
    def fillet_radius(self):
        return self.pad_radius - self.bridge_width


@dataclass
class MembraneSquareParams:
    """Parameters that define the square of the membrane"""

    only_triangles: bool = True
    correction: Union[sp.Symbol, float] = 0.0
    offset: Tuple[Union[sp.Symbol, float], Union[sp.Symbol, float]] = (0, 0)
    frame_size: Optional[Tuple[Union[sp.Symbol, float], Union[sp.Symbol, float]]] = None

    def _asdict(self):
        return {
            k: (v if not isinstance_namedtuple(v) else v._asdict())
            for k, v in asdict(self).items()
        }


@dataclass
class MembraneGeom:
    """Parameters that define the phononic crystal geometry"""

    pnc: PhononicCrystal_params
    pnc_center: PhononicCrystal_params
    structure_a: Union[sp.Symbol, float]
    center_pad_radius: Union[sp.Symbol, float]
    y_size: int
    x_size: Optional[int] = None
    geometry_type: str = ""
    center_offset: Tuple[float, float] = (0, 0)

    def _asdict(self):
        return {
            k: (v if not isinstance_namedtuple(v) else v._asdict())
            for k, v in asdict(self).items()
        }


class Membrane(NamedTuple):
    """Parameters of the output membrane"""

    membrane_geom: MembraneGeom
    membrane_square_params: MembraneSquareParams
    entity: Entity


def poly_simple_triangle(offcenter, triangle_size):
    """
                       /|  ^
                   /--- |  |
                /--     |  |
            /---        |  |
        . -             |  |  triangle_size
            ---         |  |
                --      |  |
    <--->          ---  |  |
    offcenter          --  v

    """
    triangle_h = triangle_size * np.sqrt(3) / 2
    return [
        [offcenter, 0],
        [offcenter + triangle_h, -triangle_size / 2],
        [offcenter + triangle_h, triangle_size / 2],
    ]


def draw_lotus_unit_cell(
    body: Body,
    pnc_params: PhononicCrystal_params,
    name: str,
    layer: int,
    onlyTriangles: bool = True,
) -> Entity:
    """Create a phononic crystal unit cell with structure_a and pnc params."""
    six_angles = np.linspace(0, 5, 6) * np.pi / 3
    triangle_size = pnc_params.structure_a - pnc_params.bridge_width * np.sqrt(3)

    name_index = 0
    united_triangles: List[Entity] = []
    for i in range(2):  # [0, 3, 1, 2]:
        with body([0, 0], [np.cos(six_angles[i]), np.sin(six_angles[i])]):
            name_index += 1
            triangle_to_copy = body.polyline(
                poly_simple_triangle(pnc_params.bridge_width, triangle_size),
                layer=layer,
                name=f"{body.name}_{name}_poly_base{name_index}",
            )

            triangle_to_copy.fillet(pnc_params.fillet_radius)
            name_index += 1

        united_triangles.append(triangle_to_copy)

    united_triangles[0].unite(united_triangles[1:])

    if onlyTriangles:
        return united_triangles[0]
    else:
        pnc_temp = PhononicCrystal_params(bridge_width=0, pad_radius=0, structure_a=0)
        triangle_size = pnc_params.structure_a - pnc_temp.bridge_width * np.sqrt(3)

        name_index = 0
        triangle_mask: List[Entity] = []
        for i in range(2):  # [0, 3, 1, 2]:
            with body([0, 0], [np.cos(six_angles[i]), np.sin(six_angles[i])]):
                name_index += 1
                triangle_to_copy = body.polyline(
                    poly_simple_triangle(pnc_temp.bridge_width, triangle_size),
                    layer=layer,
                    name=f"{body.name}_{name}_poly_base{name_index}",
                )

                # triangle_to_copy.fillet(pnc_temp.fillet_radius)
                name_index += 1

            triangle_mask.append(triangle_to_copy)

        triangle_mask[0].unite(triangle_mask[1:])
        triangle_mask[0].subtract(united_triangles[0])
        return triangle_mask[0]


def draw_half_lotus_unit_cell(
    body: Body,
    pnc_params: PhononicCrystal_params,
    start_at: str,
    name: str,
    layer: int,
    onlyTriangles: bool = True,
) -> Entity:
    """Create a phononic crystal unit cell with structure_a and pnc params."""
    six_angles = np.linspace(0, 5, 6) * np.pi / 3
    triangle_size = pnc_params.structure_a - pnc_params.bridge_width * np.sqrt(3)

    name_index = 0
    united_triangles: List[Entity] = []

    if start_at == "Top":
        ind = 1
    elif start_at == "Bottom":
        ind = 0
    for i in range(ind, ind + 1):  # [0, 3, 1, 2]:
        with body([0, 0], [np.cos(six_angles[i]), np.sin(six_angles[i])]):
            name_index += 1
            triangle_to_copy = body.polyline(
                poly_simple_triangle(pnc_params.bridge_width, triangle_size),
                layer=layer,
                name=f"{body.name}_{name}_poly_base{name_index}",
            )

            triangle_to_copy.fillet(pnc_params.fillet_radius)
            name_index += 1

        united_triangles.append(triangle_to_copy)

    united_triangles[0].unite(united_triangles[1:])

    if onlyTriangles:
        return united_triangles[0]
    else:
        pnc_temp = PhononicCrystal_params(bridge_width=0, pad_radius=0, structure_a=0)
        triangle_size = pnc_params.structure_a - pnc_temp.bridge_width * np.sqrt(3)

        name_index = 0
        triangle_mask: List[Entity] = []
        for i in range(ind, ind + 1):  # [0, 3, 1, 2]:
            with body([0, 0], [np.cos(six_angles[i]), np.sin(six_angles[i])]):
                name_index += 1
                triangle_to_copy = body.polyline(
                    poly_simple_triangle(pnc_temp.bridge_width, triangle_size),
                    layer=layer,
                    name=f"{body.name}_{name}_poly_base{name_index}",
                )

                # triangle_to_copy.fillet(pnc_temp.fillet_radius)
                name_index += 1

            triangle_mask.append(triangle_to_copy)

        triangle_mask[0].unite(triangle_mask[1:])
        triangle_mask[0].subtract(united_triangles[0])
        return triangle_mask[0]


def create_pnc_structure(
    body: Body,
    structure_a: sp.Symbol,
    pnc: PhononicCrystal_params,
    xy_sizes: Tuple[int, int],
    layer: int,
) -> Entity:
    """Create a phononic crystal structure with structure_a and pnc params. xy_sizes=(x_size, y_size) gives the number of elements in each direction.
    For each angle: create sample triangle in the center with right fillet to copy, and then go though all triangles_pos list and duplicate_along_line if right angle
    """
    six_angles = np.linspace(0, 5, 6) * np.pi / 3
    triangle_size = structure_a - pnc.bridge_width * np.sqrt(3)

    name_index = 0
    print("copying triangles")
    united_triangles_line: List[Entity] = []
    vec_y = [0, structure_a]
    border_triangles: List[Entity] = []
    for i in range(4):  # [0, 3, 1, 2]:
        with body([0, 0], [np.cos(six_angles[i]), np.sin(six_angles[i])]):
            name_index += 1
            triangle_to_copy = body.polyline(
                poly_simple_triangle(pnc.bridge_width, triangle_size),
                layer=layer,
                name=f"poly_base{name_index}",
            )

            # triangle_to_copy.fillet(pnc.fillet_radius)
            name_index += 1

        vec_x = [structure_a * np.sqrt(3), 0, 0]
        triangles: List[Entity] = triangle_to_copy.duplicate_along_line(vec_x, xy_sizes[0] - 1)  # type: ignore
        triangle_to_copy.unite(triangles)
        united_triangles_line.append(triangle_to_copy)

        if i in [0, 3]:
            border_triangle: Entity = body.unite(triangle_to_copy.duplicate_along_line([vec_y[0], vec_y[1] * xy_sizes[1]]))  # type: ignore
            border_triangle.rename(f"border_{i}")
            border_triangles.append(border_triangle)

    united_triangles_line[0].unite(united_triangles_line[1:])
    united_triangles_line_all_angles = united_triangles_line[0]

    triangles: List[Entity] = united_triangles_line_all_angles.duplicate_along_line(vec_y, xy_sizes[1] - 1)  # type: ignore
    united_triangles_line_all_angles.unite(triangles)
    triangles_united = united_triangles_line_all_angles
    triangles_united.unite(border_triangles)

    triangles_united.translate(
        [
            -structure_a * np.sqrt(3) * (xy_sizes[0] - 1) / 2,
            -(structure_a * (xy_sizes[1] / 2)),
            0,
        ]
    )
    return triangles_united


def draw_lotuc_center(
    body: Body,
    structure_a: sp.Symbol,
    center_pad_radius: sp.Symbol,
    pnc: PhononicCrystal_params,
    pnc_center: PhononicCrystal_params,
    layer: int,
) -> List[Entity]:
    """Creating the central lotus"""

    rhombuses: List[Entity] = []
    six_angles = np.linspace(0, 5, 6) * np.pi / 3
    bridge_width = pnc.bridge_width
    bridge_width_center = pnc_center.bridge_width

    rhombus_angle_radius = pnc_center.fillet_radius
    rhombus_angle_radius_center = center_pad_radius - pnc_center.bridge_width

    for i in range(6):
        with body([0, 0], [np.cos(six_angles[i]), np.sin(six_angles[i])]):
            rhombus = body.polyline(
                [
                    [bridge_width_center, 0],
                    [
                        structure_a * np.sqrt(3) / 2,
                        (structure_a * np.sqrt(3) - bridge_width - bridge_width_center)
                        / np.sqrt(3)
                        / 2,
                    ],
                    [structure_a * np.sqrt(3) - bridge_width, 0],
                    [
                        structure_a * np.sqrt(3) / 2,
                        -(structure_a * np.sqrt(3) - bridge_width - bridge_width_center)
                        / np.sqrt(3)
                        / 2,
                    ],
                ],
                name=f"central_lotus_triangle{i}",
                layer=layer,
            )
        rhombus.fillet(
            [rhombus_angle_radius_center, rhombus_angle_radius], [[0], [1, 2, 3]]
        )
        # rhombus.fillet(rhombus_angle_radius_center)
        rhombuses.append(rhombus)

        with body(
            [0, 0],
            [np.cos(six_angles[i] + np.pi / 6), np.sin(six_angles[i] + np.pi / 6)],
        ):
            rhombus = body.polyline(
                [
                    [structure_a + bridge_width / np.sqrt(3), 0],
                    [
                        3 / 2 * structure_a,
                        (structure_a * np.sqrt(3) / 2 - bridge_width),
                    ],
                    [2 * structure_a - bridge_width / np.sqrt(3), 0],
                    [
                        3 / 2 * structure_a,
                        -(structure_a * np.sqrt(3) / 2 - bridge_width),
                    ],
                ],
                name=f"central_lotus_triangle_back{i}",
                layer=layer,
            )
        # rhombus.fillet([rhombus_angle_radius_center, rhombus_angle_radius], [[0],[1,2,3]])
        rhombus.fillet(rhombus_angle_radius)
        rhombuses.append(rhombus)
    return rhombuses


def draw_lotus_membrane(
    body: Body,
    membrane_geom: MembraneGeom,
    layer: int,
    membrane_square_params: MembraneSquareParams = MembraneSquareParams(),
) -> Membrane:
    """Create membrane on the chip (given by variable `self` of Body class)

    Args:
        self (Body): Body class from HFSSdrawpy
        structure_r (sp.core.symbol.Symbol): radius of the triangle inscribed in the free space between the triangles (if they were with fillet 0)
        triangle_size (sp.core.symbol.Symbol): size of the triangle sides (if triangles were with fillet 0)
        triangle_angle_radius (sp.core.symbol.Symbol): fillet radius of the triangles
        rhombus_angle_radius (sp.core.symbol.Symbol): fillet radius of the rhombus
        y_size (int): number of structures in Y direction
        x_size (int): number of structures in X direction. Defaults to be a square with y_size
        frame_size (Tuple[float, float], optional): Explicitly sets size of the frame. By defaults calculated given y_size.
        layer (int, optional): Layer where to draw. Defaults to TRACK_MEMBRANE.
        onlyTriangles (bool): If you only need to output triangle and not substract them from square. Defaults to False.
        offset (tuple(2), optional): Offset that adds to default frame_size. Given in the structure size units, i.e. offset=-1 removes half of the honeycomb structure. Defaults to (0,0).
        correction (float or sp.Symbol [um], optional): correction in structure_r and triangle_size #TODO

    Returns:
        Dict: Dict_keys{
            "membrane": hole structure with triangles subtracted,
            "triangles": triangles,
            "membrane_size": (membrane_size_x, membrane_size_y)}
    """

    structure_a = membrane_geom.structure_a

    # Appling corrections
    pnc = PhononicCrystal_params(
        bridge_width=membrane_geom.pnc.bridge_width + membrane_square_params.correction,
        pad_radius=membrane_geom.pnc.pad_radius + membrane_square_params.correction / 2,
        structure_a=structure_a,
    )

    pnc_center = PhononicCrystal_params(
        bridge_width=membrane_geom.pnc_center.bridge_width
        + membrane_square_params.correction,
        pad_radius=membrane_geom.pnc_center.pad_radius
        + membrane_square_params.correction / 2,
        structure_a=structure_a,
    )

    # Extract some variable for easier accessing
    frame_size = membrane_square_params.frame_size
    only_triangles = membrane_square_params.only_triangles
    offset = membrane_square_params.offset

    # Set x_size to be a closer as possible to square with y_size
    if membrane_geom.x_size is None:
        membrane_geom.x_size = get_square_x_size(membrane_geom.y_size)
        print(
            f"x_size automatically set to {membrane_geom.x_size} to be a square membrane with y_size={membrane_geom.y_size}"
        )

    # Necessary conditions for obtaining a proper structure
    if membrane_geom.y_size % 2 == membrane_geom.x_size % 2:
        raise ValueError(
            f"One of the x_size and y_size should be odd other should be even. In your case x_size={membrane_geom.x_size} and y_size={membrane_geom.y_size}"
        )

    # Calculate the size of the frame around the structure
    if frame_size is None:
        membrane_size_x, membrane_size_y = get_frame_size(
            structure_a, (membrane_geom.x_size, membrane_geom.y_size), offset
        )
        membrane_square_params.frame_size = (membrane_size_x, membrane_size_y)
    else:
        membrane_size_x, membrane_size_y = frame_size

    # Create pnc structure
    triangles_united = create_pnc_structure(
        body=body,
        structure_a=structure_a,
        pnc=pnc,
        xy_sizes=(membrane_geom.x_size, membrane_geom.y_size),
        layer=layer,
    )

    triangles_united.fillet(pnc.pad_radius - pnc_center.bridge_width)
    # triangles_united.fillet(pnc.fillet_radius)

    square_around_pnc = body.rect(
        [-(membrane_size_x / 2), -(membrane_size_y / 2)],
        [membrane_size_x, membrane_size_y],
        layer=layer,
        name="square_around_pnc",
    )
    frame_around_pnc = body.rect(
        [-(membrane_size_x), -(membrane_size_y)],
        [membrane_size_x * 2, membrane_size_y * 2],
        layer=layer,
        name="frame_around_pnc",
    )

    frame_around_pnc.subtract(square_around_pnc)
    triangles_united.subtract(frame_around_pnc)

    # Remove center for the defect
    center_to_remove = body.polyline(
        [
            [-structure_a * np.sqrt(3), structure_a],
            [0, structure_a * 2],
            [structure_a * np.sqrt(3), structure_a],
            [structure_a * np.sqrt(3), -structure_a],
            [0, -(structure_a * 2)],
            [-structure_a * np.sqrt(3), -structure_a],
        ],
        layer=layer,
        name="center_to_remove",
    )
    triangles_united.subtract(center_to_remove)

    # Create center
    rhombuses = draw_lotuc_center(
        body=body,
        structure_a=structure_a,
        center_pad_radius=membrane_geom.center_pad_radius,
        pnc=pnc,
        pnc_center=pnc_center,
        layer=layer,
    )

    # Unite center and pnc structure
    triangles_united.unite(rhombuses)

    # If only return the triangles. needed for mask generation
    if only_triangles:
        return Membrane(
            membrane_geom=membrane_geom,
            membrane_square_params=membrane_square_params,
            entity=triangles_united,
        )

    # Creating square around the membrane
    membrane = body.rect(
        [-(membrane_size_x / 2), -(membrane_size_y / 2)],
        [membrane_size_x, membrane_size_y],
        layer=layer,
        name="SI_membrane",
    )
    membrane.subtract(triangles_united)

    return Membrane(
        membrane_geom=membrane_geom,
        membrane_square_params=membrane_square_params,
        entity=membrane,
    )
