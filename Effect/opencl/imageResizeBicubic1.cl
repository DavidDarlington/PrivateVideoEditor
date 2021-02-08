#define rgb xyz
#define rgba xyzw
//https://stackoverflow.com/questions/26823140/imresize-trying-to-understand-the-bicubic-interpolation
const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_FILTER_NEAREST | CLK_ADDRESS_CLAMP_TO_EDGE;//CLK_FILTER_NEAREST  CLK_FILTER_LINEAR
float interpolationCalculate(float x) {
	float A=-0.75f;
    float absX = x >= 0.0f ? x : -x;
    float x2 = x * x;
    float x3 = absX * x2;

    if (absX <= 1.0f) {
        return 1.0f - (A + 3.0f) * x2 + (A + 2.0f) * x3;
    } else if (absX <= 2.0f) {
        return -4.0f * A + 8.0f * A * absX - 5.0f * A * x2 + A * x3;
    }

    return 0.0f;
}



float4 updateCoefficients_getValue (float4 *tmpPixels,float x,float y){
    float4* p = tmpPixels;
    float4 a00 = p[1*4+1];
    float4 a01 = -0.5f * p[1*4+0]+ 0.5f * p[1*4+2];
    float4 a02 = p[1*4+0]- 2.5f * p[1*4+1]+ 2.0f * p[1*4+2]- 0.5f * p[1*4+3];
    float4 a03 = -0.5f * p[1*4+0]+ 1.5f * p[1*4+1]- 1.5f * p[1*4+2]+ 0.5f * p[1*4+3];

    float4 a10 = -0.5f * p[0*4+1]+ 0.5f * p[2*4+1];
    float4 a11 = 0.25f * p[0*4+0]- 0.25f * p[0*4+2]- 0.25f * p[2*4+0]+ 0.25f * p[2*4+2];
    float4 a12 = -0.5f * p[0*4+0]+ 1.25f * p[0*4+1]- p[0*4+2]+ 0.25f * p[0*4+3]+ 0.5f * p[2*4+0]- 1.25f * p[2*4+1]+ p[2*4+2]- 0.25f * p[2*4+3];
    float4 a13 = 0.25f * p[0*4+0]- 0.75f * p[0*4+1] + 0.75f * p[0*4+2]- 0.25f * p[0*4+3]- 0.25f * p[2*4+0]+ 0.75f * p[2*4+1]- 0.75f * p[2*4+2]+ 0.25f * p[2*4+3];

    float4 a20 = p[0*4+1]- 2.5f * p[1*4+1]+ 2.0f * p[2*4+1]- 0.5f * p[3*4+1];
    float4 a21 = -0.5f * p[0*4+0]+ 0.5f * p[0*4+2]+ 1.25f * p[1*4+0]- 1.25f * p[1*4+2]- p[2*4+0]+ p[2*4+2]+ 0.25f * p[3*4+0]- 0.25f * p[3*4+2];
    float4 a22 = p[0*4+0]- 2.5f * p[0*4+1]+ 2.0f * p[0*4+2]- 0.5f * p[0*4+3]- 2.5f * p[1*4+0] + 6.25f * p[1*4+1]- 5.0f * p[1*4+2]+ 1.25f * p[1*4+3]+ 2.0f * p[2*4+0]- 5.0f * p[2*4+1] + 4.0f * p[2*4+2]- p[2*4+3]- 0.5f * p[3*4+0]+ 1.25f * p[3*4+1]- p[3*4+2]+ 0.25f * p[3*4+3];
    float4 a23 = -0.5f * p[0*4+0]+ 1.5f * p[0*4+1]- 1.5f * p[0*4+2]+ 0.5f * p[0*4+3]+ 1.25f * p[1*4+0]- 3.75f * p[1*4+1]+ 3.75f * p[1*4+2]- 1.25f * p[1*4+3]- p[2*4+0]+ 3.0f * p[2*4+1]- 3.0f * p[2*4+2]+ p[2*4+3]+ 0.25f * p[3*4+0]- 0.75f * p[3*4+1]+ 0.75f * p[3*4+2]- 0.25f * p[3*4+3];

    float4 a30 = -0.5f * p[0*4+1]+ 1.5f * p[1*4+1]- 1.5f * p[2*4+1]+ 0.5f * p[3*4+1];
    float4 a31 = 0.25f * p[0*4+0]- 0.25f * p[0*4+2]- 0.75f * p[1*4+0]+ 0.75f * p[1*4+2]+ 0.75f * p[2*4+0] - 0.75f * p[2*4+2]- 0.25f * p[3*4+0]+ 0.25f * p[3*4+2];
    float4 a32 = -0.5f * p[0*4+0]+ 1.25f * p[0*4+1]- p[0*4+2]+ 0.25f * p[0*4+3]+ 1.5f * p[1*4+0]- 3.75f * p[1*4+1]+ 3.0f * p[1*4+2]- 0.75f * p[1*4+3]- 1.5f * p[2*4+0]+ 3.75f * p[2*4+1]- 3.0f * p[2*4+2]+ 0.75f * p[2*4+3]+ 0.5f * p[3*4+0]- 1.25f * p[3*4+1]+ p[3*4+2]- 0.25f * p[3*4+3];
    float4 a33 = 0.25f * p[0*4+0]- 0.75f * p[0*4+1]+ 0.75f * p[0*4+2]- 0.25f * p[0*4+3]- 0.75f * p[1*4+0]+ 2.25f * p[1*4+1]- 2.25f * p[1*4+2]+ 0.75f * p[1*4+3]+ 0.75f * p[2*4+0]- 2.25f * p[2*4+1]+ 2.25f * p[2*4+2]- 0.75f * p[2*4+3]- 0.25f * p[3*4+0]+ 0.75f * p[3*4+1]- 0.75f * p[3*4+2]+ 0.25f * p[3*4+3];
		
		
	float x2 = x * x;
    float x3 = x2 * x;
    float y2 = y * y;
    float y3 = y2 * y;

    return (a00 + a01 * y + a02 * y2 + a03 * y3) +
        (a10 + a11 * y + a12 * y2 + a13 * y3) * x +
        (a20 + a21 * y + a22 * y2 + a23 * y3) * x2 +
        (a30 + a31 * y + a32 * y2 + a33 * y3) * x3;	
		
}
float4 getRGBAValue (image2d_t src_data, float srcWidth, float srcHeight, float row, float col) {
    float newRow = row;
    float newCol = col;

    if (newRow >= srcHeight) {
        newRow = srcHeight - 1;
    } else if (newRow < 0) {
        newRow = 0;
    }

    if (newCol >= srcWidth) {
        newCol = srcWidth - 1;
    } else if (newCol < 0) {
        newCol = 0;
    }
	float2 tc=(float2)(newCol,newRow);
	float4 color = read_imagef(src_data, sampler, tc);
	return color;
    
}
float4 bicubic(image2d_t src_data,float dstColIndex, float dstRowIndex,float width,float height,float scaleW,float scaleH){
	float srcCol = min(width - 1, (dstColIndex+0.5f) / scaleW-0.5f);
	float srcRow = min(height - 1, (dstRowIndex+0.5f) / scaleH-0.5f);
	int intCol = floor(srcCol);
	int intRow = floor(srcRow);
	// calculate u v
	float u = srcCol - intCol;
	float v = srcRow - intRow;
	
	
	 
	// 16 neiber
	float4 rgba=(float4)(0.0f);
	for (int m = -1; m <= 2; m += 1) {
		for (int n = -1; n <= 2; n += 1) {
			float4 value = getRGBAValue(src_data,width,height,intRow +m,intCol + n);
			float f1 = interpolationCalculate(m - v);
			float f2 = interpolationCalculate(n - u);
			float weight = f1 * f2;			
			rgba+=(value*weight);
		}
	}
	
	
	return rgba;
	
}

