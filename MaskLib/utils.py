import os
from copy import deepcopy
from typing import List, Tuple, Union

import numpy as np
import sympy as sp
import scipy.constants as cst
from matplotlib import pyplot as plt


import yaml
import gdspy
from HFSSdrawpy import Body, Entity, Port
from HFSSdrawpy.parameters import BOND, DEFAULT, GAP, MASK, MESH, RLC, TRACK
from HFSSdrawpy.utils import Vector, parse_entry, val


def create_port(
    body: Body,
    widths=None,
    subnames=None,
    layers=None,
    offsets=0,
    name="port_0",
    is_mesh=True,
):
    """
    Creates a port and draws a small triangle for each element of the port.
    This function does exactly the same thing as the Body method 'port' except
    that if 2 widths are provided and subnames, layers, and offsets are not,
    assumes a CPW port with first track then gap.

    Parameters
    ----------
    widths : float, 'VariableString' or list, optional
        Width of the different elements of the port. If None, assumes the
        creation of a constraint_port. The default is None.
    subnames : str or list, optional
        The cable's parts will be name cablename_subname. If None simply
        numbering the cable parts. The default is None.
    layers : int or list, optional
        Each layer is described by an int that is a python constant that one
        should import. If None, layer is the DEFAULT The default is
        None.
    offsets : float, 'VariableString' or list, optional
        Describes the offset of the cable part wrt the center of the cable.
        The default is 0.
    name : str, optional
        Name of the port.
    is_mesh: Boolean, add a mesh layer when drawing cables.
        You should then add at the end of your design
                                mesh=chip.unite(chip.entities[MESH])
                                mesh.assign_mesh_length('100um')

    Returns
    -------
    'Port'
        Returns a Port object

    """

    widths = parse_entry(widths)
    t_w = widths is not None
    if t_w and isinstance(widths, list) and 2 <= len(widths) <= 3:
        if subnames is None and layers is None:
            subnames = ["track", "gap"]
            layers = [TRACK, GAP]
            offsets = [0, 0]

            if len(widths) == 3:
                subnames += ["mesh"]
                layers += [MESH]
                offsets += [0]

        if len(widths) == 2:
            if is_mesh:
                subnames += ["mesh"]
                layers += [MESH]
                offsets += [0]
                widths += [widths[1]]

            if is_mesh == "test":
                subnames += ["mesh1", "mesh2", "mesh3", "mesh4"]
                layers += [MESH, MESH, MESH, MESH, MESH]
                offsets += [
                    -widths[0] / 2,
                    +widths[0] / 2,
                    -widths[1] / 2,
                    +widths[1] / 2,
                ]
                widths += [
                    (widths[1] - widths[0]) / 4,
                    (widths[1] - widths[0]) / 4,
                    (widths[1] - widths[0]) / 4,
                    (widths[1] - widths[0]) / 4,
                ]

        if body.is_mask:
            body.rect_center(
                [0, 0],
                [2 * body.gap_mask, widths[1] + 2 * body.gap_mask],
                layer=MASK,
                name=name + "_mask_0",
            )

    (port,) = body.port(
        widths=widths,
        subnames=subnames,
        layers=layers,
        offsets=offsets,
        name=name,
    )
    return [port]


def draw_end_cable(
    body: Body,
    track: str,
    gap: str,
    typeEnd: str = "open",
    fillet: str = None,
    R: str = "50ohm",
    L: str = 0,
    C: str = 0,
    name: str = "end_cable_0",
    mesh: str = None,
) -> List[Port]:
    """

    typeEnd='open'
                +---------+
       gap|     |         |
                |         |
                +--+      |
       track|   |  |      |
                +--+      |
                |         |
       gap|     |         |
                +---------+
                track/2 gap

     typeEnd = 'RLC'
                +----+
       gap|     |    |
                |    |
                +----+
       track|   |    | (RLC)
                +----+
                |    |
       gap|     |    |
                +----+
                track

      typeEnd = 'short'
                +
       gap|     |
                |
                +
       track|   |
                +
                |
       gap|     |
                +

     typeEnd = 'lumped_port'
                +----+
       gap|     |    |
                |    |
                +----+
       track|   |    | (port)
                +----+
                |    |
       gap|     |    |
                +----+
                track

    """
    track, gap = parse_entry(track, gap)
    if typeEnd == "open":
        _gap = gap
        _track2 = track / 2
        _layer = TRACK
    elif typeEnd == "short":
        _gap = 0
        _track2 = 0
        _layer = TRACK
    elif typeEnd == "RLC" or typeEnd == "lumped_port":
        _gap = 0
        _track2 = track
        _layer = RLC
    cutout_size = Vector([_track2 + _gap, track + 2 * gap])

    if cutout_size[0] != 0:
        _cutout = body.rect_center(
            [(_gap - _track2) / 2, 0],
            cutout_size,
            layer=GAP,
            name=name + "_cutout",
        )

    if _track2 != 0:
        _track = body.rect_center(
            [-_track2 / 2, 0],
            [_track2, track],
            name=name + "_track",
            layer=_layer,
        )

        _track_mesh = body.rect_center(
            [(_track2 + _gap) / 2 - _track2, 0],
            [_track2 + _gap, track + 2 * gap],
            name=name + "_track",
            layer=MESH,
        )
        _track_mesh.assign_mesh_length(track / 2)

    if typeEnd == "open" and fillet is not None:
        fillet = parse_entry(fillet)
        _track.fillet(fillet, [1, 2])
        _cutout.fillet(fillet, [1, 2])
    if typeEnd == "RLC":
        points = [(-_track2, 0), (0, 0)]
        _track.assign_lumped_RLC(points, (R, L, C))
        body.polyline(points, closed=False, layer=DEFAULT, name=name + "_line")
    if typeEnd == "lumped_port":
        points = [(-_track2, 0), (0, 0)]
        _track.assign_lumped_port(points, name=name)
        body.polyline(points, closed=False, layer=DEFAULT, name=name + "_line")
    if body.pm.is_mask:
        body.rect_center(
            [(_gap - _track2) / 2, 0],
            [
                cutout_size[0] + track + body.gap_mask,
                cutout_size[1] + track + body.gap_mask,
            ],
            layer=MASK,
            name=name + "_mask",
        )

    with body([-_track2, 0], [-1, 0]):
        widths = [track, 2 * gap + track]
        if mesh is not None:
            mesh = parse_entry(mesh)
            widths.append(mesh)

        (port,) = create_port(body, widths, name=name + "_1")

    return [port]


