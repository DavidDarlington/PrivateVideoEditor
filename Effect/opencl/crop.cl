//---------------------------------------------------------------------------------------//
// Designed by RuanShengQiang
//---------------------------------------------------------------------------------------//

#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.1415926535897932f

static float2 rotateFunc(float2 uv, float2 center, float theta)
{
	float2 temp;
	temp.x = dot((float2)(cos(theta), -sin(theta)), uv - center);
	temp.y = dot((float2)(sin(theta), cos(theta)), uv - center);
	return (temp+center);
}

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_LINEAR;
__kernel  void MAIN(
      __read_only image2d_t src_data,
      __write_only image2d_t dest_data,        //Data in global memory
	  __global FilterParam* param,
		int autoZoom,
		float theta
	 )
{
	//int blurEdges = 0;
	float left = param->origROI[0];
	float top = param->origROI[1];
	float right =  param->origROI[2] + param->origROI[0];
	float bottom = param->origROI[3] + param->origROI[1];
	
	float rdTheta = radians(theta);
	int inputW = param->width[0];
	int inputH = param->height[0];
	float2 intputResolution = (float2)(inputW,inputH);
	
	int outputW = param->width[1];
	int outputH = param->height[1];
	float2 ouputResolution = (float2)(outputW,outputH);
	
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	
	vec2 tc = (fragCoord + (vec2)(0.5f))/ouputResolution; //using outputImage coordinate as the normalized space...
	
	vec4 color = (vec4)(0.0f);
	
	float blurPixel = 0.0f;
	//if(blurEdges == 0)
	//	blurPixel = 0.0f;
		
	float xLogic = 0.0f;
	float yLogic = 0.0f;
	float featherMatt = 0.0f;
	float4 outputColor;
	float2 tranformCoord;
	float2 tempLogicCoord;
	
	float pixelLeft = left * inputW;
	float pixelRight = right * inputW;
	float pixelTop = top * inputH;
	float pixelBot = bottom * inputH;
	
	float2 center = (float2)(left + 0.5f*(right-left), top + 0.5f*(bottom - top) );

	if(autoZoom == 1)
	{
		
		xLogic = step(-1.0f, fragCoord.x) * (1.0f - step(inputW + 1, fragCoord.x));
		yLogic = step(-1.0f, fragCoord.y) * (1.0f - step(inputH + 1, fragCoord.y) );
		
		tranformCoord.x = tc.x*(right - left) + left;
		tranformCoord.y = tc.y*(bottom - top) + top;

		tranformCoord = rotateFunc(intputResolution.xy*tranformCoord,intputResolution.xy*center,rdTheta)/intputResolution.xy;
		
		float matt = step(0.0f,tranformCoord.x)*step(tranformCoord.x, 1.0f)*step(0.0f,tranformCoord.y)*step(tranformCoord.y, 1.0f);
		
		color = read_imagef(src_data, sampler, tranformCoord)*matt;
		featherMatt = yLogic*xLogic;
		outputColor = color*featherMatt;
	}else
	{
		
		xLogic = smoothstep(left, left + blurPixel/intputResolution.x, tc.x) * (1.0f - smoothstep(right - blurPixel/intputResolution.x, right, tc.x));
		yLogic = smoothstep(top, top + blurPixel/intputResolution.y, tc.y) * (1.0f - smoothstep(bottom - blurPixel/intputResolution.y, bottom, tc.y) );
		
		tc = rotateFunc(tc*ouputResolution.xy , ouputResolution.xy*center , rdTheta)/ouputResolution.xy;
		float matt = step(0.0f,tc.x)*step(tc.x, 1.0f)*step(0.0f,tc.y)*step(tc.y, 1.0f);
		color = read_imagef(src_data, sampler, tc)*matt;
		featherMatt = yLogic*xLogic;
		outputColor = color*featherMatt;
	}
	write_imagef(dest_data, coordinate, outputColor);
}