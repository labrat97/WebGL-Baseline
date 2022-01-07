#version 100
precision highp float;

#define PI 3.141592653589
#define PHI 1.618033988749894848204586834
#define DIVIDER PI

uniform vec2 winsize;
uniform float minwid;
uniform int now;

void main() {
    vec2 center = ((2.0 * (gl_FragCoord.xy / winsize)) - 1.0) 
        * ((winsize * DIVIDER) / minwid);
    float mag = sqrt(pow(center.x, 2.) + pow(center.y, 2.));
    float angle = atan(center.y, center.x) + (2. * PI * mod(float(now)/196883., 1.));

    float gaussexp = -(0.5 * pow(((mag - exp(-1.)) / (1. - exp(-1.))), 2.));
    float intense = -mag * log(mag) * exp(1. + gaussexp);
    if (intense < 0.) {
        angle += PI;
        intense = -intense;
    }

    float b = (sin(angle) + 1.) / 2.;
    float r = (sin((PI/3.)-angle) + 1.) / 2.;
    float g = (-sin((2.*PI/3.)-angle) + 1.) / 2.;
    r = log2(r+1.);
    b = log2(b+1.);
    g = log2(g+1.);

    vec3 precolor = vec3(r, g, b);
    gl_FragColor = vec4(precolor * intense, 1.0);
}
