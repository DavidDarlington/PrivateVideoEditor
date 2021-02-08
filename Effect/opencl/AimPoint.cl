#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP | CLK_FILTER_LINEAR;

vec4 INPUTSRC(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, tc);
}

__kernel void MAIN(
      __read_only image2d_t src_data,
      __write_only image2d_t dest_data,
	  __global FilterParam* param,
	  int visible,
	  int color,
	  int PlayState)  		// the gpu items/threads should be newW*newH
{	
	int W = get_global_size(0);
	int H = get_global_size(1);
	int textH = param->height[0];;
	float iGlobalTime = param->cur_time / param->total_time;

	float2 iResolution = (float2)(W,H);
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 tc = (vec2)(fragCoord.x, fragCoord.y)/iResolution.xy;
	
	float m_roiX = param->resultROI[0];
	float m_roiY = param->resultROI[1];
	float m_roiWidth = param->resultROI[2];
	float m_roiHeight = param->resultROI[3];
	
    vec4 origCol = INPUTSRC(src_data, tc);
	
	if(visible == 0)
		write_imagef(dest_data, coordinate, origCol);
	
	if (m_roiX > 1.0f || m_roiY > 1.0f || m_roiWidth < 0.0f || m_roiHeight < 0.0f || (m_roiX + m_roiWidth < 0.0f) || (m_roiY + m_roiHeight < 0.0f))
		write_imagef(dest_data, coordinate, origCol);

	int roi_x = m_roiX * iResolution.x;
	int roi_y = m_roiY * iResolution.y;
	int roi_width = m_roiWidth * iResolution.x;
	int roi_height = m_roiHeight * iResolution.y;
	
	int min_rect_length = 20;
	int min_frame_length = min(W, H);
	min_rect_length = (int)((float)(min_frame_length) / 720.0f * (float)(min_rect_length));
	min_rect_length = max(min_rect_length, 3);
	roi_width = max(roi_width, min_rect_length);
	roi_height = max(roi_height, min_rect_length);

	int minWidth = min(roi_width, roi_height);
	int aim_length = minWidth / 4;
	aim_length = aim_length / 2 * 2 + 1;
	int aim_half_length = aim_length / 2;

	int line_width = 3;

	if (iResolution.x * iResolution.y > 100000.0f)
	{
		if (iResolution.x > iResolution.y)
		{
			if (iResolution.x > 900.0f)
				line_width = (int)((iResolution.x / 900.0f + 0.5f) * line_width);
		}
		else {
			if (iResolution.y > 900.0f)
				line_width = (int)((iResolution.y / 500.0f + 0.5f) * line_width);
		}
	}

	line_width = max(line_width / 2 * 2 + 1, 3);

	vec2 crossCenter;
	crossCenter.x = roi_x + roi_width / 2;
	crossCenter.y = roi_y + roi_height / 2;
	
	vec4 retCol = origCol;
	if(PlayState != 1)
	{
		//black rectangle
		float matt1 = step((float)(roi_x),(float)(coordinate.x))*step((float)(coordinate.x),(float)(roi_x + line_width - 1))*step((float)(roi_y),(float)(coordinate.y))*step((float)(coordinate.y),(float)(roi_y + roi_height));
		
		float matt2 = step((float)(roi_x + roi_width - line_width + 1),(float)(coordinate.x))*step((float)(coordinate.x),(float)(roi_x + roi_width))*step((float)(roi_y),(float)(coordinate.y))*step((float)(coordinate.y),(float)(roi_y + roi_height));
		
		float matt3 = step((float)(roi_x),(float)(coordinate.x))*step((float)(coordinate.x),(float)(roi_x + roi_width))*step((float)(roi_y),(float)(coordinate.y))*step((float)(coordinate.y),(float)(roi_y + line_width - 1));
		
		float matt4 = step((float)(roi_x),(float)(coordinate.x))*step((float)(coordinate.x),(float)(roi_x + roi_width))*step((float)(roi_y + roi_height - line_width + 1),(float)(coordinate.y))*step((float)(coordinate.y),(float)(roi_y + roi_height));
		
		float matt = step(1.0f,matt1 + matt2 + matt3 + matt4);
		retCol.xyz = -matt * origCol.xyz + origCol.xyz;
				
		//white rectangle
		matt1 = step((float)(roi_x + 1),(float)(coordinate.x))*step((float)(coordinate.x),(float)(roi_x + line_width - 2))*step((float)(roi_y + 1),(float)(coordinate.y))*step((float)(coordinate.y),(float)(roi_y + roi_height - 1));
		
		matt2 = step((float)(roi_x + roi_width - line_width + 2),(float)(coordinate.x))*step((float)(coordinate.x),(float)(roi_x + roi_width - 1))*step((float)(roi_y + 1),(float)(coordinate.y))*step((float)(coordinate.y),(float)(roi_y + roi_height - 1));
		
		matt3 = step((float)(roi_x + 1),(float)(coordinate.x))*step((float)(coordinate.x),(float)(roi_x + roi_width - 1))*step((float)(roi_y + 1),(float)(coordinate.y))*step((float)(coordinate.y),(float)(roi_y + line_width - 2));
		
		matt4 = step((float)(roi_x + 1),(float)(coordinate.x))*step((float)(coordinate.x),(float)(roi_x + roi_width - 1))*step((float)(roi_y + roi_height - line_width + 2),(float)(coordinate.y))*step((float)(coordinate.y),(float)(roi_y + roi_height - 1));
		
		matt = step(1.0f,matt1 + matt2 + matt3 + matt4);
		retCol.xyz = matt * ((vec3)(1.0f) - retCol.xyz) + retCol.xyz;
		
		//center cross 
		matt1 = step((float)(crossCenter.x - aim_half_length),(float)(coordinate.x))*step((float)(coordinate.x),(float)(crossCenter.x + aim_half_length))*step((float)(crossCenter.y - line_width/2),(float)(coordinate.y))*step((float)(coordinate.y),(float)(crossCenter.y + line_width/2));
		
		matt2 = step((float)(crossCenter.x - line_width/2),(float)(coordinate.x))*step((float)(coordinate.x),(float)(crossCenter.x + line_width/2))*step((float)(crossCenter.y - aim_half_length),(float)(coordinate.y))*step((float)(coordinate.y),(float)(crossCenter.y + aim_half_length));
		
		matt = step(1,matt1 + matt2);
		retCol.xyz = -matt * retCol.xyz + retCol.xyz;
		
		matt3 = step((float)(crossCenter.x - aim_half_length + 1),(float)(coordinate.x))*step((float)(coordinate.x),(float)(crossCenter.x + aim_half_length - 1))*step((float)(crossCenter.y - line_width/2 + 1),(float)(coordinate.y))*step((float)(coordinate.y),(float)(crossCenter.y + line_width/2 - 1));
		
		matt4 = step((float)(crossCenter.x - line_width/2 + 1),(float)(coordinate.x))*step((float)(coordinate.x),(float)(crossCenter.x + line_width/2 - 1))*step((float)(crossCenter.y - aim_half_length + 1),(float)(coordinate.y))*step((float)(coordinate.y),(float)(crossCenter.y + aim_half_length - 1));
		
		matt = step(1.0f,matt3 + matt4);
		retCol.xyz = matt * ((vec3)(1.0f) - retCol.xyz) + retCol.xyz;
	}
	
	if(PlayState == 1)
	{
		float matt1 = step((float)(roi_x),(float)(coordinate.x))*step((float)(coordinate.x),(float)(roi_x + roi_width - 1))*step((float)(roi_y),(float)(coordinate.y))*step((float)(coordinate.y),(float)(roi_y + roi_height));
		retCol.xyz = matt1 * (retCol.xyz * (vec3)(187.0f / 255.0f,187.0f / 255.0f,188.0f / 255.0f) - retCol.xyz) + retCol.xyz;

		//rectangle
		matt1 = step((float)(roi_x + 1),(float)(coordinate.x))*step((float)(coordinate.x),(float)(roi_x + 3))*step((float)(roi_y + 1),(float)(coordinate.y))*step((float)(coordinate.y),(float)(roi_y + roi_height - 1));

		float matt2 = step((float)(roi_x + roi_width - 4),(float)(coordinate.x))*step((float)(coordinate.x),(float)(roi_x + roi_width - 2))*step((float)(roi_y + 1),(float)(coordinate.y))*step((float)(coordinate.y),(float)(roi_y + roi_height - 1));
		
		float matt3 = step((float)(roi_x + 1),(float)(coordinate.x))*step((float)(coordinate.x),(float)(roi_x + roi_width - 2))*step((float)(coordinate.y),(float)(roi_y + 3))*step((float)(roi_y + 1),(float)(coordinate.y));

		float matt4 = step((float)(roi_x + 1),(float)(coordinate.x))*step((float)(coordinate.x),(float)(roi_x + roi_width - 2))*step((float)(coordinate.y),(float)(roi_y + roi_height - 1))*step((float)(roi_y + roi_height - 3),(float)(coordinate.y));

		float matt = step(1.0f,matt1 + matt2 + matt3 + matt4);
		retCol.xyz = matt * ((vec3)(1.0f) - retCol.xyz) + retCol.xyz;
		
		//cross
		matt1 = step((float)(crossCenter.x - aim_half_length),(float)(coordinate.x))*step((float)(coordinate.x),(float)(crossCenter.x + aim_half_length))*step((float)(coordinate.y),(float)(crossCenter.y + 1))*step((float)(crossCenter.y - 1),(float)(coordinate.y));

		matt2 = step((float)(crossCenter.x - 1),(float)(coordinate.x))*step((float)(coordinate.x),(float)(crossCenter.x + 1))*step((float)(crossCenter.y - aim_half_length),(float)(coordinate.y))*step((float)(coordinate.y),(float)(crossCenter.y + aim_half_length));

		matt = step(1.0f,matt1 + matt2);
		retCol.xyz = matt * ((vec3)(1.0f) - retCol.xyz) + retCol.xyz;
	}
	
	write_imagef(dest_data, coordinate, retCol);
}
