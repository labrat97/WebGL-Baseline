#version 100
precision highp float;

#define PI 3.141592653589
#define PHI 1.618033988749894848204586834
#define DIVIDER PI

uniform vec2 winsize;
uniform float minwid;
uniform int now;

void main() {
    // Grab the center of the canvas according to the shortest side
    vec2 center = ((2.0 * (gl_FragCoord.xy / winsize)) - 1.0) 
        * ((winsize * DIVIDER) / minwid);
    float mag = sqrt(pow(center.x, 2.) + pow(center.y, 2.));

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
    r = log2(r+1.);
    b = log2(b+1.);
    g = log2(g+1.);

    // Apply the color and intensity to the display
    vec3 precolor = vec3(r, g, b);
    gl_FragColor = vec4(precolor * intense, 1.0);
}
