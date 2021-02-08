int2 convertCoord(int2 origCoord, int origWidth, int newWidth)
{
	int temp = origCoord.y*newWidth + origCoord.x; 
	int2 newCoord;
	newCoord.x = temp%origWidth;
	newCoord.y = temp/origWidth;
	return newCoord;
}

__kernel  void MAIN(
      __read_only image2d_t src_data,          //Image Dimensions
      __write_only image2d_t dest_data,        //Data in global memory
	  __global FilterParam* param,
	  int reSizeType//if it equal to 0, it means resize to fullscreen;, //if it equal to 1, it will keep the original scale ratio after resized. 
	 )
						
{
	
   sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;
 
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

	if(reSizeType == 0)
	{
		//float4 color = read_imagef(src_data, sampler, norCoor*(float2)(origW,origH));
		temCoord = (float2)( (float)( get_global_id(0) + 0.5f )*(float)origW/newW, (float)( get_global_id(1) + 0.5f )*(float)origH/newH);
		color = read_imagef(src_data, sampler,temCoord/(float2)(origW,origH));
		
	}else
	{
		if(oH/oW < nH/nW)
		{
			float blackHeight = 0.5f*(nH - oH*nW/oW); 
			if((float)coordinate.y > blackHeight && (float)coordinate.y < blackHeight + oH*nW/oW )
			{
				temCoord = (float2) ( coordinate.x * oW/nW, (coordinate.y-blackHeight)*oW/nW );
				
				float2 tc = temCoord/(float2)(origW,origH);
				matt = step(0.0f,tc.x)*step(tc.x, 1.0f)*step(0.0f, tc.y)*step(tc.y, 1.0f);
				color = read_imagef(src_data, sampler, tc) * matt;
			}
		}
		else
		{
			float blackWidth = ( nW-(oW*nH/oH) )/2.0f;
			if( (float)coordinate.x > blackWidth && (float)coordinate.x < blackWidth + oW*nH/oH )
			{
				temCoord = (float2) ( (coordinate.x - blackWidth)*oH/nH , coordinate.y*oH/nH );
				
				float2 tc = temCoord/(float2)(origW,origH);
				matt = step(0.0f,tc.x)*step(tc.x, 1.0f)*step(0.0f,tc.y)*step(tc.y, 1.0f);
				
				color = read_imagef(src_data, sampler, tc) * matt;
			}
		}
		
	}

	write_imagef(dest_data, outCoordinate, color);
}