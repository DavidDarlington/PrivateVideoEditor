//designed by zhoubiao. 
#define maxKernelSize 101
const sampler_t samplerBG = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST; 
	const sampler_t samplerOVL = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_LINEAR;
	const sampler_t samplerOVLNN = CLK_NORMALIZED_COORDS_FALSE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_LINEAR;
	const sampler_t samplerOVLN = CLK_NORMALIZED_COORDS_FALSE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_NEAREST;
float normpdf( float x, float sigma)
{
	return 0.39894f*exp(-0.5f*x*x/(sigma*sigma))/sigma;
}
float calcsigma(float size){
	return 0.3f*(size*0.5f-1.0f)+0.8f;
}

float4 GaussionBlur(__read_only image2d_t overlay,int radius){
	float2 fragCoord = (float2)(get_global_id(0), get_global_id(1));
	int mSize = radius*2+1;
	
	if(mSize>maxKernelSize)
		mSize=maxKernelSize;
	int kSize = (mSize-1)/2;
	float array[maxKernelSize]={0.0f};
	float4 final_colour = (float4)(0.0f);	
	float sigma = calcsigma(mSize*1.0f);
	float Z = 0.0f;
	for (int j = 0; j <= kSize; ++j)
	{
		array[kSize+j] = array[kSize-j] = normpdf(j*1.0f, sigma);
	}

	//get the normalization factor (as the gaussian has been clamped)
	for (int j = 0; j < mSize; ++j)
	{
		Z += array[j];
	}

	//read out the texels
	for (int i=-kSize; i <= kSize; ++i)
	{
		for (int j=-kSize; j <= kSize; ++j)
		{
			float2 resizeCor = (float2)((fragCoord.x +i*1.0f),(fragCoord.y +1.0f*j));
			float4 color=read_imagef(overlay, samplerOVLNN, resizeCor);			
			final_colour += array[kSize+j]*array[kSize+i]*color.xyzw;

		}
	}
	float4 fragColor = (float4)(final_colour/(Z*Z));
	
	return fragColor;
	
}
float4 MeanBlur(__read_only image2d_t overlay,int radius){
	int mSize = radius*2+1;	
	int kSize = (mSize-1)/2;	
	float4 final_colour = (float4)(0.0f);		
	float2 fragCoord = (float2)(get_global_id(0), get_global_id(1));
	//read out the texels
	for (int i=-kSize; i <= kSize; ++i)
	{
		for (int j=-kSize; j <= kSize; ++j)
		{
			float2 resizeCor = (float2)((fragCoord.x +i*1.0f),(fragCoord.y +1.0f*j));
			float4 color=read_imagef(overlay, samplerOVLN, resizeCor);			
			final_colour +=color.xyzw;
		}
	}
	
	float4 fragColor = (float4)(final_colour/(mSize*mSize*1.0f));
	
	return fragColor;
	
}
__kernel void MAIN(__read_only image2d_t overlay, __write_only image2d_t dest_data,  __global FilterParam* param,  int destImageWidth,int destImageHeight,int resizeBlurType,int kernelMaxRadius){	
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));	
	int srcWidth = get_image_width(overlay);
	int srcHeight = get_image_height(overlay);	
	float2 fragCoord = (float2)(get_global_id(0), get_global_id(1));
	float4 fragColor=read_imagef(overlay, samplerOVLN, fragCoord); 
	
	// float roiX0 = param->origROI[0];
	// float roiY0 = param->origROI[1];
	// float roiX1 = param->origROI[2] + param->origROI[0];
	// float roiY1 = param->origROI[3] + param->origROI[1];
		
	// float resultX0 = param->resultROI[0];
	// float resultY0 = param->resultROI[1];
	// float resultX1 = param->resultROI[2] + param->resultROI[0];
	// float resultY1 = param->resultROI[3] + param->resultROI[1];
	int destHeight=destImageHeight;
	int destWidth=destImageWidth;
	
	//int maxKernelRadius=(srcHeight>srcWidth?srcWidth:srcHeight);
	const int maxKernelRadius=3;
	int kernelSize = 0;
	int destPixelSum = destHeight * destWidth;
	int srcPixelSum = srcHeight * srcWidth;
	// if(resizeBlurType==1){//gaussian kernel
		// if (destPixelSum != 0&&srcPixelSum >= destPixelSum*4){
			// kernelSize = (srcPixelSum / destPixelSum) >> 1;
		// }
	// }else if(resizeBlurType==0){
		// if(destPixelSum==srcPixelSum&&destHeight!=srcHeight)
			// kernelSize=1;
		// else if (destPixelSum != 0&&srcPixelSum >destPixelSum){
			// kernelSize = (srcPixelSum / destPixelSum) >> 1;
		// }
	// }
	
	if (destPixelSum != 0&&srcPixelSum >= destPixelSum*4){
			kernelSize = ((int)(sqrt((srcPixelSum*1.0f / destPixelSum*1.0f))))>>1;
			if(kernelSize>kernelMaxRadius)
				kernelSize=kernelMaxRadius;
		}
	int mSize = kernelSize*2+1;
	//fragColor=(float4)(1.0f,0.0f,0.0f,1.0f);
	if(mSize==1){
		write_imagef(dest_data, coordinate, fragColor);
		return;
	}
	if(resizeBlurType==1)
		fragColor=GaussionBlur(overlay,kernelSize);
	else if(resizeBlurType==0){
		fragColor=MeanBlur(overlay,kernelSize);
		
	}

	
	write_imagef(dest_data, coordinate, fragColor);
	
	
}