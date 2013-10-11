E = 0.1;
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

PI = 3.141592654;
SOUND_MPS = 344;
C = SOUND_MPS * 1000 / 2 / PI;

// Misc wall thickness
THICKNESS = 2;

module whistle_ball(length=FLUE_LENGTH, width=FLUE_WIDTH, volume=10000) {
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
        ball(volume);
    }
    rotate(ang, v=[0, 1, 0])
      fipple_cut(length, width);
  }
}

module whistle_cylinder(flue_width=FLUE_WIDTH,
                        flue_height=FLUE_HEIGHT,
                        pitch=440,
                        volume) {
  gap = flue_height * FLUE_TAPER * 2;
  area = gap * flue_width;
  width = flue_width + 2 * THICKNESS;
  // Effective length???
  length = 1.3 * (THICKNESS + flue_height);
  echo("Effective mouth length", length);
  _volume = volume == undef ? volume_of(pitch, area, length) : volume;
  r = pow(_volume / 2 / PI, 1 / 3);
  flue_length = min(2 * r, 20);
  echo("Radius", r);
  difference() {
    union() {
      translate([-flue_length / 2 - r, 0, flue_height / 2])
        cube([flue_length, width, flue_height + 2 * THICKNESS], center=true);
      translate([0, 0, -r + flue_height])
        rotate(90, v=[1, 0, 0])
          difference() {
            cylinder(r=r + THICKNESS, h=2 * r + 2 * THICKNESS, center=true);
            cylinder(r=r, h=2 * r, center=true);
          }
      translate([-(r + THICKNESS) / 2, 0, -(r + THICKNESS) / 2 + flue_height + THICKNESS])
        difference() {
          cube([r + THICKNESS, width, r + THICKNESS], center=true);
          translate([THICKNESS + E, 0, -THICKNESS - flue_height])
            cube([r + THICKNESS, flue_width, r + THICKNESS], center=true);
        }
    }
  translate([-r, 0, 0])
    fipple_cut(flue_length, flue_width, cut_limit=r, cut_depth=flue_height + 3 * THICKNESS);
  }
}

function volume_of(pitch, area, length) = pow(C / pitch, 2) * area / length;

module mouthpiece(length, width) {
  translate([-length, 0, 0])
    scale([1, 1, 0.3])
      rotate(90, v=[0, 1, 0])
        cylinder(r=width * 0.9, h=length);
}

module ball(volume) {
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
              cut_angle=EXIT_ANGLE,
              flare_angle=EXIT_FLARE,
              cut_limit,
              cut_depth) {
  gap = height * FLUE_TAPER * 2;
  _cut_limit = cut_limit == undef ? 50 : cut_limit;
  _cut_depth = cut_depth == undef ? 50 : cut_depth;
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
      [0, -width / 2, 0], [0, -width / 2, height * FLUE_TAPER],
      [0, width / 2, height * FLUE_TAPER], [0, width / 2, 0]
    ],
    triangles=[
      [0, 3, 2], [0, 2, 1],
      [0, 1, 5], [0, 5, 4],
      [4, 5, 6], [4, 6, 7],
      [7, 6, 2], [7, 2, 3],
      [1, 2, 6], [1, 6, 5],
      [0, 4, 7], [0, 7, 3]
    ]);

  /* Mouth cut
            x1
        3---2    z2
        |   |
        |   1    z1
        |  /
        |/
        0       far side +4
  */
  undercut_depth = tan(EXIT_ANGLE) * gap;
  x1 = _cut_limit;
  z1 = x1 * tan(cut_angle);
  z2 = max(z1 + 1, _cut_depth);
  y1 = width / 2;
  y2 = width / 2 + x1 * tan(flare_angle);
  translate([-E, 0, -undercut_depth]) {
    polyhedron(
      points=[
        [0, -y1, 0], [x1, -y2, z1], [x1, -y2, z2], [0, -y1, z2],
        [0, y1, 0],  [x1, y2, z1],  [x1, y2, z2], [0, y1, z2]
      ],
      triangles=[
        [0, 3, 2], [0, 2, 1],  // front
        [4, 6, 7], [4, 5, 6],  // back
        [0, 4, 7], [0, 7, 3],  // left
        [1, 2, 6], [1, 6, 5],  // right
        [0, 1, 5], [0, 5, 4],  // bottom
        [2, 3, 7], [2, 7, 6]   // top
    ]);
  }

  // Cut underside of labium.
  translate([gap, 0, -2 * undercut_depth])
    cube([2 * gap, width, undercut_depth * 4], center=true);
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

// A = PI R^2
// R = sqrt(A / PI)
function circle_radius(a) = sqrt(a / PI);

//whistle_ball();
whistle_cylinder();
//fipple_cut(20, 30);
