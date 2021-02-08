/*{
	"GUID":"2D0FCDC7-956B-469f-8E05-7B36CC2933FF"
}*/
#define vec2 float2
#define vec4 float4
#define rgb xyz
#define rgba xyzw

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_FILTER_LINEAR;

vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, tc);
}

__kernel void MAIN(
      __read_only image2d_t src_data,
      __write_only image2d_t dest_data,        //Data in global memory
       __global FilterParam* param)  		// the gpu items/threads should be newW*newH
{	

	int W = param->width[0];
	int H = param->height[0];
	float iGlobalTime = param->cur_time / param->total_time;
	
	float2 iResolution = (float2)(W,H);
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 tc = (vec2)(fragCoord.x, fragCoord.y)/iResolution.xy;
	
    vec4 color = INPUT(src_data, (vec2)(1.0-tc.x,1.0-tc.y));

	write_imagef(dest_data, coordinate, color);
}
