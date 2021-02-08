// author: RuanShengQiang 
// date: 2017/6/21
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.141592653589f

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;

vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, (vec2)(tc.x, 1.0f - tc.y));
}

float _abs(float a)
{
	if(a<0.0f)
		return -a;
	else
		return a;
}


__kernel void MAIN(__read_only image2d_t input1, __read_only image2d_t input2, __write_only image2d_t dstImg,__global FilterParam* param)
{
	//const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;
	
	float progress = param->cur_time / param->total_time;	int W = param->width[2];	int H = param->height[2];	int w = get_global_id(0);
	int h = get_global_id(1);
	float2 resolution = (float2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 tc = ((vec2)(fragCoord.x, fragCoord.y) + (vec2)(0.5f)) /resolution.xy;
	
	vec2 p = tc;
	vec2 rp = p;
	float a = atan2(rp.y, rp.x);
	float pa = (1.0f-progress)*PI*1.0f-PI*0.50f;
	vec4 fromc = INPUT(input1, p);
	vec4 toc = INPUT(input2, p);
	if(a>pa) {
		write_imagef(dstImg, (int2)(w, H - h -1), mix(fromc, toc, smoothstep(0.f, 1.f, (a-pa))));
		return;
	}
	write_imagef(dstImg, (int2)(w, H - h -1),fromc);
}