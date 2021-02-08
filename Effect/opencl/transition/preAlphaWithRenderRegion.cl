
//designed by RuanShengQiang. 

static int myStep(int a, int b)
{
	if(a<b)
		return 1;
	else 
		return 0;
}


//isShowRRMask: 0, 不显示渲染区域蒙版， 1，显示渲染区域蒙版

__kernel void MAIN(__read_only image2d_t overlay, 
					__write_only image2d_t dest_data,  __global FilterParam* param, 
					
					// start: 渲染区域部分的参数
					int isShowRRMask,
					int outLineSafeZoom,
					int inLineSafeZoom,
	  
					int fLeft,
					int fTop,
					int editViewsWidth,
					int editViewsHeight, //render area
					int outSideAreaR,
					int outSideAreaG,
					int outSideAreaB, 
					int outSideAreaA, // the color of area outside render area
	  
					int outLineLeft,
					int outLineTop,
					int outLineWidth,
					int outLineHeight,
	  
					int inLineLeft,
					int inLineTop,
					int inLineWidth,
					int inLineHeight,
	  
					int lineR0,
					int lineG0,
					int lineB0,
	  
					int lineR1,
					int lineG1,
					int lineB1)
					// end: 渲染区域部分的参数)
{
	
	sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE |  CLK_FILTER_NEAREST;
	int origW = param->width[0];
	int origH = param->height[0];
	int newW = param->width[1];
	int newH = param->height[1];
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	float2 temCoord = (float2)(0.0f);
	float4 color= read_imagef(overlay, sampler,coordinate);
	
	float4 outputCol = (float4)(color.xyz*color.w, color.w);
	
	if(isShowRRMask)
	{
		int linePixel = 1; 
	
		float4 color = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
		float renderflag = myStep(fLeft - 1, coordinate.x)*myStep(fTop - 1, coordinate.y)*myStep(coordinate.x, fLeft+editViewsWidth )*myStep(coordinate.y, fTop+editViewsHeight);
		
		float outlineflag1 = 0;
		float outlineflag5 = 0;
		float outlineflag3 = 0;
		float outlineflag7 = 0;
		if(outLineSafeZoom)
		{
			outlineflag1  = myStep(outLineLeft, coordinate.x)*myStep(outLineTop , coordinate.y)*myStep(coordinate.x, outLineLeft + outLineWidth - 1)*myStep(coordinate.y, outLineTop + outLineHeight -1);
			float outlineflag2 = myStep(outLineLeft - linePixel, coordinate.x)*myStep(outLineTop - linePixel , coordinate.y)*myStep(coordinate.x,outLineLeft + outLineWidth + linePixel -1 )*myStep(coordinate.y, outLineTop + outLineHeight + linePixel -1);
			outlineflag1 = outlineflag2 - outlineflag1; // the line mask
			
			outlineflag5  = myStep(outLineLeft + 1, coordinate.x)*myStep(outLineTop + 1 , coordinate.y)*myStep(coordinate.x, outLineLeft + outLineWidth - 2)*myStep(coordinate.y, outLineTop + outLineHeight -2);
			float outlineflag6 = myStep(outLineLeft - linePixel + 1, coordinate.x)*myStep(outLineTop - linePixel + 1 , coordinate.y)*myStep(coordinate.x,outLineLeft + outLineWidth + linePixel -2 )*myStep(coordinate.y, outLineTop + outLineHeight + linePixel -2);
			outlineflag5 = outlineflag6 - outlineflag5;
			
			if( outlineflag1 > 0.9f)
				color = (float4)(lineR0, lineG0, lineB0, 255.0f)/255.0f;
			if( outlineflag5 > 0.9f)
				color = (float4)(lineR1, lineG1, lineB1, 255.0f)/255.0f;
		
		}
		
		if(inLineSafeZoom)
		{
		
			outlineflag3  = myStep(inLineLeft, coordinate.x)*myStep(inLineTop, coordinate.y)*myStep(coordinate.x, inLineLeft + inLineWidth - 1)*myStep(coordinate.y, inLineTop + inLineHeight -1 );
			float outlineflag4 = myStep(inLineLeft  - linePixel, coordinate.x)*myStep(inLineTop - linePixel, coordinate.y)*myStep(coordinate.x, inLineLeft + inLineWidth + linePixel - 1 )*myStep(coordinate.y, inLineTop + inLineHeight + linePixel - 1);
			outlineflag3 = outlineflag4 - outlineflag3;

			outlineflag7  = myStep(inLineLeft + 1, coordinate.x)*myStep(inLineTop + 1, coordinate.y)*myStep(coordinate.x, inLineLeft + inLineWidth - 2)*myStep(coordinate.y, inLineTop + inLineHeight - 2 );
			float outlineflag8 = myStep(inLineLeft  - linePixel + 1, coordinate.x)*myStep(inLineTop - linePixel + 1, coordinate.y)*myStep(coordinate.x, inLineLeft + inLineWidth + linePixel - 2 )*myStep(coordinate.y, inLineTop + inLineHeight + linePixel - 2);
			outlineflag7 = outlineflag8 - outlineflag7;
			
			if( outlineflag3 > 0.9f)
				color = (float4)(lineR0, lineG0, lineB0, 255.0f)/255.0f;
				
			if( outlineflag7 > 0.9f)
				color = (float4)(lineR1, lineG1, lineB1, 255.0f)/255.0f;
				
		}
		
		if( outlineflag3 + outlineflag7 + outlineflag1 + outlineflag5  < 0.1f)
		{
			color = (float4)(outSideAreaR, outSideAreaG, outSideAreaB, outSideAreaA)/255.0f*(1.0f - renderflag);
		}
		
		float4 bgColor = outputCol;
		
		if((1.0f - renderflag)>0.0f)
			write_imagef(dest_data, coordinate,  (float4)(color.w*color.xyz + (1.0f -  color.w)*bgColor.xyz*bgColor.w, 1.0f));
		else 
			write_imagef(dest_data, coordinate,  (float4)(color.w*color.xyz + (1.0f -  color.w)*bgColor.xyz, 1.0f));
	}else
	{
		write_imagef(dest_data, coordinate, outputCol);
	}
	
	
}