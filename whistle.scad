E = 0.01;
$fa = 3;
$fs = 1;

FLUE_LENGTH = 30;
FLUE_WIDTH = 10;
FLUE_HEIGHT = 3;
FLUE_TAPER = 0.5;

TRUNCATE = 0.9;

GAP_LENGTH = FLUE_HEIGHT * FLUE_TAPER * 2;

EXIT_ANGLE = 15;
EXIT_FLARE = 8;

// Misc wall thickness
THICKNESS = 10;

module whistle(length=FLUE_LENGTH, width=FLUE_WIDTH, volume=10000) {
  r_body = cap_radius(volume, TRUNCATE);
  r_body_outer = r_body + THICKNESS;
  top = 2 * r_body_outer * TRUNCATE;

  ang = 40;
  difference() {
    union() {
      rotate(ang, v=[0, 1, 0])
        translate([0, 0, FLUE_HEIGHT / 2])
        mouthpiece(length, width);
      translate([0, 0, -top + 1.5 * FLUE_HEIGHT])
        body(volume);
    }
    rotate(ang, v=[0, 1, 0])
      fipple_cut(length, width);
  }
}

module mouthpiece(length, width) {
  translate([-length, 0, 0])
    scale([1, 1, 0.3])
      rotate(90, v=[0, 1, 0])
        cylinder(r=width * 0.9, h=length);
}

module body(volume) {
  r_body = cap_radius(volume, TRUNCATE);
  r_body_outer = r_body + THICKNESS;

  top = 2 * r_body_outer * TRUNCATE;

  difference() {
    trunc_sphere(r_body_outer);
    translate([0, 0, THICKNESS])
      trunc_sphere(r_body);
  }
}

module pipe(length, width) {
  translate([0, 0, -width + THICKNESS])
    rotate(a=90, v=[0, 1, 0])
      difference() {
        // Body
        cylinder(r=width, h=length * 2, center=true);
        // Internal volume
        translate([0, 0, length / 2])
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
  x1 = 100;
  z1 = x1 * tan(cut_angle);
  y1 = width / 2;
  y2 = width / 2 + x1 * tan(flare_angle);
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

module trunc_sphere(r) {
  difference() {
    translate([0, 0, 2 * r * (TRUNCATE - 0.5)])
      sphere(r);
    translate([0, 0, -r])
      cube([2 * r, 2 * r, 2 * r], center=true);
  }
}

/* Calculate radius of spherical cap of volume, v, and
   and percent of sphere, p (0 - 1).

   V = PI H^2 / 3 (3R - H)

   where H = 2R * P:

   V = 4 PI R^2 P^2 / 3 * (3R - 2R P)
     = 4 PI R^3 P^2 /  3 * (3 - 2 P)

   R = cube_root(3 V / (4 PI P^2 (3 - 2P))

   Note full sphere volume is 4/3 PI R^3
*/
function cap_radius(v, p) = pow(3 * v / (4 * PI * pow(p, 2) * (3 - 2 * p)), 1 / 3);

whistle();
//fipple_cut();
