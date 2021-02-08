
//designed by RuanShengQiang. 
float4 colorDodge(float4 bgCol, float4 overlay )
{
	float4 outputColor = bgCol/(1.0f - overlay);
	
	if(overlay.x >0.99999f)
		outputColor.x = 1.0f;
	if(overlay.y >0.99999f)
		outputColor.y = 1.0f;
	if(overlay.z >0.99999f)
		outputColor.z = 1.0f;
	
	return outputColor;
}

float4 colorBurn(float4 bgCol, float4 overlay )
{
	
	float4 outputColor = 1.0f - (1.0f-bgCol) / overlay; 
			
	if(overlay.x < 0.000001f)
		outputColor.x = 0.0f;
	if(overlay.y < 0.000001f)
		outputColor.y = 0.0f;
	if(overlay.z < 0.000001f)
		outputColor.z = 0.0f;
	return outputColor;
}

float4 colorDodgeForHardMix(float4 bgCol, float4 overlay )
{
	float4 outputColor = bgCol/(1.0f - overlay);
	
	if(bgCol.x < 0.000001f)
		outputColor.x = 0.0f;
	if(bgCol.y < 0.000001f)
		outputColor.y = 0.0f;
	if(bgCol.z < 0.000001f)
		outputColor.z = 0.0f;
	
	return outputColor;
}

float4 colorBurnForHardMix(float4 bgCol, float4 overlay )
{
	
	float4 outputColor = 1.0f - (1.0f-bgCol) / overlay; 
			
	if(bgCol.x > 0.9999999f)
		outputColor.x = 1.0f;
	if(bgCol.y > 0.9999999f)
		outputColor.y = 1.0f;
	if(bgCol.z > 0.9999999f)
		outputColor.z = 1.0f;
	return outputColor;
}

//tempMatt: matt without alpha
//matt: matt with altph.

