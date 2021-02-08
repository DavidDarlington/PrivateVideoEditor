// author: RuanShengQiang 
// date: 2017/6/21
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.141592653589f

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP | CLK_FILTER_LINEAR;

vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, (vec2)(tc.x, 1.0f - tc.y));
}

__kernel void MAIN(__read_only image2d_t input1, __read_only image2d_t input2, __write_only image2d_t dstImg,__global FilterParam* param)
{
	float progress = param->cur_time / param->total_time;	int W = param->width[2];	int H = param->height[2];	int w = get_global_id(0);
	int h = get_global_id(1);
	float2 resolution = (float2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 uv = ((vec2)(fragCoord.x, fragCoord.y) + (vec2)(0.5f)) /resolution.xy;
	float iPro = (3.0f* progress * progress - 2.0f * progress * progress * progress); 	
	float zoomDis = iPro;
	float matt = smoothstep(-0.3f, 0.0f, uv.x - uv.y - iPro*(1.3f))+ 1.0f - smoothstep(0.0f, 0.3f, uv.x - uv.y + iPro*(1.3f));
	float4 outputCol = mix( INPUT(input2,uv), INPUT(input1, uv), clamp(matt,0.0f, 1.0f));
	write_imagef(dstImg, (int2)(w, H - h - 1), outputCol);
}