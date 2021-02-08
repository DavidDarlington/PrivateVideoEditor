//---------------------------------------------------------------------------------------//
// Designed by RSQ
//---------------------------------------------------------------------------------------//

#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.1415926535897932f

float2 rotateFunc(float2 uv, float2 center, float theta)
{
	float2 temp;
	temp.x = dot((float2)(cos(theta), -sin(theta)), uv - center);
	temp.y = dot((float2)(sin(theta), cos(theta)), uv - center);
	return (temp+center);
}


__kernel  void MAIN(
      __read_only image2d_t control,
	  __read_only image2d_t src_data,
      __write_only image2d_t dest_data,        //Data in global memory
	  __global FilterParam* param,
	  int channel
	 )
{	
	const sampler_t samplerOVL = CLK_NORMALIZED_COORDS_FALSE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_NEAREST;
	const sampler_t samplerOVLN = CLK_NORMALIZED_COORDS_FALSE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_LINEAR;
	
	const float eps = 1.0e-10f;
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));

	float2 resolution = (float2)((float)(param->width[1]),(float)(param->height[1]));
	float2 overlayRes = (float2)((float)(param->width[0]),(float)(param->height[0]));
	
	float2 fragCoord = (float2)(coordinate.x, coordinate.y)+0.5f;
	float2 tc = fragCoord/resolution.xy;
	float2 tempTc = tc;
	float2 tempTcExe = tc;  
	float2 onePixel = (float2)(0.0f);
	
// when  theta is zero, using resize to avoid the one pixel tolerance at the edge.
	int pixelResX = (int)(param->resultROI[0] * resolution.x + 0.5f);
	int pixelResY = (int)(param->resultROI[1] * resolution.y + 0.5f);
	int pixelResWidth = (int)(param->resultROI[2] * resolution.x + 0.5f);
	int pixelResHeight = (int)(param->resultROI[3] * resolution.y + 0.5f);
	
	int pixelOvlX = (int)(param->origROI[0] * overlayRes.x + 0.5f);
	int pixelOvlY = (int)(param->origROI[1] * overlayRes.y + 0.5f);
	int pixelOvlWidth = (int)(param->origROI[2] * overlayRes.x + 0.5f);
	int pixelOvlHeight = (int)(param->origROI[3] * overlayRes.y + 0.5f);
	
	float2 resizeCor = (float2)( (pixelOvlWidth)/(float)(pixelResWidth) *(fragCoord.x - pixelResX) + pixelOvlX,
							   (pixelOvlHeight)/(float)(pixelResHeight) *(fragCoord.y - pixelResY) + pixelOvlY
							  );
	
	float matt = step((float)pixelOvlX - 1.0f,resizeCor.x)*step(resizeCor.x, (float)(pixelOvlX + pixelOvlWidth))*step((float)(pixelOvlY) - 1.0f,resizeCor.y)*step(resizeCor.y, (float)(pixelOvlY + pixelOvlHeight) );	
	
	vec4 controlChannel = read_imagef(control, samplerOVLN, (int2)(resizeCor.x, resizeCor.y));
	vec4 col = read_imagef(src_data, samplerOVL, coordinate);
	vec4 outputCol = col;
	
	if(matt > 0.0f)
	{
		switch(channel)
		{
			case 0: 
			outputCol = (vec4)(col.xyz, controlChannel.x*col.w);
			break;
			case 1: 
			outputCol = (vec4)(col.xyz, controlChannel.y*col.w);
			break;
			case 2: 
			outputCol = (vec4)(col.xyz, controlChannel.z*col.w);
			break;
			case 3: 
			outputCol = (vec4)(col.xyz, controlChannel.w*col.w);
			break;
		}
	 }
	 
	write_imagef(dest_data, coordinate, outputCol);
}
