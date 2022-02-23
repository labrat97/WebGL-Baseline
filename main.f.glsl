#version 100
precision highp float;

// Defines required for proper program run
#define PHI ((sqrt(5.)+1.)/2.)
#define PI 3.141592653589793238462643383279502884197169399375105820974944592307
#define TAU (2.*PI)
#define MAX_RADIUS (PI/4.)
#define MIN_RADIUS (PI/7.)
#define MAX_INNER_GAIN 0.8
#define MIN_INNER_GAIN 0.2
#define TRACE_COUNT 255
#define _TRACE_ITER TAU/float(TRACE_COUNT)


// Bring in the outside information needed for updating
uniform float now;
uniform vec2 winsize;
uniform float minwid;
uniform float maxwid;
#define time ((1.-pow(now, -PI))*now)
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

// Rotation matrix around the X axis.
mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}
// Rotation matrix around the Y axis.
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}
// Rotation matrix around the Z axis.
mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}


vec3 _toroid(float p, float q, float theta, float phi, float outer, float innerGain) {
    float inner = outer*innerGain;
    float skiniter = p*(theta+phi)/q;
    float r = ((outer-inner)*pcos(skiniter))+inner;
    float x = r*cos(theta);
    float y = r*sin(theta);
    float z = (inner-outer)*sin(skiniter);

    return vec3(x,y,z);
}
vec3 toroid(float trace, vec2 posbias, float p, float q, float outer, float inner, vec3 pyr) {
    // Calculate all of the rotation matrices
    mat3 rotX = rotateX(pyr.x);
    mat3 rotY = rotateY(pyr.y);
    mat3 rot = rotX * rotY;

    // Softly bound the inner and outer radii so that the knot fits in the screen
    float outbound = ((MAX_RADIUS-MIN_RADIUS)*sigmoid(outer))+MIN_RADIUS;
    float inbound = ((MAX_INNER_GAIN-MIN_INNER_GAIN)*sigmoid(inner))+MIN_INNER_GAIN;

    // Calculate the first result
    vec3 result = rot * _toroid(p, q, trace, pyr.z, outbound, inbound);
    return result;
}

void main() {
    // Some running config
    vec2 posbias = vec2(0.0);
    vec3 rot = vec3(PI/4.,0.,PI/6.);
    vec4 bgColor = vec4(0.25,0.,0.,1.);

    // Get position relative to the toroid
    vec2 posrel = ((gl_FragCoord.xy-(winsize/2.))/(minwid/2.));
    vec3 posrot = rotateX(rot.x) * rotateY(rot.y) * vec3(posrel, 0.);
    float posrotlen = length(posrot);
    if (posrotlen > MAX_RADIUS || posrotlen < (MAX_RADIUS*MIN_INNER_GAIN)) {
        gl_FragColor = bgColor;
        return;
    }

    // Calulate outer toroidal distance
    vec3 tor = toroid(time, posbias, 9., 7., 5.*cos(time/7.), sin(time/5.)+1., rot);
    float torlen = length(tor.xy-posrel);
    float z = 0.;
    for (float idx = _TRACE_ITER; idx < TAU; idx += _TRACE_ITER) {
        tor = toroid(time+(48.*idx), posbias, 9., 7., 5.*cos(time/7.), sin(time/5.)+1., rot);
        float temp = length(tor.xy-posrel);
        if (temp < torlen) {
            torlen = temp;
            z = tor.z;
        }
    }

    // Render the locally closest toroid
    gl_FragColor = torlen < 0.007*(2.*sigmoid(z*3.)) ? vec4(1.) : bgColor;
}
