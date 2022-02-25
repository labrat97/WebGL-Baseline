precision mediump float;

uniform vec2 center;
uniform vec3 rotation;
uniform float now;
uniform vec2 winsize;
uniform float minwid;
uniform float maxwid;

attribute vec4 inPos;

varying float knotSel;
varying float knotDepth;

#define PHI ((sqrt(5.)+1.)/2.)
#define PI 3.141592653589793238462643383279502884197169399375105820974944592307
#define TAU (2.*PI)
#define MAX_RADIUS .9
#define MIN_RADIUS (PI/4.)
#define MAX_INNER_GAIN 0.8
#define MIN_INNER_GAIN 0.4
#define INNER_SEP 3.
#define EPS 0.0000000001
#define time ((1.-pow(now+0.5, -PI))*now/2.)


float sigmoid(float xin) {
    return 1./(1.+exp(-xin));
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
mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, s, 0),
        vec3(-s,c, 0),
        vec3(0, 0, 1)
    );
}
vec3 _toroid(float p, float q, float theta, float phi, float outer, float innerGain) {
    float inner = outer*innerGain;
    float skiniter = p*(theta+phi)/q;
    float r = ((outer-inner)*pcos(skiniter))+inner;
    float x = r*cos(theta);
    float y = r*sin(theta);
    float z = (inner-outer)*sin(skiniter)/2.;

    return vec3(x,y,z);
}
vec3 toroid(float trace, float p, float q, float outer, float inner, vec3 pyr, vec3 rotbias) {
    // Calculate all of the rotation matrices
    mat3 rotX = rotateX(pyr.x);
    mat3 rotY = rotateY(pyr.y);
    mat3 rotZ = rotateZ(pyr.z);
    mat3 rot = rotX * rotY * rotZ;

    // Softly bound the inner and outer radii so that the knot fits in the screen
    float outbound = ((MAX_RADIUS-MIN_RADIUS)*sigmoid(outer))+MIN_RADIUS;
    float inbound = ((MAX_INNER_GAIN-MIN_INNER_GAIN)*sigmoid(inner))+MIN_INNER_GAIN;

    // Calculate the first result
    vec3 result = rot * (rotbias+_toroid(p, q, trace, 0., outbound, inbound));
    return result;
}

void main() {
    // Extract the data from the input attributes to be warped
    float wp = inPos.p;
    float wq = inPos.q;
    float inrot = inPos.s;
    knotSel = inPos.t;
    float knotSelMajor = float(int((knotSel+1.)/2.));
    float sep = 0.;
    if ((knotSel/2.)-knotSelMajor > EPS) {
        sep = INNER_SEP;
    }

    // Create base rotations for the vertex
    float theta = TAU * inPos.x * wp * wq;
    vec3 lrot = rotation;
    lrot.z -= pow(knotSel+1., sqrt(PHI/4.))*time/3.;
    lrot.x *= -1.;

    // Map rotational coordinate to the toroid
    vec3 tor = toroid(theta, wp, wq, (PI*(cos(time)-(TAU*knotSelMajor+1.))) - sep, 
        (3.*(knotSelMajor+1.)*sin(time/PHI))+sep, lrot*((knotSel+5.))/9.,
        vec3(0.,0.,-knotSelMajor/(PHI*PI)))*(1.-(knotSelMajor/TAU));
    
    // Make all data needed available to the fragment shader
    gl_Position = vec4(vec2(tor.xy*minwid/winsize), tor.z, 1.);
    knotDepth = tor.z;
    gl_PointSize = (minwid/512.)*exp(-PI*tor.z)*(1.+knotSelMajor/2.);
}
