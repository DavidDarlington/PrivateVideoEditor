#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;
static int myStep(int a, int b)
{
	if(a<b)
		return 1;
	else 
		return 0;
}
 __kernel void MAIN(
      __read_only image2d_t src,
      __write_only image2d_t dest_data,
      __global FilterParam* param,
	  
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
	  int lineB1
	  
	
	  ) // the line color 
{
	
	int W = param->width[0];
	int H = param->height[0];
	vec2 iResolution = (vec2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	float2 fragCoord = (float2)(get_global_id(0), get_global_id(1)) + 0.5f;
	
	int linePixel = 1; 
	
	vec4 color = (vec4)(0.0f, 0.0f, 0.0f, 0.0f);
	float renderflag = myStep(fLeft - 1, gl_FragCoord.x)*myStep(fTop - 1, gl_FragCoord.y)*myStep(gl_FragCoord.x, fLeft+editViewsWidth )*myStep(gl_FragCoord.y, fTop+editViewsHeight);
	
	float outlineflag1 = 0;
	float outlineflag5 = 0;
	float outlineflag3 = 0;
	float outlineflag7 = 0;
	
	vec4 bgColor = read_imagef(src, sampler, gl_FragCoord);
		
	if(outLineSafeZoom)
	{
		outlineflag1  = myStep(outLineLeft, gl_FragCoord.x)*myStep(outLineTop , gl_FragCoord.y)*myStep(gl_FragCoord.x, outLineLeft + outLineWidth - 1)*myStep(gl_FragCoord.y, outLineTop + outLineHeight -1);
		float outlineflag2 = myStep(outLineLeft - linePixel, gl_FragCoord.x)*myStep(outLineTop - linePixel , gl_FragCoord.y)*myStep(gl_FragCoord.x,outLineLeft + outLineWidth + linePixel -1 )*myStep(gl_FragCoord.y, outLineTop + outLineHeight + linePixel -1);
		outlineflag1 = outlineflag2 - outlineflag1; // the line mask
		
		outlineflag5  = myStep(outLineLeft + 1, gl_FragCoord.x)*myStep(outLineTop + 1 , gl_FragCoord.y)*myStep(gl_FragCoord.x, outLineLeft + outLineWidth )*myStep(gl_FragCoord.y, outLineTop + outLineHeight );
		float outlineflag6 = myStep(outLineLeft - linePixel + 1, gl_FragCoord.x)*myStep(outLineTop - linePixel + 1 , gl_FragCoord.y)*myStep(gl_FragCoord.x,outLineLeft + outLineWidth + linePixel  )*myStep(gl_FragCoord.y, outLineTop + outLineHeight + linePixel );
		outlineflag5 = outlineflag6 - outlineflag5;
		
		if( outlineflag5 > 0.9f)
		{
			color = (vec4)(lineR1, lineG1, lineB1, 255.0f)/255.0f;
			bgColor.w = 1.0f;
		}
		
		if( outlineflag1 > 0.9f)
		{
			color = (vec4)(lineR0, lineG0, lineB0, 255.0f)/255.0f;
			bgColor.w = 1.0f;
		}
		
			
	}
	
	if(inLineSafeZoom)
	{
	
		outlineflag3  = myStep(inLineLeft, gl_FragCoord.x)*myStep(inLineTop, gl_FragCoord.y)*myStep(gl_FragCoord.x, inLineLeft + inLineWidth - 1)*myStep(gl_FragCoord.y, inLineTop + inLineHeight -1 );
		float outlineflag4 = myStep(inLineLeft  - linePixel, gl_FragCoord.x)*myStep(inLineTop - linePixel, gl_FragCoord.y)*myStep(gl_FragCoord.x, inLineLeft + inLineWidth + linePixel - 1 )*myStep(gl_FragCoord.y, inLineTop + inLineHeight + linePixel - 1);
		outlineflag3 = outlineflag4 - outlineflag3;

		outlineflag7  = myStep(inLineLeft + 1, gl_FragCoord.x)*myStep(inLineTop + 1, gl_FragCoord.y)*myStep(gl_FragCoord.x, inLineLeft + inLineWidth - 1)*myStep(gl_FragCoord.y, inLineTop + inLineHeight - 1 );
		float outlineflag8 = myStep(inLineLeft  - linePixel + 1, gl_FragCoord.x)*myStep(inLineTop - linePixel + 1, gl_FragCoord.y)*myStep(gl_FragCoord.x, inLineLeft + inLineWidth + linePixel )*myStep(gl_FragCoord.y, inLineTop + inLineHeight + linePixel );
		outlineflag7 = outlineflag8 - outlineflag7;
	
		if( outlineflag7 > 0.9f)
		{
			color = (vec4)(lineR1, lineG1, lineB1, 255.0f)/255.0f;
			bgColor.w = 1.0f;
		}
			
				if( outlineflag3 > 0.9f)
		{
			color = (vec4)(lineR0, lineG0, lineB0, 255.0f)/255.0f;
			bgColor.w = 1.0f;
		}
				
	}
	
	if( outlineflag3 + outlineflag7 + outlineflag1 + outlineflag5  < 0.1f)
	{
		color = (vec4)(outSideAreaR, outSideAreaG, outSideAreaB, outSideAreaA)/255.0f*(1.0f - renderflag);
	}
	

	
	if((1.0f - renderflag)>0.0f)
		write_imagef(dest_data, gl_FragCoord,  (vec4)(color.w*color.xyz + (1.0f -  color.w)*bgColor.xyz*bgColor.w, 1.0f));
	else 
		write_imagef(dest_data, gl_FragCoord,  (vec4)(color.w*color.xyz + (1.0f -  color.w)*bgColor.xyz, bgColor.w));
}