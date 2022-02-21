#version 100
precision mediump float;

// Defines required for proper program run
#define GRADIENT_DELTA 0.
#define FUDGE_FACTOR 0.
#define COMPARE_FUDGE_FACTOR 1.
#define PHI ((sqrt(5.)+1.)/2.)
#define MAX_RADIUS 0.5
#define PI 3.14159265358
#define RING_COUNT 8

// Bring in the outside information needed for updating
uniform float now;
uniform vec2 winsize;
uniform float minwid;
uniform float maxwid;
#define time ((1.-pow(now/PHI, -PHI))*now)
#define size vec2(minwid)

float rndStart(vec2 co){return fract(sin(dot(co,vec2(123.42,117.853)))*412.453);}

float length2( vec2 p )
{
	return sqrt( p.x*p.x + p.y*p.y );
}

float length6( vec2 p )
{
	p = p*p*p; p = p*p;
	return pow( p.x + p.y, 1.0/6.0 );
}

float length8( vec2 p )
{
	p = p*p; p = p*p; p = p*p;
	return pow( p.x + p.y, 1.0/8.0 );
}

float sdTorus82( vec3 p, vec2 t )
{
  vec2 q = vec2(length2(p.xz)-t.x,p.y);
  return length8(q)-t.y;
}

float sdTorus88( vec3 p, vec2 t )
{
  vec2 q = vec2(length8(p.xz)-t.x,p.y);
  return length8(q)-t.y;
}

float sdTorus( vec3 p, vec2 t )
{
  return length( vec2(length(p.xz)-t.x,p.y))-t.y;
}

mat3 rotateY(float r)
{
    vec2 cs = vec2(cos(r), sin(r));
    return mat3(cs.x, 0, cs.y, 0, 1, 0, -cs.y, 0, cs.x);
}

mat3 rotateZ(float r)
{
    vec2 cs = vec2(cos(-r), sin(-r));
    return mat3(cs.x, cs.y, 0., -cs.y, cs.x, 0., 0., 0., 1.);
}

bool randRinged = false;
float randRing[32];
void startRing(vec2 seed) {
    if (randRinged) return;

    float pre = sqrt(seed.x * seed.y);
    randRing[0] = rndStart(seed);
    for (int i = 1; i < 32; i++) {
        float valStart = rndStart(vec2(randRing[i-1], pre));
        randRing[i] = 1./(1.+exp(-valStart));
        pre = randRing[i-1];
    }

    randRinged = true;
}

float DE(vec3 p0)
{
    float t = time;
    vec3 p = p0;
	float d = length(p0)+1.;
    float r = (1.+PHI)*(MAX_RADIUS);
    for(int i = 0; i < RING_COUNT; ++i)
    {
        p *= rotateZ(t*float(i+1)/(float(RING_COUNT)*pow(PHI, float(i)*PHI))) * rotateY(t*PI*float(i+1)/(float(RING_COUNT)*pow(PHI, float(i)*PHI)));
        d = min(d, sdTorus(p, vec2(r, 0.01)));
        r -= .1+((1.-(1./(1.+log((2.*now/float(RING_COUNT))+1.))))*.04);
    }
    return d;
}

vec2 DDE(vec3 p, vec3 rd){
	float d1=DE(p);
  	return vec2(d1,d1*COMPARE_FUDGE_FACTOR);
	float dt=GRADIENT_DELTA*log(d1+1.0);
	float d2=DE(p+rd*dt);
	dt/=max(dt,d1-d2);
	return vec2(d1,FUDGE_FACTOR*log(d1*dt+1.0));
}

mat3 lookat(vec3 fw,vec3 up){
	fw=normalize(fw);vec3 rt=normalize(cross(fw,up));return mat3(rt,cross(rt,fw),fw);
}

vec3 normal(vec3 p)
{
    vec2 eps = vec2(.001, 0.);
    return normalize(vec3(
        DE(p+eps.xyy) - DE(p-eps.xyy),
        DE(p+eps.yxy) - DE(p-eps.yxy),
        DE(p+eps.yyx) - DE(p-eps.yyx)));
}

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	return c.z * mix( vec3(1.0), rgb, c.y);
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = DE( aopos );
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}


vec3 compute_color(vec3 ro, vec3 rd, float t)
{
    vec3 l = normalize(vec3(0., .7, .2));
    vec3 p = ro+rd*t;
    vec3 nor = normal(p);
    vec3 ref = reflect(rd, nor);
    
    vec3 c = hsv2rgb(vec3(0.125-((pow(length(p),PHI))*exp(-PHI)), 1., 1.));
    
    
    float dif = clamp( dot( nor, l ), 0.0, 1.0 );
    float dom = smoothstep( -0.1, 0.1, ref.y );
   	float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
    
    float ao = calcAO(p, nor);
    
    vec3 v = vec3(0.);
    v += .3*vec3(dif);
    v += .3*dom*vec3(.6, .7, .9)*ao;
    v += .6*fre*vec3(.7, .8, .6)*ao;
 	return c*v;
}

vec4 pixel(vec2 pxx)
{
    // Branch out from the full computation if available
    vec2 centerRaw = winsize/2.;
    float dist = sqrt(pow(gl_FragCoord.x-centerRaw.x, 2.) + pow(gl_FragCoord.y-centerRaw.y, 2.));
    float distRel = dist/minwid;
    if (distRel > MAX_RADIUS) return vec4(0., 0., 0., 1.);

    // Get current external marking location parameters
    float pxl=4.0/size.y;//find the pixel size
	float tim=time*0.03+(0.5)*5.;
	
	//position camera
	vec3 ro=vec3(PI/2.,0.,0.)*3.4;
	vec3 rd=normalize(vec3((2.0*pxx-winsize.xy)/size.y,PI));
	rd=lookat(-ro,vec3(0.0,1.0,0.0))*rd;
	//ro=eye;rd=normalize(dir);
	vec3 bcol=vec3(1.0);
	//march
	
	float t=DDE(ro,rd).y*rndStart(pxx),d,od=1.0;
    bool hit = false;
	vec4 col=vec4(0.);//color accumulator
	for(int i=0;i<144;i++){
		vec2 v=DDE(ro+rd*t,rd);
		d=v.x;//DE(ro+rd*t);
		float px=pxl*(1.0+t);
		if(d<px){
            hit = true;
            break;
		}
		od=d;
		t+=v.y;//d;
		if(t>10.0)break;
	}

    if (hit) {
        return vec4(compute_color(ro, rd, t), 1.);
    }

    float blankHue = 0.04*(cos(0.3*now+rndStart(pxx))+(1.-(1./PHI)))/2.;
    float saturation = 1.;
    float alpha = 1./(1.+exp(-(now-PI)));
    float value = 0.5*exp(-pow(distRel*2.*PI,2.)/2.)*alpha;
    return vec4(hsv2rgb(vec3(blankHue, saturation, value)), alpha);
}
void main() {
    startRing(gl_FragCoord.xy);
    vec2 xy = (gl_FragCoord.xy/size);
	float v = .6 + 0.4*pow(20.0*xy.x*xy.y*(1.0-xy.x)*(1.0-xy.y), 0.5);
	gl_FragColor=pixel(gl_FragCoord.xy);
} 