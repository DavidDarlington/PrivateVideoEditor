#ifdef GL_ES
precision highp float;
#endif

#define PI 3.141592653589

// General parameters
float progress = PREFIX(global_time)/PREFIX(total_time);
vec2 resolution = iResolution;

vec4 FUNCNAME(vec2 tc) {
	vec4 fragOutColor;
  vec2 p = tc;
  vec2 rp = p;
  float a = atan(rp.y, rp.x);
  float pa = (1.0-progress)*PI*1.0-PI*0.50;
  vec4 fromc = INPUT1(p);
  vec4 toc = INPUT2(p);
  if(a>pa) {
    return mix(fromc, toc, smoothstep(0., 1., (a-pa)));
  }
  return fromc;
}