def _draw_one_mark(
    body: Body,
    style,
    size="default",
    suffix=None,
    writing=False,
    layer=None,
    islayer63=False,
    name="mark_0",
):
    """
    Draws one alignment mark

    Parameters
    ----------
    style     : str, 'butterfly' or 'double_butterfly' or 'cross' or
                'fancy_cross'
    size      : str, each style comes with a 'default' size
    suffix    : str, to be appended at the end of the entity name
    writing      : bool, whether or not to write suffix below the alignment mark
    layer     : int, for the 'butterfly' style, if no layer is specified then
                GAP layer is assumed
    islayer63 : bool, adds layer63 squares for e-beam if True
                only available with 'cross' type

               butterfly          cross           qcross         fancy_cross
         ^   +-----------+         +-+              -+              +-+
         |    ++       ++          +-+              -+           +  +-+  +
         |     ++     ++            |               |             +  |  +
         |      ++   ++       +-+   |   +-+         |   +-+    ++  + | +  ++
    size |       ++ ++        |-----------|         ------|    |-----------|
         |      ++   ++       +-+   |   +-+                    ++  + | +  ++
         |     ++     ++            |                             +  |  +
         |    ++       ++          +-+                           +  +-+  +
         v   +-----------+         +-+                              +-+



    """
    mark_names = [
        "double_butterfly",
        "butterfly",
        "cross",
        "qcross",
        "fancy_cross",
        "KOH_cross",
    ]
    if style not in mark_names:
        raise ValueError(
            "Choose a style among butterfly, cross,\
                          fancy_cross or double_butterfly"
        )
    elif style == "butterfly" and size == "default":
        size = "20um"
    elif style == "cross" and size == "default":
        size = "10um"
    elif style == "qcross" and size == "default":
        size = "10um"
    elif style == "fancy_cross" and size == "default":
        size = "100um"
    elif style == "KOH_cross" and size == "default":
        size = "100um"

    size = parse_entry(size)
    name = name + "_" + style
    if suffix:
        name = name + "_" + suffix

    if style == "butterfly":
        if layer is None:
            layer = GAP
        mark = []
        raw_points = [(0, 0), (size / 4, size / 8), (size / 4, -size / 8)]
        mark.append(body.polyline(raw_points, layer=layer, name=name))
        raw_points = [(0, 0), (-size / 4, +size / 8), (-size / 4, -size / 8)]
        mark.append(body.polyline(raw_points, layer=layer, name=name + "_bis"))
        mark[0].unite(mark)

    if style == "double_butterfly":
        if layer is None:
            layer = GAP
        mark = []
        raw_points = [(0, 0), (size / 4, size / 8), (size / 4, -size / 8)]
        mark.append(body.polyline(raw_points, layer=layer, name=name))
        raw_points = [(0, 0), (-size / 4, +size / 8), (-size / 4, -size / 8)]
        mark.append(body.polyline(raw_points, layer=layer, name=name + "_2"))
        raw_points = [(0, 0), (-size / 8, +size / 4), (+size / 8, +size / 4)]
        mark.append(body.polyline(raw_points, layer=layer, name=name + "_3"))
        raw_points = [(0, 0), (-size / 8, -size / 4), (+size / 8, -size / 4)]
        mark.append(body.polyline(raw_points, layer=layer, name=name + "_4"))

        mark[0].unite(mark)

    elif style == "cross":
        # the cross style with default size requires 1e-8 TOLERANCE
        # in the gds_modeler.py file
        w_thin, l_thin = size / 100, size / 2.5
        w_large, l_large = size / 10, size / 3.2
        w_square = 1.2 * size
        mark, square = [], []
        mark.append(
            body.rect(
                [-l_thin / 2, -w_thin / 2],
                [l_thin, w_thin],
                layer=layer,
                name=name + "_thin_x",
            )
        )
        mark.append(
            body.rect(
                [-w_thin / 2, -l_thin / 2],
                [w_thin, l_thin],
                layer=layer,
                name=name + "_thin_y",
            )
        )
        mark.append(
            body.rect(
                [+l_thin / 2, -w_large / 2],
                [l_large, w_large],
                layer=layer,
                name=name + "_large_right",
            )
        )
        mark.append(
            body.rect(
                [-l_thin / 2, -w_large / 2],
                [-l_large, w_large],
                layer=layer,
                name=name + "_large_left",
            )
        )
        mark.append(
            body.rect(
                [-w_large / 2, +l_thin / 2],
                [w_large, l_large],
                layer=layer,
                name=name + "_large_top",
            )
        )
        mark.append(
            body.rect(
                [-w_large / 2, -l_thin / 2],
                [w_large, -l_large],
                layer=layer,
                name=name + "_large_bot",
            )
        )
        mark[0].unite(mark)

        if islayer63:
            square.append(
                body.rect_center(
                    [0, 0], [w_square, w_square], layer=63, name=name + "_63"
                )
            )

    elif style == "qcross":
        # the cross style with default size requires 1e-8 TOLERANCE
        # in the gds_modeler.py file
        w_thin, l_thin = size / 100, size / 2.5
        w_large, l_large = size / 10, size / 3.2
        w_square = 1.2 * size / 2
        mark, square = [], []
        mark.append(
            body.rect(
                [0, 0],
                [l_thin / 2, w_thin / 2],
                layer=layer,
                name=name + "_thin_x",
            )
        )
        mark.append(
            body.rect(
                [0, 0],
                [w_thin / 2, l_thin / 2],
                layer=layer,
                name=name + "_thin_y",
            )
        )
        mark.append(
            body.rect(
                [+l_thin / 2, 0],
                [l_large, w_large / 2],
                layer=layer,
                name=name + "_large_right",
            )
        )
        mark.append(
            body.rect(
                [0, +l_thin / 2],
                [w_large / 2, l_large],
                layer=layer,
                name=name + "_large_top",
            )
        )
        mark[0].unite(mark)

        if islayer63:
            square.append(
                body.rect([0, 0], [w_square, w_square], layer=63, name=name + "_63")
            )

    elif style == "fancy_cross":
        (
            w_thin,
            l_thin,
        ) = (
            size / 70,
            size / 2.5,
        )
        w_large, l_large = size / 10, size / 4
        w_med, l_med = size / 25, size / 2.5
        mark, mark1 = [], []
        mark.append(
            body.rect(
                [-l_thin / 2, -w_thin / 2],
                [l_thin, w_thin],
                layer=layer,
                name=name + "_a",
            )
        )
        mark.append(
            body.rect(
                [-w_thin / 2, -l_thin / 2],
                [w_thin, l_thin],
                layer=layer,
                name=name + "_thin_y",
            )
        )
        mark.append(
            body.rect(
                [+l_thin / 2, -w_large / 2],
                [l_large, w_large],
                layer=layer,
                name=name + "_large_right",
            )
        )
        mark.append(
            body.rect(
                [-l_thin / 2, -w_large / 2],
                [-l_large, w_large],
                layer=layer,
                name=name + "_large_left",
            )
        )
        mark.append(
            body.rect(
                [-w_large / 2, +l_thin / 2],
                [w_large, l_large],
                layer=layer,
                name=name + "_large_top",
            )
        )
        mark.append(
            body.rect(
                [-w_large / 2, -l_thin / 2],
                [w_large, -l_large],
                layer=layer,
                name=name + "_large_bot",
            )
        )
        mark = mark[0].unite(mark)

        x1, y1 = size / 12, size / 12
        mark1.append(
            body.rect([+x1, -w_med / 2], [l_med, w_med], layer=layer, name=name + "_b")
        )
        mark1.append(
            body.rect(
                [-w_med / 2, +y1],
                [w_med, l_med],
                layer=layer,
                name=name + "_med_NW",
            )
        )
        mark1.append(
            body.rect(
                [-x1, -w_med / 2],
                [-l_med, w_med],
                layer=layer,
                name=name + "_med_SW",
            )
        )
        mark1.append(
            body.rect(
                [-w_med / 2, -y1],
                [w_med, -l_med],
                layer=layer,
                name=name + "_med_SE",
            )
        )
        mark1 = mark1[0].unite(mark1)
        mark1.rotate(45)
        mark.unite(mark1)

    elif style == "KOH_cross":
        for l in range(4):
            mark = body.rect_center(
                [0, 0], [size, size / 5], name=name + suffix + f"align_{l}", layer=layer
            )
            mark.translate([4 * size / 5, 0])
            mark.rotate(l * 90)

    if writing:
        body.text(
            [-len(suffix) / 2 * size, -3.2 * size],
            size * 1.5,
            suffix,
            layer=layer,
            name=name + suffix + "text",
        )


