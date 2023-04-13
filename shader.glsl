/*
 * SHADER BY KRZYSZTOF KRYSTIAN JANKOWSKI / P1X
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

const float WORLD_MAX = 256.0;
const float WORLD_RES = 0.001;

const float MAT_GROUND = 1.0;
const float MAT_DARKBLUE = 2.0;
const float MAT_CITY = 3.0;
const float MAT_ASPHALT = 4.0;
const float MAT_CONCRETE = 5.0;
const float MAT_CHESS = 6.0;

const float T_SUNRISE=6.0;


/*
 * SDF BRUSHES
 * https://iquilezles.org/articles/distfunctions/
 *
 * */
float sdSphere( vec3 p, float s){
    return length(p)-s;
}

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
 * FAKE RANDOM GENERATOR
 *
 * */
float rnd(vec2 pos){
    return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
}

/*
 * COMBINE SDF WORLD
 *
 * */
vec2 sdfWorld(in vec3 pos){
    float m = MAT_GROUND;
    float ground = pos.y+0.1;

    vec3 qb = vec3(mod(abs(pos.x),20.0)-10.0,
                   pos.y,
                   mod(abs(pos.z),10.0)-5.0);

    vec2 bid=vec2(floor(abs(pos.x)/20.0),
                floor(abs(pos.z)/10.0));
    float bheight = 2.0+(rnd(bid)*15.0)*u_fft;
    float b_ = sdRoundBox(qb,vec3(6.0,bheight,3.0),0.2);

    if (b_<WORLD_RES) m=MAT_CITY;

    pos -= vec3(.0,map(u_time,.0,5.0,-2.2,.3),.0);

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

    float p1x_=opUnion(p_,opUnion(i_,x_));
    if (p1x_<WORLD_RES) m=MAT_DARKBLUE;

    float world=opUnion(ground,opUnion(b_,p1x_));

    return vec2(world,m);
}

/*
 * NORMALS
 *
 * */
vec3 calcNormal(in vec3 pos){
    vec2 e = vec2(0.0001,0.0);
    return normalize(
        vec3(sdfWorld(pos+e.xyy).x-sdfWorld(pos-e.xyy).x,
             sdfWorld(pos+e.yxy).x-sdfWorld(pos-e.yxy).x,
             sdfWorld(pos+e.yyx).x-sdfWorld(pos-e.yyx).x));
}

/*
 * RAYCASTING
 *
 * */
vec2 castRay(in vec3 ro, vec3 rd){
    vec2 res=vec2(-1.0,-1.0);
    float t = 0.5;
    for (int i=0; i<2600; i++){
        vec2 scene = sdfWorld(ro+rd*t);
        if (abs(scene.x)<WORLD_RES){
            res=vec2(t,scene.y);
            break;
        }
        t+=scene.x;
        if(t>WORLD_MAX) break;
    }
    return res;
}

/*
 * SHOFT SHADOW
 *
 * */
float castSoftShadow(in vec3 ro, vec3 rd){
    float res=1.0;
    float dist=0.01;
    float size=0.03;
    for (int i=0; i<2600; i++){
        float hit = sdfWorld(ro+rd*dist).x;
        res = min(res,hit/(dist*size));
        dist+=hit;
        if(hit<WORLD_RES || hit>WORLD_MAX) break;
    }
    return clamp(res,0.0,1.0);
}

/*
 * AO
 *
 * */
float getAO(in vec3 ro, vec3 normal){
    float occ=0.0;
    float weight=1.0;
    for (int i=0; i<8; i++){
        float len = 0.01+0.02*float(i*i);
        float dist = sdfWorld(ro+normal*len).x;
        occ=(len-dist)*weight;
        weight*=.85;
    }
    return 1.0-clamp(.6*occ,0.0,1.0);
}

/*
 * MATERIALS GENERATION
 *
 * */