float4 blending(float4 backGround, float4 ovl, float matt, float tempMatt, float exeMatt, int blendingMode, float opacity, int ovlAlphaPreMul)
{
	
	float4 outputColor = (float4)(0.0f);
	float4 overlay = ovl * tempMatt * exeMatt; 
	float4 bgCol = backGround;
	float tempOpacity = opacity * matt * exeMatt;
	float invTemOpacity = 1.0f - tempOpacity;
	switch(blendingMode)
	{
		case 0:// normal,
			//bgCol = (float4)(bgCol.xyz*bgCol.w, bgCol.w);			
			outputColor = overlay;
			if(ovlAlphaPreMul == 0)
			{				
                outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
			    outputColor.w = tempOpacity + invTemOpacity* bgCol.w;
                outputColor.xyz = outputColor.xyz*tempOpacity + invTemOpacity*bgCol.xyz;
                outputColor.xyz = clamp( outputColor.xyz, (float3)(0.0f), (float3)(1.0f) );
        
                return outputColor; 
			}else{
				
                outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
                outputColor.w = tempOpacity + invTemOpacity* bgCol.w;
                float fOpacity = opacity * tempMatt;
                outputColor.xyz = outputColor.xyz*fOpacity + invTemOpacity*bgCol.xyz;
                outputColor.xyz = clamp( outputColor.xyz, (float3)(0.0f), (float3)(1.0f) );        
                return outputColor;                 
			}
			
			
	
		case 1: // Darken
			outputColor = min(overlay,bgCol);
			break;
		case 2: //multiply
			outputColor = bgCol * overlay; 
			break;
		case 3: //  color burn // 1 - (1-Target) / Blend
		{
				float4 temp = (1.0f-bgCol) / overlay; 
				if(bgCol.x > 0.99999f)
					temp.x = 0.0f;
				if(bgCol.y > 0.99999f)
					temp.y = 0.0f;
				if(bgCol.z > 0.99999f)
					temp.z = 0.0f;
				outputColor = 1.0f - temp ;
		}
			break;
		case 4: // Linear burn
			outputColor = overlay + bgCol -1.0f;
			break;
		case 5: //screen
			outputColor =  1.0f - (1.0f-bgCol)*(1.0f-overlay);
			break;
		case 6: //color dodge
		{
			outputColor = bgCol/(1.0f - overlay);
		
			 if (bgCol.x < 0.00001f)
				outputColor.x = 0.0f;
			if (bgCol.y < 0.00001f)
				outputColor.y = 0.0f;
			if (bgCol.z < 0.00001f)
				outputColor.z = 0.0f;
		}
			break ;
		case 7://Linear Dodge
			outputColor = overlay + bgCol;
			break;
		case 8: //overlay // (Target > 0.5f) * (1 - (1-2*(Target-0.5)) * (1-Blend)) + (Target <= 0.5f) * ((2*Target) * Blend)
		{
			float3 a = (float3)( (bgCol.x > 0.5f?1.0f:0.0f), (bgCol.y > 0.5f?1.0f:0.0f), (bgCol.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)((bgCol.x <=  0.5f?1.0f:0.0f), (bgCol.y <=  0.5f?1.0f:0.0f), (bgCol.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a * (1.0f - (1.0f-2.0f*(bgCol.xyz-0.5f)) * (1.0f-overlay.xyz)) + b * ((2.0f*bgCol.xyz) * overlay.xyz);
		}
			break;
		case 9: //Soft Light // 
		{
			float3 a = (float3)( (overlay.x > 0.5f?1.0f:0.0f), (overlay.y > 0.5f?1.0f:0.0f),  (overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (overlay.x <=  0.5f?1.0f:0.0f), (overlay.y <=  0.5f?1.0f:0.0f),  (overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a * (2.0f*bgCol.xyz*(1.0f - overlay.xyz) + sqrt(bgCol.xyz)*(2.0f*overlay.xyz - 1.0f)) \
							+ b * (2.0f*bgCol.xyz*overlay.xyz + bgCol.xyz*bgCol.xyz*(1.0f - 2.0f*overlay.xyz));
		}
			break;	
		case 10://Hard Light //(Blend > 0.5) * (1 - (1-Target) * (1-2*(Blend-0.5))) + (Blend <= 0.5) * (Target * (2*Blend))
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a * (1.0f - (1.0f-bgCol.xyz) * (1.0f-2.0f*(overlay.xyz-0.5f))) + b * (bgCol.xyz * (2.0f*overlay.xyz));

			break;
		}		
		case 11://vivid light //// (Blend > 0.5) * (1 - (1-Target) / (2*(Blend-0.5))) + (Blend <= 0.5) * (Target / (1-2*Blend))
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			
			outputColor.xyz = b * colorBurn(bgCol,(2.0f*overlay)).xyz + a * colorDodge(bgCol, (2.0f*(overlay - 0.5f))).xyz;
			
		}
			break;
		case 12:// Linear Light//  (Blend > 0.5) * (Target + 2*(Blend-0.5)) + (Blend <= 0.5) * (Target + 2*Blend - 1)
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a* (bgCol.xyz + 2.0f*(overlay.xyz - 0.5f)) + b* (bgCol.xyz + 2.0f*overlay.xyz - 1.0f);
		}
			break;
			
		case 13: //PIN Light// (Blend > 0.5) * (max(Target,2*(Blend-0.5))) + (Blend <= 0.5) * (min(Target,2*Blend)))
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a* (max(bgCol.xyz,2.0f*(overlay.xyz-0.5f))) + b * (min(bgCol.xyz, 2.0f*overlay.xyz));
		}
			break;
		case 14: // hardmix  (VividLight(A,B) < 128) ? 0 : 255
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = b * colorBurnForHardMix(bgCol,(2.0f*overlay)).xyz + a * colorDodgeForHardMix(bgCol, (2.0f*(overlay - 0.5f))).xyz;
			outputColor.xyz = (float3)( (float)(outputColor.x >= 0.5f?1.0f:0.0f), (float)(outputColor.y >= 0.5f?1.0f:0.0f),(float)(outputColor.z >= 0.5f?1.0f:0.0f));
			//outputColor.xyz = (float3)( (float)(overlay.x + bgCol.x >= 1.0f?1.0f:0.0f), (float)(overlay.y + bgCol.y >= 1.0f?1.0f:0.0f),(float)(overlay.z + bgCol.z >= 1.0f?1.0f:0.0f));
		}
			break;
			
		case 15://Difference
			outputColor = fabs( overlay - bgCol );
			break;
		case 16://exclusion // 0.5 - 2*(Target-0.5)*(Blend-0.5)
			outputColor = 0.5f - 2.0f*(overlay-0.5f)*(bgCol-0.5f);
			break;
		case 17://Lighten // max(Target,Blend)   
			outputColor = max(overlay,bgCol);
			break;
			
		case 19: // hollow in 
			outputColor = bgCol*overlay.w;
			outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
			return outputColor;
			break;
		case 20: // hollow out 
			outputColor = bgCol;
			if(bgCol.w < 0.000001f)
				outputColor = overlay;
			else 
				outputColor = bgCol*(1.0f - overlay.w);
			outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
			return outputColor;
			break;
		case 21: // backGround hollow in 
			outputColor = overlay*bgCol.w;
			outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
			return outputColor;
			break;
		case 22: // replace
			if(tempMatt * exeMatt > 0.0001f)
				return (float4)(overlay.xyz, overlay.w);
			 else 
				return bgCol;
		default:
			//bgCol = (float4)(bgCol.xyz*bgCol.w, bgCol.w);
			outputColor = overlay;		
			outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
			outputColor.w = tempOpacity + invTemOpacity* bgCol.w;
            float fOpacity = opacity * tempMatt;
			outputColor.xyz = outputColor.xyz*fOpacity + invTemOpacity*bgCol.xyz;
			outputColor.xyz = clamp( outputColor.xyz, (float3)(0.0f), (float3)(1.0f) );
	
			return outputColor; 
	}
	
	outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
	//outputColor.w = overlay.w + (1.0f - overlay.w)* bgCol.w;
	outputColor.w = tempOpacity + invTemOpacity* bgCol.w;
    float fOpacity = opacity * tempMatt;
	outputColor.xyz = outputColor.xyz*tempOpacity + invTemOpacity*bgCol.xyz;
	//outputColor.xyz = outputColor.xyz*fOpacity + invTemOpacity*bgCol.xyz;
	outputColor.xyz = clamp( outputColor.xyz, (float3)(0.0f), (float3)(1.0f) );
	
	return outputColor; 
	
}
__kernel void MAIN(__read_only image2d_t overlay, __read_only image2d_t background, __write_only image2d_t dest_data,  __global FilterParam* param, int blendingMode, float kRender_Alpha, int ovlAlphaPreMul,int ovlResize,int samperType)
{
	//ovlResize  overlay need resize 0--no resize 1--resize   samperType sampler type default nearest
	const sampler_t samplerBG = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST; 
	const sampler_t samplerOVL = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_NEAREST;
	const sampler_t samplerOVLN = CLK_NORMALIZED_COORDS_FALSE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_NEAREST;
	
	const float eps = 1.0e-10f;
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));

	int overlayWidth = param->width[0];
	int overlayHeight = param->height[0];
	int backgroundWidth = param->width[1];
	int backgroundHeight = param->height[1];


	float2 resolution = (float2)((float)(param->width[1]),(float)(param->height[1]));
	float2 overlayRes = (float2)((float)(param->width[0]),(float)(param->height[0]));
	
	float2 fragCoord = (float2)(coordinate.x, coordinate.y)+0.5f;
	float2 tc = fragCoord/resolution.xy;
	float2 tempTc = tc;
	float2 tempTcExe = tc;  
	float2 onePixel = (float2)(1.0f)/resolution.xy;
	
	float4 bgCol = read_imagef(background, samplerBG, tempTc);

	
	float4 ovlCol; 

	// when  theta is zero, using resize to avoid the one pixel tolerance at the edge.
	int pixelResX = (int)(param->resultROI[0] * resolution.x + 0.5f);
	int pixelResY = (int)(param->resultROI[1] * resolution.y + 0.5f);
	int pixelResWidth = (int)(param->resultROI[2] * resolution.x + 0.5f);
	int pixelResHeight = (int)(param->resultROI[3] * resolution.y + 0.5f);
	//no resize 
	int pixelOvlX = 0;
	int pixelOvlY = 0;
	int pixelOvlWidth = 0;
	int pixelOvlHeight = 0;
	if(ovlResize == 0){
		pixelOvlX = (int)(param->origROI[0] * overlayRes.x + 0.5f);
		pixelOvlY = (int)(param->origROI[1] * overlayRes.y + 0.5f);
		}
	else {
		//resize from original, ignore roi.x roi.y
		pixelOvlX=0;
		pixelOvlY=0;
	}
		pixelOvlWidth = (int)(param->origROI[2] * overlayRes.x + 0.5f);
		pixelOvlHeight = (int)(param->origROI[3] * overlayRes.y + 0.5f);
	
	
	if(pixelResWidth <= 2 || pixelResHeight <= 2)
	{
		write_imagef(dest_data, coordinate, bgCol);
		return;
	}
	//
	float2 resizeCor = (float2)( (pixelOvlWidth )/(float)(pixelResWidth ) *(fragCoord.x - pixelResX) + pixelOvlX,
							   (pixelOvlHeight )/(float)(pixelResHeight ) *(fragCoord.y - pixelResY) + pixelOvlY
							  );
	
	float matt  = step((float)pixelOvlX,resizeCor.x)*step(resizeCor.x, (float)(pixelOvlX + pixelOvlWidth))*step((float)(pixelOvlY),resizeCor.y)*step(resizeCor.y, (float)(pixelOvlY + pixelOvlHeight) );	
	ovlCol = read_imagef(overlay, samplerOVLN, resizeCor);
	
	float tempMatt = matt;
	matt = matt*ovlCol.w;
	
	float4 outputCol = blending( bgCol, ovlCol, matt, tempMatt, 1.0f, blendingMode, kRender_Alpha, ovlAlphaPreMul);
	write_imagef(dest_data, coordinate, outputCol);
}