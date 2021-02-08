#ifdef GL_ES
precision highp float;
#endif

vec4 FUNCNAME(vec2 tc)
{		
	vec4 origCol = INPUT(tc);
	
	int nEnable = PREFIX(visible);
	int nPlayState = PREFIX(PlayState);
	
	if(nEnable == 0)
		return origCol;
	
	vec4 result_roi = PREFIX(result_roi);
	ivec2 coordinate = ivec2(tc * iResolution);
	
	float m_roiX = result_roi.x;
	float m_roiY = result_roi.y;
	float m_roiWidth = result_roi.z;
	float m_roiHeight = result_roi.w;

	if (m_roiX > 1.0 || m_roiY > 1.0 || m_roiWidth < 0.0 || m_roiHeight < 0.0 || (m_roiX + m_roiWidth < 0.0) || (m_roiY + m_roiHeight < 0.0))
		return origCol;

	int roi_x = int(result_roi.x * iResolution.x);
	int roi_y = int(result_roi.y * iResolution.y);
	int roi_width = int(result_roi.z * iResolution.x);
	int roi_height = int(result_roi.w * iResolution.y);
	
	int min_rect_length = 20;
	int min_frame_length = min(coordinate.x, coordinate.y);
	min_rect_length = int(float(min_frame_length) / 720.0 * float(min_rect_length));
	min_rect_length = max(min_rect_length, 3);
	roi_width = max(roi_width, min_rect_length);
	roi_height = max(roi_height, min_rect_length);

	int minWidth = min(roi_width, roi_height);
	int aim_length = minWidth / 4;
	aim_length = aim_length / 2 * 2 + 1;
	int aim_half_length = aim_length / 2;

	int line_width = 3;

	if (iResolution.x * iResolution.y > 100000.0)
	{
		if (iResolution.x > iResolution.y)
		{
			if (iResolution.x > 900.0)
				line_width = int((iResolution.x / 900.0 + 0.5) * float(line_width));
		}
		else {
			if (iResolution.y > 900.0)
				line_width = int((iResolution.y / 500.0 + 0.5) * float(line_width));
		}
	}

	line_width = max(int(line_width) / 2 * 2 + 1, 3);

	ivec2 crossCenter;
	crossCenter.x = roi_x + roi_width / 2;
	crossCenter.y = roi_y + roi_height / 2;
	
	vec4 retCol = origCol;
	if(nPlayState != 1)
	{
		//black rectangle
		float matt1 = step(float(roi_x),float(coordinate.x))*step(float(coordinate.x),float(roi_x + line_width - 1))*step(float(roi_y),float(coordinate.y))*step(float(coordinate.y),float(roi_y + roi_height));
		
		float matt2 = step(float(roi_x + roi_width - line_width + 1),float(coordinate.x))*step(float(coordinate.x),float(roi_x + roi_width))*step(float(roi_y),float(coordinate.y))*step(float(coordinate.y),float(roi_y + roi_height));
		
		float matt3 = step(float(roi_x),float(coordinate.x))*step(float(coordinate.x),float(roi_x + roi_width))*step(float(roi_y),float(coordinate.y))*step(float(coordinate.y),float(roi_y + line_width - 1));
		
		float matt4 = step(float(roi_x),float(coordinate.x))*step(float(coordinate.x),float(roi_x + roi_width))*step(float(roi_y + roi_height - line_width + 1),float(coordinate.y))*step(float(coordinate.y),float(roi_y + roi_height));
		
		float matt = step(1.0,matt1 + matt2 + matt3 + matt4);
		retCol.xyz = -matt * origCol.xyz + origCol.xyz;
				
		//white rectangle
		matt1 = step(float(roi_x + 1),float(coordinate.x))*step(float(coordinate.x),float(roi_x + line_width - 2))*step(float(roi_y + 1),float(coordinate.y))*step(float(coordinate.y),float(roi_y + roi_height - 1));
		
		matt2 = step(float(roi_x + roi_width - line_width + 2),float(coordinate.x))*step(float(coordinate.x),float(roi_x + roi_width - 1))*step(float(roi_y + 1),float(coordinate.y))*step(float(coordinate.y),float(roi_y + roi_height - 1));
		
		matt3 = step(float(roi_x + 1),float(coordinate.x))*step(float(coordinate.x),float(roi_x + roi_width - 1))*step(float(roi_y + 1),float(coordinate.y))*step(float(coordinate.y),float(roi_y + line_width - 2));
		
		matt4 = step(float(roi_x + 1),float(coordinate.x))*step(float(coordinate.x),float(roi_x + roi_width - 1))*step(float(roi_y + roi_height - line_width + 2),float(coordinate.y))*step(float(coordinate.y),float(roi_y + roi_height - 1));
		
		matt = step(1.0,matt1 + matt2 + matt3 + matt4);
		retCol.xyz = matt * (vec3(1.0) - retCol.xyz) + retCol.xyz;
		
		//center cross 
		matt1 = step(float(crossCenter.x - aim_half_length),float(coordinate.x))*step(float(coordinate.x),float(crossCenter.x + aim_half_length))*step(float(crossCenter.y - line_width/2),float(coordinate.y))*step(float(coordinate.y),float(crossCenter.y + line_width/2));
		
		matt2 = step(float(crossCenter.x - line_width/2),float(coordinate.x))*step(float(coordinate.x),float(crossCenter.x + line_width/2))*step(float(crossCenter.y - aim_half_length),float(coordinate.y))*step(float(coordinate.y),float(crossCenter.y + aim_half_length));
		
		matt = step(1.0,matt1 + matt2);
		retCol.xyz = -matt * retCol.xyz + retCol.xyz;
		
		matt3 = step(float(crossCenter.x - aim_half_length + 1),float(coordinate.x))*step(float(coordinate.x),float(crossCenter.x + aim_half_length - 1))*step(float(crossCenter.y - line_width/2 + 1),float(coordinate.y))*step(float(coordinate.y),float(crossCenter.y + line_width/2 - 1));
		
		matt4 = step(float(crossCenter.x - line_width/2 + 1),float(coordinate.x))*step(float(coordinate.x),float(crossCenter.x + line_width/2 - 1))*step(float(crossCenter.y - aim_half_length + 1),float(coordinate.y))*step(float(coordinate.y),float(crossCenter.y + aim_half_length - 1));
		
		matt = step(1.0,matt3 + matt4);
		retCol.xyz = matt * (vec3(1.0) - retCol.xyz) + retCol.xyz;
	}
	
	if(nPlayState == 1)
	{
		float matt1 = step(float(roi_x),float(coordinate.x))*step(float(coordinate.x),float(roi_x + roi_width - 1))*step(float(roi_y),float(coordinate.y))*step(float(coordinate.y),float(roi_y + roi_height));
		retCol.xyz = matt1 * (retCol.xyz * vec3(187.0 / 255.0,187.0 / 255.0,188.0 / 255.0) - retCol.xyz) + retCol.xyz;

		//rectangle
		matt1 = step(float(roi_x + 1),float(coordinate.x))*step(float(coordinate.x),float(roi_x + 3))*step(float(roi_y + 1),float(coordinate.y))*step(float(coordinate.y),float(roi_y + roi_height - 1));

		float matt2 = step(float(roi_x + roi_width - 4),float(coordinate.x))*step(float(coordinate.x),float(roi_x + roi_width - 2))*step(float(roi_y + 1),float(coordinate.y))*step(float(coordinate.y),float(roi_y + roi_height - 1));
		
		float matt3 = step(float(roi_x + 1),float(coordinate.x))*step(float(coordinate.x),float(roi_x + roi_width - 2))*step(float(coordinate.y),float(roi_y + 3))*step(float(roi_y + 1),float(coordinate.y));

		float matt4 = step(float(roi_x + 1),float(coordinate.x))*step(float(coordinate.x),float(roi_x + roi_width - 2))*step(float(coordinate.y),float(roi_y + roi_height - 1))*step(float(roi_y + roi_height - 3),float(coordinate.y));

		float matt = step(1.0,matt1 + matt2 + matt3 + matt4);
		retCol.xyz = matt * (vec3(1.0) - retCol.xyz) + retCol.xyz;
		
		//cross
		matt1 = step(float(crossCenter.x - aim_half_length),float(coordinate.x))*step(float(coordinate.x),float(crossCenter.x + aim_half_length))*step(float(coordinate.y),float(crossCenter.y + 1))*step(float(crossCenter.y - 1),float(coordinate.y));

		matt2 = step(float(crossCenter.x - 1),float(coordinate.x))*step(float(coordinate.x),float(crossCenter.x + 1))*step(float(crossCenter.y - aim_half_length),float(coordinate.y))*step(float(coordinate.y),float(crossCenter.y + aim_half_length));

		matt = step(1.0,matt1 + matt2);
		retCol.xyz = matt * (vec3(1.0) - retCol.xyz) + retCol.xyz;
	}
	
	return retCol;
}