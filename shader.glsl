/*
 * SHADER BY KRZYSZTOF KRYSTIAN JANKOWSKI
 * MUSIC BY TimTaj (This Uplifting House)
 *
 * Introducing the Demoscene Tool for Fullscreen Shader Demos,
 * a cutting-edge WebGL (GLSL) powered application crafted by
 * the collaborative efforts of ChatGPT 4 and KKJ from the P1X group.
 *
 * *** WORK IN PROGRESS ***
 * This shader will change over time as I develop it.
 * Also there will be a huge refactor once I got everything right.
 *
 * (c)2023.04 P1X
 * */

precision mediump float;
varying vec2 v_uv;
uniform float u_time;
uniform vec2 u_resolution;
uniform float u_fft;

/*
 * SDF BRUSHES
 * https://iquilezles.org/articles/distfunctions/
 *
 * */
float sdSphere( vec3 p, float s){return length(p)-s;}

float sdBox( vec3 p, vec3 b){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdRoundBox( vec3 p, vec3 b, float r ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

/*
 * SDF OPs
 *
 * */
float opUnion( float d1, float d2) { return min(d1,d2); }

float opSubtraction( float d1, float d2) { return max(-d1,d2); }

float opIntersection( float d1, float d2) { return max(d1,d2); }

float opSmoothUnion( float d1, float d2, float k) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float opSmoothSubtraction( float d1, float d2, float k) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float opSmoothIntersection( float d1, float d2, float k) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }


float map(float value, float inputMin, float inputMax, float outputMin, float outputMax) {
    return outputMin + ((clamp(value, inputMin, inputMax) - inputMin) / (inputMax - inputMin)) * (outputMax - outputMin);
}

/*
 * COMBINE SDF WORLD
 *
 * */
vec2 map(in vec3 pos){
    float m = 1.0;
    float ground = pos.y + 0.1;

    float b1 = sdBox(pos-vec3(map(u_time,18.0,35.0,-3.0,-4.0),u_fft,map(u_time,18.0,35.0,-.5,1.0)),vec3(2.0,0.1+u_fft*2.0,0.05));
    float b2 = sdBox(pos-vec3(-1.0,u_fft*2.0,map(u_time,18.0,35.0,-1.0,-2.0)),vec3(2.0,0.1+u_fft*4.0,0.05));
    float b3 = sdBox(pos-vec3(1.0,u_fft*2.0,map(u_time,18.0,35.0,-1.0,-2.0)),vec3(2.0,0.1+u_fft*4.0,0.05));
    float b4 = sdBox(pos-vec3(map(u_time,18.0,35.0,3.0,4.0),u_fft,map(u_time,18.0,35.0,-.5,1.0)),vec3(2.0,0.1+u_fft*2.0,0.05));
    float b_ = opUnion(b1,opUnion(b2,opUnion(b3,b4)));

    if (b_<0.001) m=5.0;

    pos -= vec3(.0,map(u_time,.0,5.0,-2.2,.3),.0);

    float p1 = sdBox(pos-vec3(-0.7,0.95,.0),vec3(0.05,0.95,0.05));
    float p2 = sdBox(pos-vec3(-0.5,1.85,.0),vec3(0.15,0.05,0.05));
    float p3 = sdBox(pos-vec3(-0.5,0.95,.0),vec3(0.15,0.05,0.05));
    float p4 = sdBox(pos-vec3(-0.3,1.40,.0),vec3(0.05,0.50,0.05));
    float p_ = opUnion(p1,opUnion(p4,opUnion(p2,p3)));
    if (p_<0.001) m=2.0;

    float i1 = sdBox(pos-vec3(.0,0.95,.0),vec3(0.05,0.95,0.05));
    float i2 = sdBox(pos-vec3(-.1,1.75,.0),vec3(0.05,0.05,0.05));
    float i_ = opUnion(i1,i2);
    if (i_<0.001) m=3.0;

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
    if (x_<0.001) m=4.0;

    float p1x_=opUnion(p_,opUnion(i_,x_));
    return vec2(opSmoothUnion(ground,opUnion(p1x_,b_),0.1),m);
}

/*
 * NORMALS
 *
 * */
vec3 calcNormal(in vec3 pos){
    vec2 e = vec2(0.0001,0.0);
    return normalize(
        vec3(map(pos+e.xyy).x-map(pos-e.xyy).x,
             map(pos+e.yxy).x-map(pos-e.yxy).x,
             map(pos+e.yyx).x-map(pos-e.yyx).x));
}

/*
 * RAYCASTING
 *
 * */
vec2 castRay(in vec3 ro, vec3 rd){
   float t = 0.0;
   float m=-1.0;
    for (int i=0; i<100; i++){
        vec3 pos = ro + t*rd;
        vec2 scene = map(pos);
        m=scene.y;
        if (scene.x<0.001) break;
        t+=scene.x;
        if (t>20.0) break;
    }
    if (t>20.0) t = -1.0;
    return vec2(t,m);
}

/*
 * MATERIALS GENERATION
 *
 * */
vec3 getMaterial(vec3 p, float id){
    vec3 m=vec3(.0,.0,.0);

    if(id<1.5){
        m=vec3(mod(floor(p.x*8.0)+floor(p.z*8.0),2.0));
    }else
    if(id<2.5){
        m=vec3(4.0,.0,.0);
    }else
    if(id<3.5){
        m=vec3(.0,4.0,.0);
    }else
    if(id<4.5){
        m=vec3(.0,.0,4.0);
    }else
    if(id<5.5){
        float chess=mod(floor(p.x*4.0)*floor(p.y*4.0),2.0);
        m=vec3(map(u_fft,0.65,1.0,0.0,4.0)*chess,chess,chess);
    }

    return m;
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
    col *= map(u_time,0.0,3.0,.0,1.0);

    vec3 mate = vec3(0.2);
    vec2 ray = castRay(ro,rd);
    float t=ray.x;
    float m=ray.y;

    if (t>0.0){
        vec3 pos = ro+t*rd;
        vec3 nor = calcNormal(pos);
        vec3 sun_dir = normalize(vec3(sin(u_time*.25)*3.0,map(u_time,0.0,4.0,-1.0,3.0),cos(u_time*.25)*3.0));
        float sun_shadow = step(castRay(pos+nor*0.001, sun_dir).x, 0.0);
        float sun_dif = clamp(dot(nor,sun_dir),0.0,1.0);
        float sky_dif = clamp(0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0)),0.0,1.0);
        float bou_dif = clamp(0.5 + 0.5*dot(nor,vec3(0.0,-1.0,0.0)),0.0,1.0);

        col  = mate*getMaterial(pos,m);
        col += mate*vec3(5.0,3.0,2.0)*sun_dif*sun_shadow;
        col += mate*vec3(0.5,0.8,0.9)*sky_dif;
        col += mate*vec3(0.7,0.3,0.2)*bou_dif;
        col *= map(u_time,0.0,3.0,.1,1.0);
    }
    return col;
}

/*
 * UV SCREEN RATIO
 *
 * */
vec2 getUV(in vec2 fragCoord, vec2 offset){
  return (2.0*(fragCoord+offset) * u_resolution.xy)/ u_resolution.y;
}

/*
 * 4xAA
 *
 * */
vec3 renderAAAA(in vec2 fragCoord){
    vec4 e =vec4(0.125,-0.125,0.375,-0.375)*0.005;
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
  vec3 col = renderAAAA(v_uv);

  col = pow (col, vec3(0.4545));
  gl_FragColor = vec4(col, 1.0);
}

/*
 * END OF LISTING
 *
 * */
