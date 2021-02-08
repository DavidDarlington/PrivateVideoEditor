
// author: RuanShengQiang 
// date: 2017/6/21
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.141592653589f

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP | CLK_FILTER_LINEAR;

static vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, (vec2)(tc.x, 1.0f - tc.y));
}

static vec2 scale(vec2 uv, vec2 center, vec2 amp)
{

	return (uv + center)*(amp);

}

static float GetParabolaMap(float t, float T)	
{
	return (3.0f * T * t * t - 2.0f * t * t * t) / (T * T);
}

static float GetSinusoidalMap(float t, float T)	
{
	return t - T * sin(2.0f * PI * t / T) / (2.0f * PI);
}

__kernel void MAIN(__read_only image2d_t input1, __read_only image2d_t input2, __write_only image2d_t dstImg,__global FilterParam* param)
{
	float progress = param->cur_time / param->total_time;	int W = param->width[2];	int H = param->height[2];	int w = get_global_id(0);
	int h = get_global_id(1);
	float2 resolution = (float2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 uv = ((vec2)(fragCoord.x, fragCoord.y) + (vec2)(0.5f)) /resolution.xy;
	float iPro = GetSinusoidalMap(progress, 1.0f); 	
	iPro = GetParabolaMap(iPro, 1.0f) ;
	
	iPro = iPro *2.29f;
	float4 outputCol;
	float4 y1;
	
	float matt = smoothstep(1.5f - iPro,1.0f - iPro, uv.y - uv.x );
	vec4 col = mix( INPUT(input2, uv), INPUT(input1, uv), matt ); 

	write_imagef(dstImg, (int2)(w, H - h - 1),col);
}
