precision highp float;

uniform vec2 center;
uniform float pval;
uniform float qval;
uniform vec3 rotation;
uniform float now;
uniform vec2 winsize;
uniform float minwid;
uniform float maxwid;

attribute vec4 inPos;

#define PHI ((sqrt(5.)+1.)/2.)
#define PI 3.141592653589793238462643383279502884197169399375105820974944592307
#define TAU (2.*PI)
#define MAX_RADIUS (PI/4.)
#define MIN_RADIUS (PI/7.)
#define MAX_INNER_GAIN 0.8
#define MIN_INNER_GAIN 0.2
#define time ((1.-pow(now+0.5, -PI))*now/2.)


float sigmoid(float xin) {
    return 1./(1.+exp(-xin));
}
float pcos(float xin) {
    return (cos(xin)+1.)/2.;
}
float psin(float xin) {
    return (sin(xin)+1.)/2.;
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
vec3 _toroid(float p, float q, float theta, float phi, float outer, float innerGain) {
    float inner = outer*innerGain;
    float skiniter = p*(theta+phi)/q;
    float r = ((outer-inner)*pcos(skiniter))+inner;
    float x = r*cos(theta);
    float y = r*sin(theta);
    float z = (outer-inner)*psin(skiniter)/2.;

    return vec3(x,y,z);
}
vec3 toroid(float trace, float p, float q, float outer, float inner, vec3 pyr) {
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

// Really not doing anything with this right now
void main() {
    float rot = TAU * inPos.x * (pval - 1.) * (qval - 1.);
    vec3 tor = toroid(rot, pval, qval, 5.*cos(time), 5.*sin(time/PHI), rotation);
    gl_Position = vec4(vec2(tor.xy*minwid/winsize), tor.z, 1.);
    gl_PointSize = pow((normalize(gl_Position.xyz).z+1.5), 2.);
}
