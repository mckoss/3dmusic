E = 0.01;
$fa = 3;
$fs = 1;

FLUE_LENGTH = 41;
FLUE_WIDTH = 10;
FLUE_HEIGHT = 2;
FLUE_TAPER = 0.5;

GAP_LENGTH = 3;

EXIT_ANGLE = 15;
EXIT_FLARE = 8;

// Misc wall thickness
THICKNESS = 5;

module whistle(length=FLUE_LENGTH,
               width=FLUE_WIDTH) {
  difference() {
    pipe(length, width);
    fipple_cut(length, width);
  }
}

module pipe(length, width) {
  translate([0, 0, -width + THICKNESS])
    rotate(a=90, v=[0, 1, 0])
      difference() {
        // Body
        cylinder(r=width, h=length * 2, center=true);
        // Internal volume
        # translate([0, 0, length / 2])
          cylinder(r=width - THICKNESS, h=length + 2 * E, center=true);
        // Mouthpiece curve
        translate([width * 1.7, 0, -length])
          rotate(a=90, v=[1, 0, 0])
            cylinder(r=width * 2, h = width * 3, center=true);
      }
}

/*
   Cut parts (using difference) to remove the windway (flue)
   and carve the labium (knife edge).

   The bottom of the windway is at the origin (z = 0).
*/
module fipple_cut(length=FLUE_LENGTH,
              width=FLUE_WIDTH,
              height=FLUE_HEIGHT,
              taper=FLUE_TAPER,
              gap=GAP_LENGTH,
              cut_angle=EXIT_ANGLE,
              flare_angle=EXIT_FLARE) {

  /* wind-way (flue)
     2----6
     |\   |\
     | 1----5
     3_|__7 |
      \|   \|
       0----4
  */

  polyhedron(
    points=[
      [-length - E, -width / 2, 0], [-length - E, -width / 2, height],
      [-length - E, width / 2, height], [-length - E, width / 2, 0],
      [0, -width / 2, 0], [0, -width / 2, height * taper],
      [0, width / 2, height * taper], [0, width / 2, 0]
    ],
    triangles=[
      [0, 3, 2], [0, 2, 1],
      [0, 1, 5], [0, 5, 4],
      [4, 5, 6], [4, 6, 7],
      [7, 6, 2], [7, 2, 3],
      [1, 2, 6], [1, 6, 5],
      [0, 4, 7], [0, 7, 3]
    ]);

  // mouth cut
  cut_depth = tan(EXIT_ANGLE) * gap;
  x1 = length;
  z1 = length * tan(cut_angle);
  y1 = width / 2;
  y2 = width / 2 + length * tan(flare_angle);
  translate([-E, 0, -cut_depth]) {
    polyhedron(
      points=[
        [0, -y1, 0], [x1, -y2, z1], [0, -y1, z1],
        [0, y1, 0],  [x1, y2, z1],  [0, y1, z1]
      ],
      triangles=[
        [0, 2, 1], [3, 4, 5],
        [0, 5, 2], [0, 3, 5],
        [2, 4, 1], [2, 5, 4],
        [0, 4, 3], [0, 1, 4]
    ]);
  }

  // Cut underside of labium.
  undercut = 5 * gap;
  // Ensure gap is clear down to cut depth
  translate([undercut / 2, 0, -2 * cut_depth])
    cube([undercut, width, cut_depth * 4], center=true);
}

// Fipple cut placed at origin
module fipple_mouth_cut(width, length, height, cut_angle=EXIT_ANGLE, flare_angle=EXIT_FLARE) {
  x1 = length;
  z1 = length * tan(cut_angle);
  y1 = width / 2;
  y2 = width / 2 + length * tan(flare_angle);
  polyhedron(
    points=[
      [0, -y1, 0], [x1, -y2, z1], [0, -y1, z1],
      [0, y1, 0],  [x1, y2, z1],  [0, y1, z1]
    ],
    triangles=[
      [0, 2, 1], [3, 4, 5],
      [0, 5, 2], [0, 3, 5],
      [2, 4, 1], [2, 5, 4],
      [0, 4, 3], [0, 1, 4]
  ]);
}

whistle();
//fipple_cut();
