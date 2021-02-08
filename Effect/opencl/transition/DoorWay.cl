// author: RuanShengQiang 
// date: 2017/6/21
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.141592653589f

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;
__constant float grayPhase = 0.3f;
__constant float reflection = 0.4f;
__constant float perspective = 0.4f;
__constant float depth = 3.0f;
__constant vec4 black = (vec4)(0.0f);
__constant vec2 boundMin = (vec2)(0.0f);
__constant vec2 boundMax = (vec2)(1.0f, 1.0f);

vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, (vec2)(tc.x, 1.0f - tc.y));
}

vec3 grayscale (vec3 color) {
  return (vec3)(0.2126f*color.z + 0.7152f*color.y + 0.0722f*color.x);
}

float _abs(float a)
{
	if(a<0.0f)
		return -a;
	else
		return a;
}

float rand(vec2 co){
	float temp; 
	return fract(sin(dot(co.xy ,(vec2)(12.9898f,78.233f))) * 43758.5453f,&temp);
}

float myMod(float x ,float y)
{
	return x-y * floor (x/y);
}

bool inBounds (vec2 p) {
	vec2 boundMin = (vec2)(0.0f, 0.0f);
	vec2 boundMax = (vec2)(1.0f, 1.0f);
	return boundMin.x<p.x && boundMin.y<p.y && p.x < boundMax.x && p.y <boundMax.y;
}

vec2 project (vec2 p) {
  return p * (vec2)(1.0f, -1.2f) + (vec2)(0.0f, -0.02f);
}

vec4 bgColor (vec2 p, vec2 pto,image2d_t input2) {
  vec4 c = (vec4)(0.0f);
  pto = project(pto);
  if (inBounds(pto)) {
    c += mix(black, INPUT(input2, pto), reflection * mix(1.0f, 0.0f, pto.y));
  }
  return c;
}

__kernel void MAIN(__read_only image2d_t input1, __read_only image2d_t input2, __write_only image2d_t dstImg, __global FilterParam* param)
{
	float progress = param->cur_time / param->total_time;	int W = param->width[2];	int H = param->height[2];	int w = get_global_id(0);
	int h = get_global_id(1);
	float2 resolution = (float2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 p = ((vec2)(fragCoord.x, fragCoord.y) + (vec2)(0.5f)) /resolution.xy;


	vec2 pfr = (vec2)(-1.f), pto = (vec2)(-1.f);
	float middleSlit = 2.0f * _abs(p.x-0.5f) - progress;
	if (middleSlit > 0.0f) {
		pfr = p + (p.x > 0.5f ? -1.0f : 1.0f) * (vec2)(0.5f*progress, 0.0f);
		float d = 1.0f/(1.0f+perspective*progress*(1.0f-middleSlit));
		pfr.y -= d/2.f;
		pfr.y *= d;
		pfr.y += d/2.f;
	 }
 
	float size = mix(1.0f, depth, 1.f -progress);
	pto = (p + (vec2)(-0.5f, -0.5f)) * (vec2)(size, size) + (vec2)(0.5f, 0.5f);
	vec4 gl_FragColor;
	if (inBounds(pfr)) {
		gl_FragColor = INPUT(input1, pfr);
	}else if (inBounds(pto)) {
		gl_FragColor = INPUT(input2, pto);
	}
	else {
		gl_FragColor = bgColor(p, pto,input2);
	}
		
	write_imagef(dstImg, (int2)(w, H - h -1), gl_FragColor);
}