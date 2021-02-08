
//designed by RuanShengQiang. 
//tempMatt: matt without alpha
//matt: matt with altph.

float4 blending(float4 backGround, float4 ovl, float matt, float tempMatt, float exeMatt)
{
	float opacity = 1.0f; 
	float4 outputColor = (float4)(0.0f);
	float4 overlay = ovl * tempMatt * exeMatt; 
	float4 bgCol = backGround;
	float tempOpacity = opacity * matt * exeMatt;
	float invTemOpacity = 1.0f - tempOpacity;
	
	outputColor = overlay;
	tempOpacity = opacity * tempMatt * exeMatt;
	
	outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
	outputColor.w = overlay.w * overlay.w + (1.0f - overlay.w)* bgCol.w;
	return outputColor*tempOpacity + invTemOpacity*bgCol;
	
}

void moveX(float* resultX0, float* resultY0, float* resultX1, float* resultY1, float progress)
{
	*resultX0 = *resultX0 + progress;
	*resultX1 = *resultX1 + progress;
}

__kernel void MAIN(__read_only image2d_t overlay, __read_only image2d_t background, __write_only image2d_t dest_data,  __global FilterParam* param,  float visX0,float visY0, float visWidth,float visHeight, int inORout) // inORout: 0 - enter the arena; 1 - out the arena
{
	const sampler_t samplerBG = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST; 
	const sampler_t samplerOVL = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_LINEAR;
	float progress = param->cur_time / param->total_time;
	
	const float eps = 1.0e-10f;
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));

	float2 resolution = (float2)((float)(param->width[1]),(float)(param->height[1]));
	float2 overlayRes = (float2)((float)(param->width[0]),(float)(param->height[0]));
	
	float2 fragCoord = (float2)(get_global_id(0), get_global_id(1))+0.5f;
	float2 tc = fragCoord/resolution.xy;
	float2 tempTc = tc;
	float2 tempTcExe = tc; 

	float roiX0 = visX0;
	float roiY0 = visY0;
	float roiX1 = visX0 + visWidth;
	float roiY1 = visY0 + visHeight;
	
	float resultX0 = visX0 ;
	float resultY0 = visY0;
	float resultX1 = visX0 + visWidth;
	float resultY1 = visY0 + visHeight;
	
	float4 bgCol = (float4)(0.0f);//
	
	if(inORout == 0)
	{
		bgCol = read_imagef(overlay, samplerBG, tempTc);
		progress = ( 3.0f*progress*progress - 2.0f * progress*progress*progress - 1.0f)*(visWidth);
		//3*x*x - 2*x*x*x -1
	}else
	{
		bgCol = read_imagef(background, samplerBG, tempTc);
		progress = ( 2.0f * progress*progress*progress - 3.0f*progress*progress )*(visWidth);
		//2*x*x*x- 3*x*x 
	}
	moveX(&resultX0, &resultY0, &resultX1, &resultY1, progress);
	
	float2 roiCenter = (float2)((roiX1-roiX0)*0.5f + roiX0, (roiY1-roiY0)*0.5f + roiY0);
	float2 resultRoiCenter = (float2)((resultX1-resultX0)*0.5f + resultX0, (resultY1-resultY0)*0.5f + resultY0);
	float2 transl =  resultRoiCenter - roiCenter;
	
	float scalFactorX = 1.0f;//(resultX1 - resultX0)/(roiX1 - roiX0);
	float scalFactorY = 1.0f;//(resultY1 - resultY0)/(roiY1 - roiY0);

    tc = tc  - transl;
	float2 center = roiCenter;
	float2  renderModeDirectCor = tc;
	tc.x = ( tc.x - center.x )/(scalFactorX+eps) + center.x ;
	tc.y = ( tc.y - center.y )/(scalFactorY+eps) + center.y;

	float smoothGap = 2.0f/resolution.x; 
	float matt = step(roiX0,tc.x)*step(tc.x, roiX1)*step(roiY0,tc.y)*step(tc.y, roiY1);

	
	float2 RenderMode_Fill = (float2)(0.0f);
	
	float pixelOvlWidth = (roiX1-roiX0)*overlayRes.x;
	float pixelOvlHeight = (roiY1-roiY0)*overlayRes.y;
	float pixelResWidth = (resultX1 - resultX0)*resolution.x;
	float pixelResHeight = (resultY1 - resultY0)*resolution.y;
		
	float origRatio = pixelOvlHeight/pixelOvlWidth; 
	float resRatio = pixelResHeight/pixelResWidth; 
	
	float roiOrigRatio =  (roiY1-roiY0)/(roiX1-roiX0);

	float4 ovlCol = (float4)(0.0f);
	if(inORout == 0)
	{
		ovlCol = read_imagef(background, samplerOVL, tc);
	}else
	{
		ovlCol = read_imagef(overlay, samplerOVL, tc);
	}
	
	float exeMatt = step(visX0,tempTcExe.x)*step(tempTcExe.x, visX0+visWidth)*step(visY0,tempTcExe.y)*step(tempTcExe.y, visY0+visHeight);
	float tempMatt = matt;
	matt = matt*ovlCol.w*exeMatt;
	
	float4 outputCol = blending( bgCol, ovlCol, matt, tempMatt, exeMatt);
	write_imagef(dest_data, coordinate, outputCol);
}