vec3 getMaterial(vec3 p, vec3 nor, float id){
    vec3 m=vec3(.0,.0,.0);

    if(id==MAT_GROUND){
        m=vec3(.0,1.0,.0);
        m*=vec3(mod(floor(.5+p.x*.25)*floor(.5+p.z*.5),5.0));

    }else
    if(id==MAT_DARKBLUE){
        m=vec3(0.1,.2,5.0);
    }else
    if(id==MAT_CITY){
        float crnd = rnd(vec2(floor(abs(p.x)/20.0),
                floor(abs(p.z)/30.0)))*2.0;
        float win=
        mod(floor(p.x*4.0)*floor(p.y*4.0),2.0)*nor.z+
        0.1*nor.y+
        mod(floor(p.y*4.0)*floor(p.z*4.0),2.0)*nor.x;
        m=vec3(map(u_fft,0.65,1.0,0.0,4.0)*win,win+crnd,win+crnd);
    }else
    if(id==MAT_CHESS){
    vec3(mod(floor(p.x*8.0)+floor(p.z*8.0),2.0));
    }else
    if(id==MAT_ASPHALT){
        m=vec3(.01,.01,.02);
    }
    return m;
}


vec3 getColor(vec3 pos, vec3 nor,vec3 rd, float material_id){
    // colors reducer for better color correction
    vec3 mate = vec3(0.2);

    // environment: sun, shadows, fake bounce light
    vec3 sun_pos = normalize(vec3(-6.0,map(u_time,T_SUNRISE*.25,T_SUNRISE,-3.0,3.0),3.0));
    float sun_shadow = castSoftShadow(pos+nor*0.001, sun_pos);
    float ao = getAO(pos,nor);

    float sun_dif = clamp(dot(nor,sun_pos),0.0,1.0);
    float sky_dif = clamp(0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0)),0.0,1.0);
    float bou_dif = clamp(0.5 + 0.5*dot(nor,vec3(0.0,-1.0,0.0)),0.0,1.0);

    float sunrise = map(u_time,T_SUNRISE*.25,T_SUNRISE,.01,1.0);

    vec3 col = mate*getMaterial(pos,nor,material_id);
    col *= ao;
    col += mate*vec3(5.0,3.0,2.0)*sun_dif*sun_shadow*ao;
    col += mate*vec3(0.5,0.8,0.9)*sky_dif;
    col += mate*vec3(0.7,0.3,0.2)*bou_dif;
    col *= sunrise;

    return col;
}

/*
 * THE RENDERER
 *
 * */
vec3 render(in vec2 p){

    // ray origin aka camera
    vec3 ro = vec3(.0,
        map(u_time,T_SUNRISE,T_SUNRISE*2.0,0.0,.5),
        map(u_time,T_SUNRISE,T_SUNRISE*2.0,1.5,1.5-u_time));

    // target aka look at
    vec3 ta = vec3(
        map(u_time,T_SUNRISE,T_SUNRISE*2.0,0.0,0.0+sin(0.5+u_time*.4)*2.0),
        map(u_time,0.0,T_SUNRISE,.5+sin(u_time*.5)*.3,1.5+sin(u_time*.3)*1.5),
        map(u_time,T_SUNRISE,T_SUNRISE*2.0,0.0,.0-u_time));


    if (u_time>T_SUNRISE*4.0) {
        ro.y += map(u_time,T_SUNRISE*4.0,T_SUNRISE*8.0,1.0,14.0);
        ta.y += ro.y - abs(sin(u_time*.3))*1.5;
    }

    vec3 ww = normalize (ta-ro);
    vec3 uu = normalize( cross(ww, vec3(0,1,0)));
    vec3 vv = normalize (cross(uu,ww));

    // ray direction
    vec3 rd = normalize(p.x*uu+p.y*vv+1.5*ww);

    // sky simulation
    vec3 col = vec3(map(u_time,T_SUNRISE*.5,T_SUNRISE,1.0,.0),0.75,1.0) - 0.5*rd.y;
    col =  mix(col, vec3(0.7,0.8,0.8), exp(-10.0*rd.y));
    col *= map(u_time,T_SUNRISE*.25,T_SUNRISE,.0,1.0);

    // hit ray trace
    vec2 ray = castRay(ro,rd);
    float ray_hit=ray.x;
    float material_id=ray.y;

    if (ray_hit>0.0){
        vec3 pos = ro+rd*ray_hit;
        vec3 nor = calcNormal(pos);
        col = getColor(pos,nor,rd,material_id);

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
  vec3 col = renderAAAA(v_uv); // 4xAA
  //vec3 col = render(getUV(v_uv,vec2(0.0))); // no AA

  // color/exposure correction
  col = pow (col, vec3(0.4545));
  gl_FragColor = vec4(col, 1.0);
}

/*
 * END OF LISTING
 *
 * */
