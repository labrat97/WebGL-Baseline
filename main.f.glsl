precision mediump float;

varying float knotSel;
varying float knotDepth;

uniform float now;

// Defines required for proper program run
#define PHI ((sqrt(5.)+1.)/2.)
#define PI 3.141592653589793238462643383279502884197169399375105820974944592307
#define TAU (2.*PI)
#define EPS (1.*pow(10., -9.))
#define HUE_BIAS -PI/12.
#define HUE_STEP PI/9779.

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
float sigmoid(float xin) {
    return 1./(1.+exp(-xin));
}
float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    // Create rounded points
    float dist = length(gl_PointCoord-0.5)*2.;
    if (dist > 1.) {
        discard;
    }
    else {
        float distmod = sigmoid(PI*exp(-knotDepth));
        float noise = (sigmoid(rand(gl_FragCoord.xy+vec2(now)+gl_PointCoord.xy))-0.5);
        vec3 hsv = vec3(HUE_BIAS + (noise/PI) + pow(HUE_STEP*knotSel, 1./TAU), 1., distmod);
        vec3 rgb = hsv2rgb(hsv);
        gl_FragColor = vec4(rgb, 1.);
    }
}
