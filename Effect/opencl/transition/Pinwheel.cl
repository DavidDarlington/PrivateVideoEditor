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

float rand(vec2 co){
	float temp; 
	return fract(sin(dot(co.xy ,(vec2)(12.9898f,78.233f))) * 43758.5453f,&temp);
}

__kernel void MAIN(__read_only image2d_t input1, __read_only image2d_t input2, __write_only image2d_t dstImg,__global FilterParam* param)
{
	float progress = param->cur_time / param->total_time;	int W = param->width[2];	int H = param->height[2];	int w = get_global_id(0);
	int h = get_global_id(1);
	float2 resolution = (float2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 p = ((vec2)(fragCoord.x, fragCoord.y) + (vec2)(0.5f)) /resolution.xy;
	
	float circPos = atan2(p.y - 0.5f, p.x - 0.5f) + (2.0f-progress*2.0f) + 3.14159;
	float modPos = fmod(circPos, 3.1415f / 2.f);
	float signed1 = sign((2.0f-progress*2.0f) - modPos);
	float smoothed = smoothstep(0.f, 1.f, signed1);
	float4 outColor;
	if (smoothed < 0.5f){
		outColor =  INPUT(input2, p);
	} else {
		outColor = INPUT(input1, p);
  }
	write_imagef(dstImg, (int2)(w, H - h -1),outColor);
}