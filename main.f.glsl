#version 100
precision highp float;

// Defines required for proper program run
#define PHI ((sqrt(5.)+1.)/2.)
#define PI 3.141592653589793238462643383279502884197169399375105820974944592307
#define MAX_RADIUS (PI/4.)
#define MIN_RADIUS (PI/7.)
#define MAX_INNER_GAIN 0.8
#define MIN_INNER_GAIN 0.2


// Bring in the outside information needed for updating
uniform float now;
uniform vec2 winsize;
uniform float minwid;
uniform float maxwid;
#define time ((1.-pow(now/PHI, -PHI))*now)
#define size vec2(minwid)

//float rndStart(vec2 co){return fract(sin(dot(co,vec2(123.42,117.853)))*412.453);}

float tanh(float xin) {
    float top = exp(xin)-exp(-xin);
    float bottom = exp(xin)+exp(-xin);

    return top/bottom;
}

float sigmoid(float xin) {
    return 1./(1.+exp(-xin));
}

float psin(float xin) {
    return (sin(xin)+1.)/2.;
}
float pcos(float xin) {
    return (cos(xin)+1.)/2.;
}

vec3 _toroid(float p, float q, float theta, float outer, float innerGain) {
    float inner = outer * innerGain;

    float r = ((outer-inner)*pcos(p*theta/q))+inner;
    float x = r*cos(theta);
    float y = r*sin(theta);
    float z = (inner-outer)*sin(q*theta);

    return vec3(x,y,z);
}
vec3 toroid(vec2 posrel, vec2 posbias, float p, float q, float outer, float inner) {
    // Center and scale the frag coords, centering again with the newcenter variable
    // This will serve as the variable for the position in toroid-space relative to the center of the knot
    vec2 posrelcent = posrel-posbias;

    // Get the angle of rotation from the start for the relative position of the toroid
    float theta = atan(posrelcent.y, posrelcent.x);

    // Softly bound the inner and outer radii so that the knot fits in the screen
    float outbound = ((MAX_RADIUS-MIN_RADIUS)*sigmoid(outer))+MIN_RADIUS;
    float inbound = ((MAX_INNER_GAIN-MIN_INNER_GAIN)*sigmoid(inner))+MIN_INNER_GAIN;

    // Calculate the first result
    vec3 result = _toroid(p, q, theta, outbound, inbound);

    // Check the distance from the relative center to the first result
    float dist = length(result.xy-posrelcent);
    float minrot = theta;
    for (int i = 1; i > 0; i++) {
        vec3 temp = _toroid(p, q, theta+(2.*float(i)*PI), outbound, inbound);
        float tdst = length(temp.xy-posrelcent);
        if (tdst < dist) {
            dist = tdst;
            result = temp;
            minrot = theta+(2.*float(i)*PI);
        }

        if (i >= int(((p-1.)*(q-1.))+0.5)) break;
    }

    return vec3(dist, result.z, minrot);
}

void main() {
    vec2 posrel = ((gl_FragCoord.xy-(winsize/2.))/(minwid/2.));
    vec3 dist = toroid(posrel, vec2(.0,.0), 9., 7., 1., -5.);
    float intensity = length(dist.x) < 0.01 ? 1. : 0.;
    gl_FragColor = vec4(intensity,intensity,intensity,1.);
}
