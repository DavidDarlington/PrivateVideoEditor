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
      __write_only image2d_t dest_data,        //Data in global memory
	  __global FilterParam* param,
		int mode,
		float theta, 
		
		float r0,
		float g0,
		float b0,
	
		float r1,
		float g1,
		float b1,
		
		int channelChoose
	 )
{

	int W = param->width[0];
	int H = param->height[0];
	float2 u_resolution = (float2)(W,H);
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 uv = (vec2)(fragCoord.x + 0.5f, fragCoord.y + 0.5f)/u_resolution.xy;
	vec4 controlChannel = read_imagef(src_data, sampler, uv);
	vec4 outputCol = (vec4)(0.0f);
	vec2 center = (vec2)(0.5f);
	float r = 0.7f;
	theta = -theta;
	float theta0 = radians(theta);
	
	vec2 xy0 = center + r*(vec2)(cos(theta0),sin(theta0));
	
	float theta1 = radians(theta + 180.0f);
	
	vec2 xy1 = center + r*(vec2)(cos(theta1),sin(theta1));
	
	vec3 decayColor = length(uv - xy0)/1.4f * (float3)(r0, g0, b0)  + length(uv - xy1)/1.4f * (float3)(r1, g1, b1);
	if(0 == mode) // fill color 
	{
		switch(channelChoose)
		{
			case 0: outputCol = (vec4)((vec3)(r0,g0,b0), controlChannel.x);break;
			case 1: outputCol = (vec4)((vec3)(r0,g0,b0), controlChannel.y);break;
			case 2: outputCol = (vec4)((vec3)(r0,g0,b0), controlChannel.z);break;
			case 3: outputCol = (vec4)((vec3)(r0,g0,b0), controlChannel.w);break;
		}	
		
	}else 
	{
		switch(channelChoose)
		{
			case 0: outputCol = (vec4)(decayColor, controlChannel.x);break;
			case 1: outputCol = (vec4)(decayColor, controlChannel.y);break;
			case 2: outputCol = (vec4)(decayColor, controlChannel.z);break;
			case 3: outputCol = (vec4)(decayColor, controlChannel.w);break;
			
		}
	}
	write_imagef(dest_data, coordinate, outputCol);
}
