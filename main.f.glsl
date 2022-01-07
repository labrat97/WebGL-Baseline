#version 100
precision highp float;

#define PI 3.141592653589
#define PHI 1.618033988749894848204586834
#define DIVIDER (3./2.) * PI
#define INNER_BIAS 1.

// Pull in program data
uniform vec2 winsize;
uniform float minwid;
uniform int now;

// Add all of the cubes together, perform a cube root, then multiply x to the result.
float treeavg(float x, float y, float z) {
#define POWER 3.
#define ROOT 3.    
    float xp = pow(x, POWER);
    float yp = pow(y, POWER);
    float zp = pow(z, POWER);

    return x * pow(xp + yp + zp, 1./ROOT);
}

void main() {
    // Grab the center of the canvas according to the shortest side. Put into an
    // approximate range of [0., 1.].
    vec2 center = ((2.0 * (gl_FragCoord.xy / winsize)) - INNER_BIAS) 
        * ((winsize * DIVIDER) / minwid);

    // Get the distance from the center in the function. Due to the way that the
    // log() function is implemented, simply subtracting the bias of the pupil
    // accounds for the required floor function.
    float mag = sqrt(pow(center.x, 2.) + pow(center.y, 2.)) - 1.;

    // Add the date to the angle for some sort of motion, slow, but motion.
    float angle = atan(center.y, center.x) + (2. * PI * mod(float(now)/196883., 1.));

    // Add an action potential with the initial branch sitting at the center
    float gaussexp = -(0.5 * pow(((mag - exp(-1.)) / (1. - exp(-1.))), 2.));
    float intense = -mag * log(mag) * exp(1. + gaussexp);

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