def draw_alignment_marks(
    body: Body,
    style,
    marks={},
    writing=False,
    size="default",
    layer=None,
    islayer63=False,
    name="alignment_marks_0",
):
    """
    Draws one or several alignment marks

    Parameters
    ----------
    style     : str, 'butterfly' or 'cross' or 'fancy_cross'
    marks     : dict {'suffix':location}, location being a vector list
                if empty, the function return a single mark at [0,0]
    writing     : bool, whether or not to write suffix under the mark
    size      : str, each style comes with a 'default' size
    layer     : int, for the 'butterfly' style, if no layer is specified then
                GAP layer is assumed
    islayer63 : bool, adds layer63 squares for e-beam if True
                only available with 'cross' type
    name      : specify global name
    """

    if len(marks) == 0:
        _draw_one_mark(
            body,
            style=style,
            size=size,
            suffix=None,
            writing=writing,
            layer=layer,
            islayer63=islayer63,
            name=name,
        )

    for suffix, location in marks.items():
        with body(location, [1, 0]):
            _draw_one_mark(
                body,
                style=style,
                size=size,
                suffix=suffix,
                writing=writing,
                layer=layer,
                islayer63=islayer63,
                name=name,
            )


def hole_array(
    body: Body,
    pos,
    size,
    hole_spacing="25um",
    hole_size="5um",
    name="rect_array",
    odd=False,
    layer=DEFAULT,
) -> Entity:
    """
    Create a holed region to flux stability.
    The region is defined as a centered rectangle with it's pos (center) and
    size (diagonal)

    Parameters
    ----------
    body : Body
        Body on which to make this array.
    pos : List or Vector
        Bottom left corner of the region.
    size : List or Vector
        Diagonal
    hole_spacing : float or str with units, optional
        Distance between 2 holes. The default is '25um'.
    hole_size : float or str with units, optional
        Hole size. The default is '5um'.
    name : str, optional
        The default is 'rect_array'.
    odd : bool
        True -> Make sure NX and NY are odd number
        False -> Does not matter
    layer : int, optional
        Layer of the hole array. The default is DEFAULT.

    Returns
    -------
    hole_array : TYPE
        DESCRIPTION.

    """
    pos, size, hole_spacing, hole_size = parse_entry(pos, size, hole_spacing, hole_size)
    pos = Vector(pos)
    size = Vector(size)
    pos = pos - size / 2

    NX = int(val(size[0]) // val(hole_spacing))
    NY = int(val(size[1]) // val(hole_spacing))
    if odd:
        if NX % 2 == 1:
            NX += 1
        if NY % 2 == 1:
            NY += 1
    pos = pos + size / 2
    pos = pos - Vector([NX * hole_spacing / 2, NY * hole_spacing / 2])
    NX = NX + 1
    NY = NY + 1
    hole_array = body.rect_array(
        pos,
        [hole_size, hole_size],
        NX,
        NY,
        [hole_spacing, hole_spacing],
        layer=layer,
        name=name,
    )
    # store number of rectangles in the entity
    # a bit dirty
    hole_array.NX = NX
    hole_array.NY = NY

    return hole_array
    # hole_array.subtract(chip.entities[MASK])


def draw_connector(
    body: Body,
    pcb_track,
    pcb_gap,
    bond_length,
    tr_line=True,
    resistance="50 ohm",
    name="connector_0",
    lumped_length=None,
    layer=TRACK,
    connect_to_gnd=False,
    port_type=None,
):
    """
    Draws a CPW connector for inputs and outputs.

    Inputs:
    -------
    name : (str) should be different from other connector's name
    iBondLength: (float) corresponds to dimension a in the drawing
    iLineTest (Bool): unclear, keep False

        ground plane
        +------+
        |      |
        |      |
        |   +--+
    iIn |   |    iOut
        |   +--+
        |      |
        |      |
        +------+

    Outputs:
    --------
    returns created entities with formalism [Port], [Entity]
    """

    pcb_gap, pcb_track = parse_entry(pcb_gap, pcb_track)
    bond_length = parse_entry(bond_length)
    chip_thickness = 280e-6

    if layer == TRACK:
        if lumped_length is None:
            if not connect_to_gnd:
                body.rect(
                    [pcb_gap, pcb_track / 2],
                    [bond_length, -pcb_track],
                    layer=TRACK,
                    name=name + "_track",
                )

                # gap

                body.rect(
                    [0, pcb_gap + pcb_track / 2],
                    [pcb_gap + bond_length, -(2 * pcb_gap + pcb_track)],
                    layer=GAP,
                    name=name + "_gap",
                )

            # mesh
            body.rect(
                [0, pcb_gap + pcb_track / 2],
                [pcb_gap + bond_length, -(2 * pcb_gap + pcb_track)],
                layer=MESH,
                name=name + "_mesh",
            ).assign_mesh_length(pcb_track)

            if body.pm.is_mask:
                body.rect(
                    [
                        pcb_gap / 2 - body.gap_mask,
                        pcb_gap + pcb_track / 2 + body.gap_mask,
                    ],
                    [
                        pcb_gap / 2 + bond_length + body.gap_mask,
                        -(2 * pcb_gap + pcb_track + 2 * body.gap_mask),
                    ],
                    layer=MASK,
                    name=name + "_mask",
                )
            if connect_to_gnd == False:
                with body([pcb_gap + bond_length, 0], [1, 0]):
                    (portOut,) = create_port(
                        body, widths=[pcb_track, 2 * pcb_gap + pcb_track], name=name
                    )
            else:
                if port_type != "waveport":
                    with body([0, 0], [1, 0]):
                        (portOut,) = create_port(
                            body, widths=[pcb_track, 2 * pcb_gap + pcb_track], name=name
                        )
                else:
                    face_pos_in = [0, -pcb_track * 5, -3 * chip_thickness / 2]
                    face_size = [0, pcb_track * 10, 3 * chip_thickness]
                    with body([0, 0], [1, 0]):
                        (portOut,) = waveport(
                            body,
                            [pcb_track, pcb_track + 2 * pcb_gap],
                            face_pos_in,
                            face_size,  # pos and sheet size
                            face_ori=1,  # orientation
                            name="waveport_in",
                            is_mesh=True,
                            # deembed_dist=length_cable,
                            # deembed=True,
                            coor=0,
                        )

            if tr_line:
                ohm = body.rect(
                    [0, pcb_track / 2],
                    [pcb_gap, -pcb_track],
                    layer=RLC,
                    name=name + "_ohm",
                )
                points = [(0 + body.overdev, 0), (pcb_gap - body.overdev, 0)]
                ohm.assign_lumped_RLC(points, (resistance, 0, 0))
                body.polyline(points, name=name + "_line", closed=False, layer=DEFAULT)

                ohm.assign_mesh_length(pcb_track)

        else:
            body.rect(
                [pcb_gap + lumped_length, pcb_track / 2],
                [bond_length, -pcb_track],
                layer=TRACK,
                name=name + "_track",
            )

            # gap
            body.rect(
                [0, pcb_gap + pcb_track / 2],
                [
                    pcb_gap + bond_length + lumped_length,
                    -(2 * pcb_gap + pcb_track),
                ],
                layer=GAP,
                name=name + "_gap",
            )

            if body.pm.is_mask:
                body.rect(
                    [
                        pcb_gap / 2 - body.gap_mask,
                        pcb_gap + pcb_track / 2 + body.gap_mask,
                    ],
                    [
                        pcb_gap / 2 + bond_length + body.gap_mask,
                        -(2 * pcb_gap + pcb_track + body.gap_mask * 2),
                    ],
                    layer=MASK,
                    name=name + "_mask",
                )

            with body([pcb_gap + lumped_length + bond_length, 0], [1, 0]):
                (portOut,) = create_port(
                    body, widths=[pcb_track, 2 * pcb_gap + pcb_track], name=name
                )

            if tr_line:
                ohm = body.rect(
                    [0, pcb_track / 2],
                    [pcb_gap + lumped_length, -pcb_track],
                    layer=RLC,
                    name=name + "_ohm",
                )
                points = [
                    (+body.overdev, 0),
                    (pcb_gap + lumped_length - body.overdev, 0),
                ]
                ohm.assign_lumped_RLC(points, ("50ohm", 0, 0))
                body.polyline(points, name=name + "_line", closed=False, layer=DEFAULT)

                ohm.assign_mesh_length(pcb_track)

        try:
            return [portOut]
        except:
            return [None]
    else:
        inner = body.rect(
            [pcb_gap, pcb_track / 2],
            [bond_length, -pcb_track],
            layer=TRACK,
            name=name + "_track",
        )

        outter = body.rect(
            [0, pcb_gap + pcb_track / 2],
            [pcb_gap + bond_length, -(2 * pcb_gap + pcb_track)],
            layer=layer,
            name=name + "_gap",
        )
        outter.subtract(inner)


def place_name(
    body,
    design_name,
    pos=[0, 0],
    anchor=[-1, -1],
    layer=GAP,
    height="200um",
    name="design_name",
    esc=False,
):
    """
    design_name or list of names that will be put one on top of the other
    anchor [-1, -1] = left, bottom is the default
    pos is the position on the body
    """
    height, pos = parse_entry(height, pos)

    if isinstance(design_name, list):
        Ny = len(design_name)  # Number of lines
        Nx = max([len(text) for text in design_name])
    else:
        Ny = 1
        Nx = len(design_name)

    anchor = -(np.array([0.5, 0.5]) + np.array(anchor) / 2) * np.array(
        [(Nx * 8 / 9 + 1 / 9) * height, (Ny * 11 / 9) * height]
    )
    pos_x = pos[0] + height * 2 / 9 + anchor[0]
    pos_y = pos[1] + (Ny - 1) * height * 11 / 9 + anchor[1]

    for ii, name in enumerate(design_name):
        body.text(
            [pos_x, pos_y],
            text=name,
            size=height,
            name=name + "_%d" % ii,
            layer=layer,
            esc=esc,
        )
        pos_y -= height * 11 / 9

    if body.is_mask:
        body.rect(
            [pos_x - height * 2 / 9, pos_y + height * 11 / 9],
            [(Nx * 8 / 9 + 1 / 9) * height, (Ny * 11 / 9) * height],
            layer=MASK,
            esc=esc,
            name=name + "_mask",
        )


def layout(
    body: Body,
    name,
    simu_rf_track_gap,
    simu_dc_track_gap,
    resistance,
    tr_line=True,
    **kwargs,
):
    """
    simu_con_track_gap are override values for track and gap for the RF connectors
    in HFSS simulation
    kwargs should contain e.g. 'RF=[1, 2, 3]' meaning that you want RF ports 1,
    2 and 3. You may also have different kind of keywords for different
    kind of ports e.g. 'DC=[1, 2, 3]'
    If the value is anything (e.g. RF=True), all ports of this type will be
    displayed.
    Special case of no kwargs. All ports are displayed but not returned. This
    helps the users have a broad picture of the layout without knowing the
    types of ports.

    Numbering value indicates numbering convention. For JAWS, numbering starts
    at 1 see drawpylib/drawpylib/alice_and_bob

    Returns
    -------
    ground_plane, RF_list, DC_list, etc.
    port_n is accessible via RF_list[n] with starting index 'numbering'.

    """
    file_path = os.path.dirname(__file__)
    source_layout = open(os.path.join(file_path, f"Parameters/{name}.yaml"), "r")
    chip_layout = yaml.load(source_layout, Loader=yaml.FullLoader)
    x_dim, y_dim = parse_entry(chip_layout["x_dim"], chip_layout["y_dim"])
    bond_length = "200um"

    # drawing ground plane

    ground_plane = body.rect([0, 0], [x_dim, y_dim], name="ground_plane", layer=TRACK)

    # port display

    if kwargs == {}:
        marker = True  # will not return the ports, used as a preview
        for key, value in chip_layout["ports"].items():
            kwargs[key] = [ii + 1 for ii in range(len(value["loc"]))]
    else:
        marker = False
        for key, value in kwargs.items():
            assert key in chip_layout["ports"].keys()
            if not isinstance(value, list):
                kwargs[key] = [
                    ii + 1 for ii in range(len(chip_layout["ports"][key]["loc"]))
                ]

    port_types = chip_layout["ports"]
    port_list = []
    for type_name, type_params in port_types.items():
        if type_name in kwargs.keys():
            _port_list = [None] * chip_layout["numbering"]
            track, gap = type_params["dim"]
            for ii, loc in enumerate(type_params["loc"]):
                if ii + 1 in kwargs[type_name]:
                    with body(*loc):
                        if body.pm.mode == "gds":
                            (port,) = draw_connector(
                                body,
                                track,
                                gap,
                                bond_length,
                                tr_line=False,
                                name="port_%s_%d" % (type_name, ii + 1),
                            )
                            place_name(
                                body,
                                [f"{ii + 1}"],
                                anchor=[0, 0],
                                layer=BOND,
                                height=gap,
                            )
                        if body.pm.mode == "hfss":
                            if type_name != "RF":
                                track, gap = simu_dc_track_gap
                                # tr_line = True
                                (port,) = draw_connector(
                                    body,
                                    track,
                                    gap,
                                    bond_length,
                                    tr_line=tr_line,
                                    resistance=resistance,
                                    name="port_%s_%d" % (type_name, ii + 1),
                                    connect_to_gnd=True,
                                )
                            else:
                                track, gap = simu_rf_track_gap
                                (port,) = draw_connector(
                                    body,
                                    track,
                                    gap,
                                    bond_length,
                                    tr_line=tr_line,
                                    resistance=resistance,
                                    name="port_%s_%d" % (type_name, ii + 1),
                                    connect_to_gnd=True,
                                    # port_type="waveport",
                                )

                        _port_list.append(port)
                else:
                    _port_list.append(None)
            port_list.append(_port_list)

    body.center = [x_dim / 2, y_dim / 2]
    body.x_dim = x_dim
    body.y_dim = y_dim

    if marker:
        ground_plane
    else:
        return ground_plane, *port_list


def entities_finder(
    body: Body, keylist: List[str], layers: List[int] = None, match_case: bool = True
) -> List[Entity]:
    """
    Finding entities base on strings
    Inputs:
        keylist : list
            strings of entity names
        match_case: bool
            name of the entity
    Returns:
        sublist: list
            list of entities
    """
    sublist = []
    layers = layers if layers is not None else body.entities
    for idx in layers:
        for key in keylist:
            if match_case:
                sublist += [s for s in body.entities[idx] if key == s.name]
            else:
                sublist += [s for s in body.entities[idx] if key in s.name]
    return sublist


def poly_area(points):
    x, y = points.T[0], points.T[1]
    return 0.5 * np.abs(np.dot(x, np.roll(y, 1)) - np.dot(y, np.roll(x, 1)))


def draw_cable_double(*args, **kwargs) -> float:
    body: Body = kwargs.pop("body")
    added_width = kwargs.pop("added_width")
    new_layer_mask = kwargs.pop("new_layer_mask")
    name = kwargs.pop("name")

    length = body.draw_cable(*args, name=name, **kwargs)
    for a in args:
        a.layers[-1] = new_layer_mask
        a.widths[-1] += 2 * added_width
    body.draw_cable(*args, name=name + "_2", **kwargs)
    for a in args:
        a.layers[-1] = MASK
        a.widths[-1] -= 2 * added_width
    return length


def KOH_corner_protection(body: Body, entity: Entity, locations: List, size) -> Entity:

    if isinstance(size, List) or isinstance(size, np.ndarray):
        size_x = size[0]
        size_y = size[1]
    else:
        size_x, size_y = size
    corners = []
    for i in locations:
        corners.append(
            body.rect_center(
                i,
                [size_x, size_y],
                layer=entity.layer,
                name=entity.name + f"corner{locations.index(i)}",
            )
        )
    return entity.unite(corners)


def save_gds(body: Body, name, rel_path: str = None, **kwargs) -> None:
    max_points = 199 if "max_points" not in kwargs else kwargs["max_points"]
    body.pm.generate_gds(
        os.path.join(os.getcwd(), rel_path), name, max_points=max_points
    )
    print(
        "File saved as "
        + os.path.join(os.getcwd(), rel_path, name + f"_{body.name}.gds")
    )


def draw_circle(
    body: Body,
    center: List[str],
    radius: str,
    width: str,
    name: str,
    layer: int,
    start_angle: str = "0",
    end_angle: str = "360",
    Number_of_points=500,
    mesh_size: str = None,
    **kwargs,
) -> Entity:

    center, r, width, start_angle, end_angle = parse_entry(
        center, radius, width, start_angle, end_angle
    )

    if len(center) == 2:
        x, y = center
    elif len(center) == 3:
        x, y, z = center

    arc = [start_angle]
    j = start_angle
    for i in range(int(Number_of_points / 2 - 2)):
        step = (end_angle - start_angle) / int(Number_of_points / 2 - 1)
        j = j + step
        arc.append(j)
    arc.append(end_angle)

    outer_edge = [
        (
            x + (r + width / 2) * sp.cos(np.pi / 180 * i),
            y + (r + width / 2) * sp.sin(np.pi / 180 * i),
        )
        for i in arc
    ]
    inner_edge = [
        (
            x + (r - width / 2) * sp.cos(np.pi / 180 * i),
            y + (r - width / 2) * sp.sin(np.pi / 180 * i),
        )
        for i in arc
    ]
    inner_edge.reverse()

    return body.polyline(
        [inner_edge.pop()] + outer_edge + inner_edge,
        layer=layer,
        name=name + "_circle_track",
        closed=True,
    )


def draw_ellipse(
    body: Body,
    center: List[str],
    a: str,
    b: str,
    width: str,
    name: str,
    layer: int,
    start_angle: str = "0",
    end_angle: str = "360",
    Number_of_points: int = 500,
    mesh_size: str = None,
    **kwargs,
) -> Entity:

    center, a, b, width, start_angle, end_angle = parse_entry(
        center, a, b, width, start_angle, end_angle
    )

    if len(center) == 2:
        x, y = center
    elif len(center) == 3:
        x, y, z = center

    arc = [start_angle]
    j = start_angle
    for i in range(int(Number_of_points / 2 - 2)):
        step = (end_angle - start_angle) / int(Number_of_points / 2 - 1)
        j = j + step
        arc.append(j)
    arc.append(end_angle)

    outer_edge = [
        (
            x + (a + width / 2) * sp.cos(np.pi / 180 * i),
            y + (b + width / 2) * sp.sin(np.pi / 180 * i),
        )
        for i in arc
    ]
    inner_edge = [
        (
            x + (a - width / 2) * sp.cos(np.pi / 180 * i),
            y + (b - width / 2) * sp.sin(np.pi / 180 * i),
        )
        for i in arc
    ]
    inner_edge.reverse()

    return body.polyline(
        [inner_edge.pop()] + outer_edge + inner_edge,
        layer=layer,
        name=name + "_ellipse_track",
        closed=True,
    )


def get_wafer_chip_centers(chip_width, chip_height, wafer_diameter, wafer_flat_height):

    x_range = wafer_diameter
    y_range = wafer_diameter / 2 + wafer_flat_height
    N_x = int(val(x_range) // val(chip_width))
    N_y = int(val(y_range) // val(chip_height))

    chip_centers_x = [i * chip_width for i in np.arange(-N_x / 2, N_x / 2, 1)]
    chip_centers_y = [i * chip_height for i in np.arange(-N_y / 2, N_y / 2, 1)]

    chip_centers = []
    a = 0
    for i in chip_centers_x:
        chip_centers.append([])
        for j in chip_centers_y:
            chip_centers[a].append((i, j))
        a = a + 1

    return chip_centers


def waveport(
    body,
    widths,
    face_pos,
    face_size,
    face_ori=1,
    coor=0,
    deembed_dist=0,
    name="waveport_0",
    is_mesh=False,
):
    """
    Create a waveport on a rectangle defined by rect(face_pos, face_size).

    Parameters
    ----------
    body : body on which this waveport is defined
    track : track of the CPW
    gap : gap of the CPW
    face_pos : lower corner of the waveport face
    face_size : diagonal of the waveport face
    face_ori : 1 or -1 to change the orientation of the port on the face
        inwards, outwards... The default is 1.
    coor : absolute coordinate of the port within the face.
        Default 0, port is centered in the face.
    deembed_dist : deembeding distance. Default is 0.
    name : The default is 'waveport_0'.

    Returns
    -------
    list
        List of one created ports

    """
    _ = parse_entry(widths, face_pos, face_size, coor)
    widths, face_pos, face_size, coor = _

    if face_size[0] == 0:
        # port along x axis
        pos = [face_pos[0], coor]
        ori = [face_ori, 0]
    elif face_size[1] == 0:
        # port along y axis
        pos = [coor, face_pos[1]]
        ori = [0, face_ori]
    else:
        raise Exception("Waveport supported along x or y planes")

    with body(pos, ori):
        (port,) = create_port(body, widths, is_mesh=is_mesh, name=name + "_port")

    pos = Vector(pos)
    ori = Vector(ori)
    start = [
        val(pos[0] + ori.orth()[0] * widths[0] / 2) * 1e3,
        val(pos[1] + ori.orth()[1] * widths[0] / 2) * 1e3,
        0,
    ]
    stop = [
        val(pos[0] + ori.orth()[0] * widths[1] / 2) * 1e3,
        val(pos[1] + ori.orth()[1] * widths[1] / 2) * 1e3,
        0,
    ]
    waveport = body.rect(face_pos, face_size, name=name + "_wave", layer=RLC)
    waveport.assign_waveport(
        DoDeembed=True, DeembedDist=deembed_dist, DoRenorm=True, start=start, stop=stop
    )
    return [port]


def get_square_x_size(y_size: int) -> int:
    x_size1 = int(np.floor(y_size / np.sqrt(3)))
    x_size2 = int(np.ceil(y_size / np.sqrt(3)))
    return x_size2 if y_size % 2 == x_size1 % 2 else x_size1


def get_frame_size(
    structure_a: sp.Symbol,
    xy_sizes: Tuple[float, float],
    offset: Tuple[Union[sp.Symbol, float], Union[sp.Symbol, float]],
) -> Tuple[sp.Symbol, sp.Symbol]:
    """Returns membrane square frame size for a membrane with (x_size, y_size) and given offset"""
    membrane_size_x: sp.Symbol = (xy_sizes[0] + offset[0]) * structure_a * np.sqrt(3)
    membrane_size_y: sp.Symbol = (xy_sizes[1] + offset[1] + 0.5) * structure_a
    return (membrane_size_x, membrane_size_y)


def save_svg(
    body: Body, name: str, rel_path: str = None, layer_colors: dict = None, **kwargs
):
    """Not sure if this works correctly for multiple cells"""
    """layer_colors is a dict with layer numbers for keys and rgb value for values"""
    scale = 1 if "scale" not in kwargs else kwargs["scale"]
    s = body.pm.interface

    for cell_name in s.gds_cells.keys():
        mystyle = {}
        ldkeys, ltkeys = s.gds_cells[cell_name].get_svg_classes()
        cmap = None
        if layer_colors is None:
            cmap = plt.get_cmap("viridis")

        for num, (layer, d) in enumerate(sorted(ldkeys)):
            if len(body.entities[layer]) > 0:
                body.entities[layer][0] = body.unite(body.entities[layer])
                if cmap is not None:
                    c_temp = np.array(cmap(num / len(body.entities.keys()))) * 255
                    c = f"rgb({int(c_temp[0])}, {int(c_temp[1])}, {int(c_temp[2])})"
                else:
                    c = layer_colors[layer]

                # Define fill and stroke for layer "layer" and datatype d
                mystyle[(layer, d)] = {"fill": c, "stroke": "none", "fill-opacity": "1"}

        s.gds_cells[cell_name].write_svg(
            os.path.join(os.getcwd(), rel_path) + name + f"_{body.name}.svg",
            scaling=scale,
            style=mystyle,
            background=None,
        )
        print(
            "File saved as "
            + os.path.join(os.getcwd(), rel_path, name + f"_{body.name}.svg")
        )
