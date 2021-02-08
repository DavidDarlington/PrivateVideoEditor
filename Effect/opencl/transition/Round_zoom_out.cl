// author: RuanShengQiang 
// date: 2017/6/1
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;

vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, (vec2)(tc.x, 1.0f - tc.y));
}

__kernel void MAIN(__read_only image2d_t input1, __read_only image2d_t input2, __write_only image2d_t dstImg,__global FilterParam* param)
{
	//const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;
	
	float progress = param->cur_time / param->total_time;	int W = param->width[2];	int H = param->height[2];	int w = get_global_id(0);
	int h = get_global_id(1);
	float2 resolution = (float2)(W,H);
	float curPos = progress*2.0f;
	
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	float iPro = (3.0f* progress * progress - 2.0f * progress * progress * progress); 	
	vec2 uv = fragCoord/resolution;
	vec2 circleUV = (vec2)(fragCoord.x, fragCoord.y)/resolution.x;
	float r = length(circleUV-(vec2)(0.5f,resolution.y/resolution.x/2.0f));
	vec4 outCol = mix(INPUT(input2,uv), INPUT(input1,uv), smoothstep(-0.3f+iPro, 0.0f+iPro, r));
	
	write_imagef(dstImg, (int2)(w, H - h -1), outCol);
}