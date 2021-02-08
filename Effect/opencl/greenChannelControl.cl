//---------------------------------------------------------------------------------------//
// Designed by RSQ
//---------------------------------------------------------------------------------------//

#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.1415926535897932f

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_FILTER_NEAREST;

__kernel  void MAIN(
      __read_only image2d_t src_data,
	  __read_only image2d_t control,
      __write_only image2d_t dest_data,        //Data in global memory
	  __global FilterParam* param	
	 )
{	
	int W = param->width[0];
	int H = param->height[0];
	vec2 u_resolution = (vec2)(W,H);
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1)) + 0.5f;
	vec2 uv = fragCoord/u_resolution;
	
	vec4 controlChannel = read_imagef(control, sampler, uv);
	vec4 col = read_imagef(src_data, sampler, uv);
	
	vec4 outputCol = (vec4)(col.xyz, controlChannel.y);

	write_imagef(dest_data, coordinate, outputCol);
}
