// OpenGrid Snap Mount Generator
// @author Natesh Narain <nnaraindev@gmail.com>
//
// @description A generator for mounts that can snap into the OpenGrid Snap system.

include <opengrid-snap.scad>

// Use lite snaps
lite = false;

// Thickness of the base of the mount
base_thickness = 5.0;
// Length of the base in mm.
base_length = 75;
// Width of the base in mm.
base_width = 75;

// Number of cells in X direction
cells_x = 2;
// Number of cells in Y direction
cells_y = 1;

// Radius of mounting holes
mounting_hole_radius = 2.0;
// Countersink depth from the bottom face of the base. Set to 0 to disable.
mounting_hole_countersink_depth = 0;
// Countersink radius for all mounting holes.
mounting_hole_countersink_radius = 2.0; //(.1)
// Mounting hole positions relative to the bottom corner of the base plate closest
// to the origin. Accepted formats:
// - Single hole: [x, y]
// - Multiple holes: [[x1, y1], [x2, y2], ...]
// - Flat list: [x1, y1, x2, y2, ...]
// bottom corner of the base plate closest to the origin
mounting_hole_positions = [];

/* [Hidden] */
fulldiff=3.4;
h=lite ? 3.4 : fulldiff*2;

snap_height = h;
snap_width = 24.80;

// grid spacing in mm
grid_spacing = 28;



$fs = 0.1;


module base(length, width, thickness){
    cuboid([length, width, thickness], anchor=CENTER);
}

module snapGrid(cellx, celly, grid_spacing){
    union(){
        for(x = [0 : cells_x-1]){
            for(y = [0 : cells_y-1]){
                translate([x * grid_spacing, y * grid_spacing, 0])
                    openGridSnap(lite=lite, directional=false);
            }
        }
    }
}

module snapBase(){
    union(){
        min_base_length = (cells_x - 1) * grid_spacing + snap_width;
        min_base_width = (cells_y - 1) * grid_spacing + snap_width;
        effective_base_length = max(base_length, min_base_length);
        effective_base_width = max(base_width, min_base_width);

        grid_center_x = (cells_x - 1) * grid_spacing / 2;
        grid_center_y = (cells_y - 1) * grid_spacing / 2;
        translate([grid_center_x, grid_center_y, snap_height / 2 + base_thickness / 2]) {
            base(effective_base_length, effective_base_width, base_thickness);
        }

        snapGrid(cells_x, cells_y, grid_spacing);
    }
}

module mountingHoles(positions, radius, countersink_depth, countersink_radius){
    min_base_length = (cells_x - 1) * grid_spacing + snap_width;
    min_base_width = (cells_y - 1) * grid_spacing + snap_width;
    effective_base_length = max(base_length, min_base_length);
    effective_base_width = max(base_width, min_base_width);

    grid_center_x = (cells_x - 1) * grid_spacing / 2;
    grid_center_y = (cells_y - 1) * grid_spacing / 2;

    base_corner_x = grid_center_x - effective_base_length / 2;
    base_corner_y = grid_center_y - effective_base_width / 2;

    is_single_pair = is_list(positions) && len(positions) == 2 && is_num(positions[0]) && is_num(positions[1]);

    is_flat_numeric_list =
        is_list(positions) &&
        len(positions) > 0 &&
        len(positions) % 2 == 0 &&
        is_undef(search(false, [for (v = positions) is_num(v)]));

    normalized_positions =
        is_single_pair ? [positions] :
        (is_flat_numeric_list ? [for (i = [0:2:len(positions)-2]) [positions[i], positions[i+1]]] :
        (is_list(positions) ? positions : []));

    countersink_enabled =
        is_num(countersink_depth) &&
        is_num(countersink_radius) &&
        countersink_depth > 0 &&
        countersink_radius > radius;

    effective_countersink_depth = countersink_enabled ? min(countersink_depth, base_thickness) : 0;

    for (pos = normalized_positions){
        if (is_list(pos) && len(pos) >= 2 && is_num(pos[0]) && is_num(pos[1])) {
            hole_x = base_corner_x + pos[0];
            hole_y = base_corner_y + pos[1];
            translate([hole_x, hole_y, snap_height / 2 + base_thickness / 2])
                cylinder(h=base_thickness * 10 + 0.2, r=radius, center=true);

            if (countersink_enabled) {
                translate([hole_x, hole_y, snap_height / 2 + effective_countersink_depth / 2])
                    cylinder(h=effective_countersink_depth + 0.2, r=countersink_radius, center=true);
            }
        }
    }
}

module snapMount(){
    difference() {
        snapBase();
        mountingHoles(
            mounting_hole_positions,
            mounting_hole_radius,
            mounting_hole_countersink_depth,
            mounting_hole_countersink_radius
        );
    }
}


snapMount();
