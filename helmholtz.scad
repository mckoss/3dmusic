/* Experiments with helmholtz resonators.

   Equation for Helmholtz resonator frequency.
   http://en.wikipedia.org/wiki/Helmholtz_resonance
   http://www.phys.unsw.edu.au/jw/Helmholtz.html

   f = c / (2 * pi) * sqrt(A/V/L)

   where:
      c = 340 m/s (speed of sound)
      A = total cross-sectional area of hole(s)
      V = static volume
      L = length of "neck"

   Note that L should be replaced by the "effective length" of the neck
   which includes an additional end-effect term proportional to the radius
   of the neck opening (on each end).
*/

// Sphere and cylinder precision
$fa = 3;
$fs = 1;

// Ratio of full sphere to print
TRUNCATE = 0.9;
THICKNESS = 1.0;

// Constants
PI = 3.141592654;
E = 0.01;
SOUND_MPS = 344;
C = SOUND_MPS * 1000 / 2 / PI;
RADIUS_TO_LENGTH = 2.2;

/* Create a Helmholtz oscillator with parameters in array:

   p = [volume, length, area]

   TODO: Should the cylinder volume be part of the total static volume?
*/
module helmholtz(p) {
  v = p[0];
  l = p[1];
  a = p[2];
  t = p[3];

  r_neck = circle_radius(a);

  eff_l = l + RADIUS_TO_LENGTH * r_neck;
  echo("Predicted frequency", C * sqrt(a / v / eff_l));

  if (t == "s") {
    helmholtz_sphere(v, l, a);
  } else if (t == "c") {
    helmholtz_cube(v, l, a);
  }
}

module helmholtz_sphere(v, l, a) {
  r_neck = circle_radius(a);

  r_body = cap_radius(v, TRUNCATE);
  r_body_outer = r_body + THICKNESS;

  top = 2 * r_body_outer * TRUNCATE;

  difference() {
    trunc_sphere(r_body_outer);
    translate([0, 0, THICKNESS])
      trunc_sphere(r_body);
    translate([0, 0, top / 2])
      cylinder(r=r_neck, h=top);
  }

  translate([0, 0, top - THICKNESS])
    neck_tube(r_neck, l);
}

// Take several (l, a) pairs in holes.
module helmholtz_holes(v, holes) {
  r_body = cap_radius(v, TRUNCATE);
  r_body_outer = r_body + THICKNESS;
  top = 2 * r_body_outer * TRUNCATE;
  ang = 360 / len(holes);

  difference() {
    trunc_sphere(r_body_outer);
    translate([0, 0, THICKNESS])
      trunc_sphere(r_body);

    for (i = [0 : len(holes) - 1])
      assign(l = holes[i][0],
             r_neck = circle_radius(holes[i][1])
            ) {

      translate([0, 0, top / 2])
        rotate(ang * i, v=[0, 0, 1])
          rotate(45, v=[0, 1, 0])
            cylinder(r=r_neck, h=top);
    }
  }


  for (i = [0 : len(holes) - 1])
      assign(l = holes[i][0],
             r_neck = circle_radius(holes[i][1])
            ) {

    translate([0, 0, top / 2])
       rotate(ang * i, v=[0, 0, 1])
         rotate(45, v=[0, 1, 0])
           translate([0, 0, top / 2 - THICKNESS])
             neck_tube(r_neck, l);
  }
}

module helmholtz_cube(v, l, a) {
  r_neck = circle_radius(a);
  side = pow(v, 1 / 3);

  top = side * 1.5;

  difference() {
    trunc_cube(side + 2 * THICKNESS);
    translate([0, 0, THICKNESS])
      trunc_cube(side);
    translate([0, 0, top / 2])
      cylinder(r=r_neck, h=top);
  }

  translate([0, 0, top - THICKNESS])
    neck_tube(r_neck, l);
}

module neck_tube(r, l) {
  difference() {
    cylinder(r=r + THICKNESS, h=l);
    translate([0, 0, -E])
      cylinder(r=r, h=l + 2 * E);
  }
}

module trunc_sphere(r) {
  difference() {
    translate([0, 0, 2 * r * (TRUNCATE - 0.5)])
      sphere(r);
    translate([0, 0, -r])
      cube([2 * r, 2 * r, 2 * r], center=true);
  }
}

module trunc_cube(side) {
  difference() {
    translate([0, 0, side * .75])
      rotate(a=-atan(1/sqrt(2)), v=[1, 0, 0])
        rotate(a=45, v=[0, 1, 0])
          cube(side, center=true);
    translate([0, 0, -side])
      cube([2 * side, 2 * side, 2 * side], center=true);
    translate([0, 0, side * 2.5])
      cube([2 * side, 2 * side, 2 * side], center=true);
  }
}

// Note: Unfortunately, OpenSCAD does not allow for passing module parameters
// via the child() function, otherwise this could be made a generic
// grid replicator.
module grid_samples(samples, spacing=50) {
  count = len(samples);
  cols = ceil(sqrt(count));
  rows = ceil(count / cols);

  for (i = [0: count - 1]) assign(r = floor(i / cols), c = i % cols) {
    translate([c * spacing, (rows - r - 1) * spacing, 0])
      helmholtz(samples[i]);
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


/*
grid_samples([
  // v, l, a, t
  [32000, 20, 30, "c"],
  //[32000, 80, 30, "s"],
  //[32000, 20, 30, "s"],
  ]);
*/

// l, a pairs
helmholtz_holes(32000, [[20, 30], [40, 30], [60, 30]]);