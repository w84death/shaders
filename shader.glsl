/*
 * SHADER BY KRZYSZTOF KRYSTIAN JANKOWSKI
 * (c)2023.04 P1X
 *
 * Introducing the Demoscene Tool for Fullscreen Shader Demos,
 * a cutting-edge WebGL (GLSL) powered application crafted by
 * the collaborative efforts of ChatGPT 4 and KKJ from the P1X group.
 *
 * */

precision mediump float;
varying vec2 v_uv;
uniform float u_time;
uniform vec2 u_resolution;

/*
 * SDF BRUSHES
 * https://iquilezles.org/articles/distfunctions/
 *
 * */
float sdSphere( vec3 p, float s ){return length(p)-s;}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

/*
 * SDF OPs
 *
 * */
float opUnion( float d1, float d2 ) { return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }

/*
 * COMBINE SDF WORLD
 *
 * */
float map(in vec3 pos){
    float ground = pos.y + 0.1;

    pos -= vec3(.0,-0.8+sin(-1.5+u_time*.5)*1.4,.0);


    float p1 = sdBox(pos-vec3(-0.7,0.95,.0),vec3(0.05,0.95,0.05));
    float p2 = sdBox(pos-vec3(-0.5,1.85,.0),vec3(0.15,0.05,0.05));
    float p3 = sdBox(pos-vec3(-0.5,0.95,.0),vec3(0.15,0.05,0.05));
    float p4 = sdBox(pos-vec3(-0.3,1.40,.0),vec3(0.05,0.50,0.05));
    float p_ = opUnion(p1,opUnion(p4,opUnion(p2,p3)));

    float i1 = sdBox(pos-vec3(.0,0.95,.0),vec3(0.05,0.95,0.05));
    float i2 = sdBox(pos-vec3(-.1,1.75,.0),vec3(0.05,0.05,0.05));
    float i_ = opUnion(i1,i2);

    float x1 = sdBox(pos-vec3(0.3,1.55,.0),vec3(0.05,0.35,0.05));
    float x2 = sdBox(pos-vec3(0.7,1.55,.0),vec3(0.05,0.35,0.05));
    float x3 = sdBox(pos-vec3(0.3,0.45,.0),vec3(0.05,0.45,0.05));
    float x4 = sdBox(pos-vec3(0.7,0.45,.0),vec3(0.05,0.45,0.05));
    float x5 = sdBox(pos-vec3(0.4,1.15,.0),vec3(0.05,0.05,0.05));
    float x6 = sdBox(pos-vec3(0.6,1.15,.0),vec3(0.05,0.05,0.05));
    float x7 = sdBox(pos-vec3(0.4,0.95,.0),vec3(0.05,0.05,0.05));
    float x8 = sdBox(pos-vec3(0.6,0.95,.0),vec3(0.05,0.05,0.05));
    float x9 = sdBox(pos-vec3(0.5,1.05,.0),vec3(0.05,0.05,0.05));
    float x_ = opUnion(x1,opUnion(x2,opUnion(x3,opUnion(x4,opUnion(x5,opUnion(x6,opUnion(x7,opUnion(x8,x9))))))));

    float scene=opUnion(p_,opUnion(i_,x_));
    return opSmoothUnion(ground,scene,0.1);
}

/*
 * NORMALS
 *
 * */
vec3 calcNormal( in vec3 pos){
    vec2 e = vec2(0.0001,0.0);
    return normalize(
        vec3(map(pos+e.xyy)-map(pos-e.xyy),
             map(pos+e.yxy)-map(pos-e.yxy),
             map(pos+e.yyx)-map(pos-e.yyx)));
}

/*
 * RAYCASTING
 *
 * */
float castRay(in vec3 ro, vec3 rd){
   float t = 0.0;
    for (int i=0; i<100; i++){
        vec3 pos = ro + t*rd;
        float dis = map(pos);
        if (dis<0.001) break;
        t+=dis;
        if (t>20.0) break;
    }
    if (t>20.0) t = -1.0;
    return t;
}

/*
 * THE RENDERER
 *
 * */
vec3 render(in vec2 p){
    vec3 ro = vec3(.0,.0,1.5-sin(u_time*.5)*.5);
    vec3 ta = vec3(.0,.5+sin(u_time*.5)*.3,.0);

    vec3 ww = normalize (ta-ro);
    vec3 uu = normalize( cross(ww, vec3(0,1,0)));
    vec3 vv = normalize (cross(uu,ww));

    vec3 rd = normalize(p.x*uu+p.y*vv+1.5*ww);

    vec3 col = vec3(0.4,0.75,1.0) - 0.5*rd.y;
    col =  mix(col, vec3(0.7,0.8,0.8), exp(-10.0*rd.y));

    vec3 mate = vec3(0.2);
    float t = castRay(ro,rd);

    if (t>0.0){
        vec3 pos = ro+t*rd;
        vec3 nor = calcNormal(pos);
        vec3 sun_dir = normalize(vec3(0.6,0.8,-0.2));
        float sun_shadow = step(castRay( pos+nor*0.001, sun_dir), 0.0);
        float sun_dif = clamp(dot(nor,sun_dir),0.0,1.0);
        float sky_dif = clamp(0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0)),0.0,1.0);
        float bou_dif = clamp(0.5 + 0.5*dot(nor,vec3(0.0,-1.0,0.0)),0.0,1.0);

        col  = mate*vec3(2.5,2.0,0.0);
        col += mate*vec3(5.0,3.0,2.0)*sun_dif*sun_shadow;
        col += mate*vec3(0.5,0.8,0.9)*sky_dif;
        col += mate*vec3(0.7,0.3,0.2)*bou_dif;

    }
    return col;
}

/*
 * UV SCREEN RATIO
 *
 * */
vec2 getUV(in vec2 fragCoord, vec2 offset){
  return (2.0*fragCoord * u_resolution.xy)/ u_resolution.y;
}

/*
 * 4xAA
 *
 * */
vec3 renderAAAA(in vec2 fragCoord){
    vec4 e =vec4(0.125,-0.125,0.375,-0.375);
    vec3 colAA = render(getUV(fragCoord,e.xz))+
    render(getUV(fragCoord,e.yw))+
    render(getUV(fragCoord,e.wx))+
    render(getUV(fragCoord,e.zy));

    return colAA/=4.0;
}

/*
 * MAIN
 *
 * */
void main() {
  //vec3 col = renderAAAA(v_uv);
  vec3 col = render(getUV(v_uv,vec2(.0,.0)));

  col = pow (col, vec3(0.4545));
  gl_FragColor = vec4(col, 1.0);
}

/*
 * END OF LISTING
 *
 * */
