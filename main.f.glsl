#version 100
precision highp float;

#define PI 3.141592653589
#define PHI 1.618033988749894848204586834
#define DIVIDER (3./2.) * PI
#define INNER_BIAS 1.
#define RESOLUTION 0.5
#define THICKNESS 0.003

// Pull in program data
uniform vec2 winsize;
uniform float minwid;
uniform int now;
uniform sampler2D backbuffer;

// Add all of the cubes together, perform a cube root, then multiply x to the result.
float treeavg(float x, float y, float z) {
#define POWER 3.
#define ROOT 3.    
    float xp = pow(x, POWER);
    float yp = pow(y, POWER);
    float zp = pow(z, POWER);

    return x * pow(xp + yp + zp, 1./ROOT);
}

// Draw a line from UV coord p1 to UV coord p2 with UV scale thickness
float drawLine(vec2 p1, vec2 p2, float thickness) {
  vec2 uv = gl_FragCoord.xy / vec2(RESOLUTION, RESOLUTION);

  float a = abs(distance(p1, uv));
  float b = abs(distance(p2, uv));
  float c = abs(distance(p1, p2));

  if (a >= c || b >=  c) return 0.0;

  float p = (a + b + c) * 0.5;

  // median to (p1, p2) vector
  float h = 2. / c * sqrt(p * (p - a) * (p - b) * (p - c));

  return mix(1.0, 0.0, smoothstep(0.5 * thickness, 1.5 * thickness, h));
}

vec2 cpotential(vec2 pos, float size, float bias, float spread, float angle) {
    // Grab the center of the canvas according to the shortest side. Put into an
    // approximate range of [-1., 1.].
    vec2 center = ((2.0 * (gl_FragCoord.xy / winsize)) - INNER_BIAS) 
        * ((winsize * DIVIDER) / minwid);
    
    // Get the distance from the center in the function
    float mag = (sqrt(pow((center.x - pos.x)/size, 2.) + pow((center.y - pos.y)/size, 2.)) - bias);
    if (mag < 0.) return vec2(0.);

    // Calculate the normal distribution exponent at the mean of 1/e in the entropy function.
    float gaussexp = -(0.5 * pow(((mag - exp(-1.)) / (spread * (1. - exp(-1.)))), 2.));

    // Apply the exponential to the natural entropy function, making an action potential.
    float apotential = -mag * log(mag) * exp(1. + gaussexp);

    // Convert to a complex number
    float resultAngle = atan(center.y - pos.y, center.x - pos.x) + angle;
    return vec2(sin(resultAngle) * apotential, cos(resultAngle) * apotential);
}

void main() {
    // Add the date to the angle for some sort of motion, slow, but motion.
    float baseangle = (2. * PI * mod(float(now)/196883., 1.));

    // Add an action potential with the initial branch sitting at the center
    vec2 cintense = 1./((1./cpotential(vec2(0.), 0.85, 1., 1., baseangle)) + (1./cpotential(vec2(0.), 1., 1., 1., baseangle*2.)));
    float angle = atan(cintense.y, cintense.x);
    float intense = sqrt(pow(cintense.x, 2.) + pow(cintense.y, 2.));

    // Negative pixel values don't work well. To handle this, if the intensity
    // goes negative, the phase is flipped
    if (intense < 0.) {
        angle += PI;
        intense = -intense;
    }

    // Apply the angle to the color wheel in a 3 phased fasion
    float b = (sin(angle) + 1.) / 2.;
    float r = (sin((PI/3.)-angle) + 1.) / 2.;
    float g = (-sin((2.*PI/3.)-angle) + 1.) / 2.;

    // Logrithmically scale values to make blend work more naturally.
    r = treeavg(r, g, b);
    b = treeavg(b, g, r);
    g = treeavg(g, r, b);

    // Apply the color and intensity to the display
    vec3 precolor = vec3(r, g, b);
    gl_FragColor = vec4(precolor * intense, 1.0);
}
