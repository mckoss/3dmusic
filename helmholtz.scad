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

  r_neck = circle_radius(a);
  r_neck_outer = r_neck + THICKNESS;
  v_neck = a * l;

  // Effective length add 0.6r on outer edge and 1.0r for inner edge.
  eff_l = l + RADIUS_TO_LENGTH * r_neck;
  echo("Predicted frequency", C * sqrt(a / v / eff_l));

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
    difference() {
      cylinder(r=r_neck_outer, h=l);
      translate([0, 0, -E])
        cylinder(r=r_neck, h=l + 2 * E);
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

module grid_samples(samples, spacing=50) {
  count = len(samples);
  cols = ceil(sqrt(count));
  rows = ceil(count / cols);

  for (r = [0, rows - 1]) {
    for (c = [0, cols - 1]) assign(i = r * cols + c) {
      if (i < count) {
        translate([c * spacing, (rows - r - 1) * spacing, 0])
          helmholtz(samples[i]);
      }
    }
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

v_base = 20 * 20 * 20;
grid_samples([[v_base, 20, 30], [v_base / 4, 20, 30], [v_base * 4, 20, 30]]);
