float2 rotateFunc(float2 uv, float2 center, float theta)
{
	float2 temp;
	temp.x = dot((float2)(cos(theta), -sin(theta)), uv - center);
	temp.y = dot((float2)(sin(theta), cos(theta)), uv - center);
	return(temp+center);
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

__kernel void doMask4Chnl( __read_only image2d_t mask, __read_only image2d_t background,__write_only image2d_t dest_data,  __global FilterParam* param, float theta, int invertMask)
{
	const float eps = 1.0e-10f;
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));

	float2 resolution = (float2)((float)(param->width[1]),(float)(param->height[1]));
	float2 overlayRes = (float2)((float)(param->width[0]),(float)(param->height[0]));
	
	float2 fragCoord = (float2)(get_global_id(0), get_global_id(1)) + 0.5f;
	float2 tc = fragCoord/resolution.xy;
	float2 tempTc = tc;

	float roiX0 = 0.0f;//param->origROI[0];
	float roiY0 = 0.0f;//param->origROI[1];
	float roiX1 = 1.0f;//param->origROI[2] + param->origROI[0];
	float roiY1 = 1.0f;//param->origROI[3] + param->origROI[1];

	float resultX0 = param->resultROI[0];
	float resultY0 = param->resultROI[1];
	float resultX1 = param->resultROI[2] + param->resultROI[0];
	float resultY1 = param->resultROI[3] + param->resultROI[1];

	float2 roiCenter = (float2)((roiX1-roiX0)*0.5f + roiX0, (roiY1-roiY0)*0.5f + roiY0);
	float2 resultRoiCenter = (float2)((resultX1-resultX0)*0.5f + resultX0, (resultY1-resultY0)*0.5f + resultY0);
	float2 transl =  resultRoiCenter - roiCenter;
	
	float scalFactorX = (resultX1 - resultX0)/(roiX1 - roiX0);
	float scalFactorY = (resultY1 - resultY0)/(roiY1 - roiY0);

	float _theta = -0.0174532925199433f*theta;
    tc = tc  - transl;
	float2 center = roiCenter;
	tc = rotateFunc(tc*resolution.xy,resolution.xy*center,_theta)/resolution.xy;
	float2  renderModeDirectCor = tc;
	tc.x = ( tc.x - center.x )/(scalFactorX+eps) + center.x ;
	tc.y = ( tc.y - center.y )/(scalFactorY+eps) + center.y;
		
	float matt = step(roiX0,tc.x)*step(tc.x, roiX1)*step(roiY0,tc.y)*step(tc.y, roiY1);
	
	float4 bgCol = read_imagef(background, samplerBG, tempTc);
	float4 ovlCol = read_imagef(mask, samplerOVL, tc)*matt;
	
	if(1 == invertMask)
		matt = 1.0f - ovlCol.w;
	else
		matt = ovlCol.w;
	
	//write_imagef(dest_data, coordinate, (float4)(bgCol.xyz, bgCol.w * matt) );
	write_imagef(dest_data, coordinate, bgCol *matt);
}

__kernel void doMaskOneChnl( __read_only image2d_t mask, __read_only image2d_t background,__write_only image2d_t dest_data,  __global FilterParam* param, float theta, int invertMask)
{
	const float eps = 1.0e-10f;
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));

	float2 resolution = (float2)((float)(param->width[1]),(float)(param->height[1]));
	float2 overlayRes = (float2)((float)(param->width[0]),(float)(param->height[0]));
	
	float2 fragCoord = (float2)(get_global_id(0), get_global_id(1)) + 0.5f;
	float2 tc = fragCoord/resolution.xy;
	float2 tempTc = tc;

	float roiX0 = 0.0f;//param->origROI[0];
	float roiY0 = 0.0f;//param->origROI[1];
	float roiX1 = 1.0f;//param->origROI[2] + param->origROI[0];
	float roiY1 = 1.0f;//param->origROI[3] + param->origROI[1];

	float resultX0 = param->resultROI[0];
	float resultY0 = param->resultROI[1];
	float resultX1 = param->resultROI[2] + param->resultROI[0];
	float resultY1 = param->resultROI[3] + param->resultROI[1];

	float2 roiCenter = (float2)((roiX1-roiX0)*0.5f + roiX0, (roiY1-roiY0)*0.5f + roiY0);
	float2 resultRoiCenter = (float2)((resultX1-resultX0)*0.5f + resultX0, (resultY1-resultY0)*0.5f + resultY0);
	float2 transl =  resultRoiCenter - roiCenter;
	
	float scalFactorX = (resultX1 - resultX0)/(roiX1 - roiX0);
	float scalFactorY = (resultY1 - resultY0)/(roiY1 - roiY0);

	float _theta = -0.0174532925199433f*theta;
    tc = tc  - transl;
	float2 center = roiCenter;
	tc = rotateFunc(tc*resolution.xy,resolution.xy*center,_theta)/resolution.xy;
	float2  renderModeDirectCor = tc;
	tc.x = ( tc.x - center.x )/(scalFactorX+eps) + center.x ;
	tc.y = ( tc.y - center.y )/(scalFactorY+eps) + center.y;
		
	float matt = step(roiX0,tc.x)*step(tc.x, roiX1)*step(roiY0,tc.y)*step(tc.y, roiY1);
	
	float4 bgCol = read_imagef(background, samplerBG, tempTc);
	float4 ovlCol = read_imagef(mask, samplerOVL, tc)*matt;
	
	if(1 == invertMask)
		matt = 1.0f - ovlCol.w;
	else
		matt = ovlCol.w;
	
	if(matt < 0.00001f)
		bgCol = (float4)(0.0f);
	write_imagef(dest_data, coordinate, (float4)(bgCol.xyz, bgCol.w * matt) );
}