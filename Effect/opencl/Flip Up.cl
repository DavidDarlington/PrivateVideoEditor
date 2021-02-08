#define vec2 float2
#define vec4 float4
#define rgb xyz
#define rgba xyzw

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP | CLK_FILTER_LINEAR;

vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, tc);
}

__kernel void MAIN(
      __read_only image2d_t src_data,
      __write_only image2d_t dest_data,
	  __global FilterParam* param,
      int alpha)  		// the gpu items/threads should be newW*newH
{	
	int W = param->width[0];
	int H = param->height[0];
	float iGlobalTime = param->cur_time / param->total_time;

	float2 iResolution = (float2)(W,H);
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 tc = ((vec2)(fragCoord.x, fragCoord.y) + (vec2)(0.5f))/iResolution.xy;
	
    vec4 color = INPUT(src_data, (vec2)(tc.x,1.0-tc.y));
	vec4 origCol = INPUT(src_data,  (vec2)(tc.x, tc.y));

    write_imagef(dest_data, coordinate, origCol*(1.0f - (float)alpha/100.0f) + color*(float)alpha/100.0f);
}
