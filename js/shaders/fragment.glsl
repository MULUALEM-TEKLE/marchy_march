uniform float time;
uniform float progress;
uniform sampler2D texture1;
uniform vec4  resolution;

varying vec2 vUv;
varying vec3 vPosition;

float PI = 3.141592653;


mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
	mat4 m = rotationMatrix(axis, angle);
	return (m * vec4(v, 1.0)).xyz;
}

/* 
SMIN function types
 */

// polynomial smooth min 1 (k=0.1)
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
/*
 // exponential smooth min (k=32)
float smin( float a, float b, float k )
{
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}
// power smooth min (k=8)
float smin( float a, float b, float k )
{
    a = pow( a, k ); b = pow( b, k );
    return pow( (a*b)/(a+b), 1.0/k );
}
// root smooth min (k=0.01)
float smin( float a, float b, float k )
{
    float h = a-b;
    return 0.5*( (a+b) - sqrt(h*h+k) );
}
// polynomial smooth min 1 (k=0.1)
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
// polynomial smooth min 2 (k=0.1)
float smin( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
} */


float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdSphere( vec3 p, float r )
{
  return length(p)-r;
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdOctahedron( vec3 p, float s)
{
  p = abs(p);
  float m = p.x+p.y+p.z-s;
  vec3 q;
       if( 3.0*p.x < m ) q = p.xyz;
  else if( 3.0*p.y < m ) q = p.yzx;
  else if( 3.0*p.z < m ) q = p.zxy;
  else return m*0.57735027;
    
  float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
  return length(vec3(q.x,q.y-s+k,q.z-k)); 
}

float sdf(vec3 p){
    vec3 p1 = rotate(p , vec3(1.) , time/15.);
    vec3 p2 = rotate(p , vec3(1.) , time/5.);
    float box = sdBox(p1 , vec3(0.3));
    float sphere = sdSphere(p , 0.4);
    float torus = sdTorus(p , vec2(.2));
    float octahedron = sdOctahedron(p2 , .6);
    return smin(box, octahedron , 0.1);
}

  

vec3 calcNormal( in vec3 p ) // for function f(p)
{
    const float eps = 0.0001; // or some other value
    const vec2 h = vec2(eps,0);
    return normalize( vec3(sdf(p+h.xyy) - sdf(p-h.xyy),
                           sdf(p+h.yxy) - sdf(p-h.yxy),
                           sdf(p+h.yyx) - sdf(p-h.yyx) ) );
}


void main() {
    vec2 newUV  = (vUv - vec2(0.5)) * resolution.zw + vec2(.5);
    
    vec3 camPos = vec3(0. , 0. , 2.);
    vec3 ray = normalize(vec3( (vUv - vec2(0.5)) * resolution.zw , -1));


    vec3 rayPos = camPos;
    float t = 0.0;
    float tMax = 5.;

    for(int i = 0 ; i < 256 ; i++){
        vec3 pos = camPos + t * ray;
        float h = sdf(pos);

        if(h  < 0.0001 || t > tMax) break;
        t+=h;
    }

    vec3 color = vec3(0.);
    if(t < tMax){
        vec3 pos = camPos + t * ray;
        color = vec3(1.);
        vec3 normal = calcNormal(pos);
        color = normal;
        float diff = dot(vec3(1.) , normal);
        color = vec3(diff);
    }

    gl_FragColor = vec4(color , 1.0);
}