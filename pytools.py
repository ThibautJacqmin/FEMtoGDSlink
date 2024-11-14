# -*- coding: utf-8 -*-
"""
Created on Thu Nov 14 16:52:43 2024

@author: ThibautJacqmin
"""
import klayout.db as db

def cell_vertices_to_string(cell, layout, layer_index):
    """
    Extract the vertices coordinates of all polygon shapes in a cell, including instances, and format as a string.
    
    Parameters:
        cell (db.Cell): A KLayout Cell object containing shapes.
        layout (db.Layout): The layout object, needed to access cells by index.
        layer_index (db.LayerInfo): The index of the layer to extract shapes from.
    
    Returns:
        str: A string of vertices in the format "(x1, y1; x2, y2; ...)".
    """
    
    # List to collect vertices
    vertices = []

    # Iterate over all shapes in the specified layer
    for shape in cell.shapes(layer_index):
        # If the shape is a polygon, get its vertices directly
        if shape.is_polygon():
            polygon = shape.polygon
            # Convert to a simple polygon and retrieve the points
            simple_polygon = polygon.to_simple_polygon()
            for point in simple_polygon.each_point():
                vertices.append((point.x, point.y))
        
        # If the shape is an instance (like an array), handle each instance manually
        elif shape.is_instance():
            # Get the instance and its transformation
            inst = shape.cell_inst()
            trans = shape.trans()
            instance_cell = layout.cell(inst.cell_index())
            
            if instance_cell:
                # For each polygon in the instance cell, apply the transformation and collect vertices
                for inst_shape in instance_cell.shapes(layer_index):
                    if inst_shape.is_polygon():
                        transformed_polygon = inst_shape.polygon.transformed(trans).to_simple_polygon()
                        for point in transformed_polygon.each_point():
                            vertices.append((point.x, point.y))

    # Check if we found any vertices
    if not vertices:
        return "No vertices found in the specified cell and layer."

    # Format the vertices list into a string "(x1, y1; x2, y2; ...)"
    vertices_string = "(" + "; ".join(f"{x}, {y}" for x, y in vertices) + ")"
    
    return vertices_string
