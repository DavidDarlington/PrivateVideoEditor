float2 rotateFunc(float2 uv, float2 center, float theta)
{
	float2 temp;
	temp.x = dot((float2)(cos(theta), -sin(theta)), uv - center);
	temp.y = dot((float2)(sin(theta), cos(theta)), uv - center);
	return temp+center ;
}

const sampler_t samplerBG = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_MIRRORED_REPEAT | CLK_FILTER_NEAREST;
const sampler_t samplerOVL = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_MIRRORED_REPEAT | CLK_FILTER_LINEAR;
const sampler_t samplerCopy = CLK_NORMALIZED_COORDS_FALSE| CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;

typedef struct
{
	int width[8];
	int height[8];
	float cur_time;
	float total_time;
	float origROI[4];
	float resultROI[4];
}FilterParam;

__kernel void doCopy( __read_only image2d_t src, __write_only image2d_t dest_data, __global FilterParam* param)
{
	
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	float4 ovlCol = read_imagef(src, samplerCopy, coordinate);
	write_imagef(dest_data, coordinate, ovlCol );

}

__kernel void doMask( __global uchar* mask, __read_only image2d_t background,__write_only image2d_t dest_data,  __global FilterParam* param, float theta, float blurStrength, int invertMask)
{
	const float eps = 1.0e-10f;
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));

	float2 resolution = (float2)((float)(param->width[1]),(float)(param->height[1]));
	float2 overlayRes = (float2)((float)(param->width[0]),(float)(param->height[0]));
	
	float2 fragCoord = (float2)(get_global_id(0), get_global_id(1)) + 0.5f;
	float2 tc = fragCoord/resolution.xy;
	float2 tempTc = tc;
	
	float4 bgCol = read_imagef(background, samplerBG, tempTc);
	int index = coordinate.y * param->width[1] + coordinate.x;
	__global uchar* pMaskAt = mask + index*4;
	if(1 == invertMask)
		bgCol = bgCol * (255.0f - pMaskAt[3])/255.0f;	
	else 
		bgCol = bgCol * (pMaskAt[3])/255.0f;
	write_imagef(dest_data, coordinate, bgCol);
}