__kernel  void MAIN(
      __read_only image2d_t src_data,          //Image Dimensions
      __write_only image2d_t dest_data,        //Data in global memory
	  __global FilterParam* param,
	  int reSizeType//if it equal to 0, it means resize to fullscreen;, //if it equal to 1, it will keep the original scale ratio after resized. 
	 )
{
	int origW = param->width[0];
	int origH = param->height[0];
	int newW = param->width[1];
	int newH = param->height[1];

	float2 coordinate = (float2)(get_global_id(0), get_global_id(1)) + (float2)(0.5f);

	int2 outCoordinate = (int2)(get_global_id(0), get_global_id(1));

	float2 norCoor = ((float2)(get_global_id(0), get_global_id(1)) + (float2)(0.5f))/(float2)(newW,newH);

	float2 origCenter = (float2)(newW,newH)/2.0f;

	float nW = newW;
	float nH = newH;
	float oW = origW;
	float oH = origH;
	float2 temCoord = (float2)(0.0f);
	float4 color= (float4)(0.0f); 
	float matt; 

	if(reSizeType == 0){
		//caculate radio
		float scaleW = nW / oW;
		float scaleH = nH / oH;
		//do copy
		if(scaleW==1.0f&&scaleH==1.0f){
			color = read_imagef(src_data, sampler, outCoordinate);
			//color=(float4)(1.0f,0.0f,0.0f,1.0f);
			write_imagef(dest_data, outCoordinate, color);
			return;
		}
		else{
			color=bicubic(src_data,coordinate.x,coordinate.y,oW,oH,scaleW,scaleH);
			//color=(float4)(1.0f,0.0f,0.0f,1.0f);
			write_imagef(dest_data, outCoordinate, color);
			return;
		}		
	}
	else{
		if(oH/oW < nH/nW)
		{
			float blackHeight = 0.5f*(nH - oH*nW/oW); 
			float dstH=oH*nW/oW;
			float scaleW=nW/oW;
			float scaleH=dstH/oH;
			
			if((float)coordinate.y > blackHeight && (float)coordinate.y < blackHeight + oH*nW/oW )
			{
				color=bicubic(src_data,coordinate.x,coordinate.y-blackHeight,oW,oH,scaleW,scaleH);
				//color=(float4)(1.0f,0.0f,0.0f,1.0f);
				write_imagef(dest_data, outCoordinate, color);
				return;
			}else{
				write_imagef(dest_data, outCoordinate, color);
				return;
			}
		}
		else
		{
			float blackWidth = ( nW-(oW*nH/oH) )/2.0f;
			float dstW=oW*nH/oH;
			float scaleW=dstW/oW;
			float scaleH=nH/oH;
			//do copy
			if(scaleW==1.0f&&scaleH==1.0f){
				color = read_imagef(src_data, sampler, outCoordinate);
				//color=(float4)(1.0f,0.0f,0.0f,1.0f);
				write_imagef(dest_data, outCoordinate, color);
				return;
			}
			else if((float)coordinate.x > blackWidth && (float)coordinate.x < blackWidth + oW*nH/oH )
			{
				color=bicubic(src_data,coordinate.x-blackWidth,coordinate.y,oW,oH,scaleW,scaleH);
				//color=(float4)(1.0f,0.0f,0.0f,1.0f);
				write_imagef(dest_data, outCoordinate, color);
				return;
			}else{
				write_imagef(dest_data, outCoordinate, color);
				return;
			}
		}
	}


}

















