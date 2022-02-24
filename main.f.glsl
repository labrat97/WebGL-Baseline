precision mediump float;

// Defines required for proper program run
#define PHI ((sqrt(5.)+1.)/2.)
#define PI 3.141592653589793238462643383279502884197169399375105820974944592307
#define TAU (2.*PI)

void main() {
    float dist = length(gl_PointCoord.xy-0.5)*2.;
    float val = 0.;
    if (dist <= 1.) {
        val = 1.;
    }
    gl_FragColor = vec4(1.,1.,1.,val);
}
