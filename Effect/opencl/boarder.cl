#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE| CLK_FILTER_LINEAR;

__kernel void MAIN(
      __read_only image2d_t input1,
      __write_only image2d_t dest_data,
      __global FilterParam* param,
					float amp,
					float opacity,
					float R,
					float G,
					float B)
{

	int W = param->width[0];
	int H = param->height[0];
	vec2 u_resolution = (vec2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	float2 fragCoord = (float2)(get_global_id(0), get_global_id(1)) + 0.5f;
	float roiX0 = param->origROI[0];
	float roiY0 = param->origROI[1];
	float roiX1 = param->origROI[2] + param->origROI[0];
	float roiY1 = param->origROI[3] + param->origROI[1];
	
	float resultX0 = param->resultROI[0];
	float resultY0 = param->resultROI[1];
	float resultX1 = param->resultROI[2] + param->resultROI[0];
	float resultY1 = param->resultROI[3] + param->resultROI[1];
	
	float width = resultX1 - resultX0;
	float height = resultY1 - resultY0;
	
	float2 tc = fragCoord/u_resolution.xy;
	float4 outputCol = read_imagef(input1, sampler, tc);
	
	width = width*u_resolution.x; 
	height = height*u_resolution.y;
	float ampx  = amp;
	float ampy  = amp;
	/*
	if(u_resolution.x < u_resolution.y)
	{
		ampx  = amp/2.0f*u_resolution.x;
		ampy  = amp/2.0f*u_resolution.x;
	}	
	if(height>width)
	{
		ampx  = ampx * width/(float)(u_resolution.x);
		ampy  = ampy * width/(float)(u_resolution.x);
	}else
	{
		ampx  = ampx * height/(float)(u_resolution.y);
		ampy  = ampy * height/(float)(u_resolution.y);
	}
	*/
	float pro;
	float pixelX0 = resultX0 * u_resolution.x;
	float pixelY0 = resultY0 * u_resolution.y;
	float pixelX1 = resultX1 * u_resolution.x;
	float pixelY1 = resultY1 * u_resolution.y;
	
	float matt = step(ampx + pixelX0, fragCoord.x)*step(fragCoord.x, pixelX1 - ampx)*step(ampy + pixelY0, fragCoord.y)*step(fragCoord.y, pixelY1 - ampy );
	
	float outMatt = step(pixelX0, fragCoord.x)*step(fragCoord.x, pixelX1)*step(pixelY0, fragCoord.y)*step(fragCoord.y, pixelY1);
	
	if( outMatt - matt < 0.5f)
		write_imagef( dest_data, gl_FragCoord, outputCol );
	else
		write_imagef( dest_data, gl_FragCoord, (float4)((vec3)(R, G, B)*opacity + (1.0f - opacity)*outputCol.xyz, outputCol.w) );

	
}