//---------------------------------------------------------------------------------------//
// Designed by RuanShengQiang
//---------------------------------------------------------------------------------------//

#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.1415926535897932f

vec2 scale(vec2 tc, vec2 scale, vec2 center)
{
    return (tc - center)*scale + center;
}

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_LINEAR;
__kernel  void MAIN(
      __read_only image2d_t input1,
	  __read_only image2d_t input2,
      __write_only image2d_t dest_data,        //Data in global memory
	  __global FilterParam* param,
		int mode
	 )
{
	int outputW = param->width[1];
	int outputH = param->height[1];
	vec2 ouputResolution = (vec2)(outputW,outputH);
	
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 tc = (fragCoord + (vec2)(0.5f))/ouputResolution; //using outputImage coordinate as the normalized space...

	vec4 color1 = read_imagef(input1, sampler, tc);;
	vec4 color2 = read_imagef(input2, sampler, tc);;
	
	if (mode == 0) // Left/Right
	{
		if (tc.x <= 0.5f)
		{
			write_imagef(dest_data, coordinate, color1);
			return;
		}
		else
		{
			write_imagef(dest_data, coordinate, color2);
			return;
		}
	}
	else if (mode == 1)
	{
		if (tc.y <= 0.5f)
		{
			write_imagef(dest_data, coordinate, color1);
			return;
		}
		else
		{
			write_imagef(dest_data, coordinate, color2);
			return;
		}
	}
	
	if (tc.x <= 0.5f)
	{
		tc.x = tc.x  * 2.0f;
        vec2 cc = scale(tc, (vec2)(1.0f, 2.0f), (vec2)(0.5f, 0.5f));
		float matt = step(0.0f, cc.x) * step(cc.x, 1.0f) * step(0.0f, cc.y) * step(cc.y, 1.0f);
		write_imagef(dest_data, coordinate, read_imagef(input1, sampler, cc)*matt);
		return;
	}
	else
	{
		tc.x = (tc.x - 0.5f)  * 2.0f;
		vec2 cc = scale(tc, (vec2)(1.0f, 2.0f), (vec2)(0.5f,0.5f));
		float matt = step(0.0f, cc.x) * step(cc.x, 1.0f) * step(0.0f, cc.y) * step(cc.y, 1.0f);
		write_imagef(dest_data, coordinate, read_imagef(input2, sampler, cc)*matt);
		return;
	}
	
}