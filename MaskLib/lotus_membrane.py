import numpy as np

from HFSSdrawpy import Body, Modeler

from utils import save_gds, parse_entry, get_frame_size, save_svg
from structures import (
    draw_lotus_unit_cell,
    draw_half_lotus_unit_cell,
    PhononicCrystal_params,
    MembraneGeom,
    MembraneSquareParams,
    draw_lotus_membrane,
)
from layers import FRONTSIDE, SIN_CHIP

onlyTriangles = False

pm = Modeler("gds")
pm.is_mask = True
pm.is_litho = False
name = "lotus"
body = Body(pm, "membrane")
save_as_svg = True

chip_width = parse_entry("6 mm")
chip_height = parse_entry("6 mm")

# --- Parameters --- #
bridge_width = parse_entry("5 um")
pad_radius = parse_entry("11 um")

triangle_angle_radius = parse_entry("5 um")
rhombus_angle_radius = parse_entry("7 um")

center_pad_radius = parse_entry("13 um")
bridge_width_center = parse_entry("5 um")

structure_a = parse_entry("45 um")
frame_size = parse_entry(["750 um", "700 um"])
# onlyTriangles = True
offset = (-0.25, -0.8)
geometry_type = "l2"
coordinates = None
membrane_displacement = (0, 0)
identifier = None

correction = parse_entry("0 um")  # "0.8 um")

y_size = 17
membrane_params = MembraneSquareParams(
    only_triangles=onlyTriangles, offset=offset, correction=correction
)

membrane_geom = MembraneGeom(
    pnc=PhononicCrystal_params(
        bridge_width=bridge_width, pad_radius=11e-6, structure_a=structure_a
    ),
    pnc_center=PhononicCrystal_params(
        bridge_width=bridge_width, pad_radius=11e-6, structure_a=structure_a
    ),
    structure_a=structure_a,
    center_pad_radius=center_pad_radius,
    y_size=y_size,
)

memb = draw_lotus_membrane(
    body,
    membrane_geom,
    layer=FRONTSIDE,
    membrane_square_params=membrane_params,
)

if body.mode == "gds" and not save_as_svg:
    save_gds(body, name, "pnc_membranes/drawn_files/")
elif body.mode == "gds" and save_as_svg:

    membrane_size_x, membrane_size_y = get_frame_size(
        structure_a, (membrane_geom.x_size, membrane_geom.y_size), offset
    )
    square_under_pnc = body.rect(
        [-(membrane_size_x / 2), -(membrane_size_y / 2)],
        [membrane_size_x, membrane_size_y],
        layer=3,
        name="square_around_pnc",
    )
    square_around_pnc = body.rect(
        [-membrane_size_x / 2 - 1e-6, -membrane_size_y / 2 - 1e-6],
        [membrane_size_x + 2e-6, membrane_size_y + 2e-6],
        layer=FRONTSIDE,
        name="square_around_pnc",
    )

    frame_around_pnc = body.rect(
        [-membrane_size_x / 2 - 100e-6, -membrane_size_y / 2 - 100e-6],
        [membrane_size_x + 200e-6, membrane_size_y + 200e-6],
        layer=SIN_CHIP,
        name="frame_around_pnc",
    )

    frame_around_pnc.subtract(square_around_pnc, keep_originals=True)
    square_around_pnc.subtract(square_under_pnc, keep_originals=True)

    scale_bar = body.rect(
        [-membrane_size_x / 2, -membrane_size_y / 2 - 70e-6],
        ["200 um", "10 um"],
        name="scale_bar",
        layer=2,
    )
    body.text(
        [-membrane_size_x / 2 + 100e-6, -membrane_size_y / 2 - 50e-6],
        25e-6,
        "0.2 mm",
        name="scale",
        layer=2,
    )

    save_svg(
        body,
        name,
        "pnc_membranes/drawn_files/",
        layer_colors={
            1: "rgb(57, 11, 175)",
            2: "rgb(0, 0, 0)",
            3: "rgb(0, 0, 0)",
            13: "rgb(221, 225, 6)",
        },
        scale=0.5e7,
    )
