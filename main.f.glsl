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


vec3 _toroid(float p, float q, float theta, float outer, float innerGain) {
    float inner = outer * innerGain;

    float r = ((outer-inner)*pcos(p*theta/q))+inner;
    float x = r*cos(theta);
    float y = r*sin(theta);
    float z = (inner-outer)*psin(q*theta);

    return vec3(x,y,z);
}
vec4 toroid(vec2 posrel, vec2 posbias, float p, float q, float outer, float inner, vec3 pyr) {
    // Center and scale the frag coords, centering again with the newcenter variable
    // This will serve as the variable for the position in toroid-space relative to the center of the knot
    vec2 posrelcent = (posrel-posbias);

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

        if (i >= int(0.5+((p-1.)*(q-1.)))) break;
    }

    return vec4((result) + vec3(posbias, 0.), minrot);
}

void main() {
    vec2 posrel = ((gl_FragCoord.xy-(winsize/2.))/(minwid/2.));
    vec2 posbias = vec2(0.);
    vec3 rot = vec3(PI/6.,0.,0.);
    mat3 rotm = rotateX(rot.x) * rotateY(rot.y) * rotateZ(rot.z);

    vec4 tor = toroid(posrel, posbias, 9., 7., 5.*cos(time/7.), sin(time/5.)+1., rot);
    vec3 torrot = rotm * tor.xyz;
    float torlen = length(tor.xy-posrel);
    tor = toroid(posrel, posbias, 3., 2., 4.*(cos(time/7.)-0.5), 7.*sin(time/5.), rot);
    torlen = min(torlen, length(tor.xy-posrel));
    gl_FragColor = torlen < 0.003 ? vec4(1.) : vec4(0.);
}
