precision mediump float;

varying float ringSel;

// Defines required for proper program run
#define PHI ((sqrt(5.)+1.)/2.)
#define PI 3.141592653589793238462643383279502884197169399375105820974944592307
#define TAU (2.*PI)
#define EPS (1.*pow(10., -9.))

void main() {
    // Create rounded points
    float dist = length(gl_PointCoord-0.5)*2.;
    if (dist > 1.) {
        gl_FragColor = vec4(0.);
    }
    else {
        gl_FragColor = vec4(1.);
    }
}
