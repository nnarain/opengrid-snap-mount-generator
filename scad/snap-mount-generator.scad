// OpenGrid Snap Mount Generator
// @author Natesh Narain <nnaraindev@gmail.com>
//
// @description A generator for mounts that can snap into the OpenGrid Snap system.

include <opengrid-snap.scad>

// Use lite snaps
lite = false;

// Thickness of the base of the mount
base_thickness = 5.0;

// Number of cells in X direction
cells_x = 2;
// Number of cells in Y direction
cells_y = 1;

// grid spacing in mm
grid_spacing = 28;

// Radius of mounting holes
mounting_hole_radius = 2.0;
// Mounting hole positions as [[x, y], ...] (or a single [x, y]) relative to the
// bottom corner of the base plate closest to the origin
mounting_hole_positions = [];

/* [Hidden] */
fulldiff=3.4;
h=lite ? 3.4 : fulldiff*2;

snap_height = h;
snap_width = 24.80;

base_length = 75;
base_width = 75;

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

module mountingHoles(positions, radius){
    min_base_length = (cells_x - 1) * grid_spacing + snap_width;
    min_base_width = (cells_y - 1) * grid_spacing + snap_width;
    effective_base_length = max(base_length, min_base_length);
    effective_base_width = max(base_width, min_base_width);

    grid_center_x = (cells_x - 1) * grid_spacing / 2;
    grid_center_y = (cells_y - 1) * grid_spacing / 2;

    base_corner_x = grid_center_x - effective_base_length / 2;
    base_corner_y = grid_center_y - effective_base_width / 2;

    normalized_positions =
        (is_list(positions) && len(positions) == 2 && is_num(positions[0]) && is_num(positions[1])) ? [positions] :
        (is_list(positions) ? positions : []);

    for (pos = normalized_positions){
        if (is_list(pos) && len(pos) >= 2 && is_num(pos[0]) && is_num(pos[1])) {
            hole_x = base_corner_x + pos[0];
            hole_y = base_corner_y + pos[1];
            translate([hole_x, hole_y, snap_height / 2 + base_thickness / 2])
                cylinder(h=base_thickness * 10 + 0.2, r=radius, center=true);
        }
    }
}

module snapMount(){
    difference() {
        snapBase();
        mountingHoles(mounting_hole_positions, mounting_hole_radius);
    }
}


snapMount();
