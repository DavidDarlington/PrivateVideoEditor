
float2 rotateFunc(float2 uv, float2 center, float theta)
{
	float2 temp;
	temp.x = dot((float2)(cos(theta), -sin(theta)), uv - center);
	temp.y = dot((float2)(sin(theta), cos(theta)), uv - center);
	return (temp+center);
}
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
			bgCol = (float4)(bgCol.xyz*bgCol.w, bgCol.w);
			outputColor = overlay;
			if(ovlAlphaPreMul == 0)
			{
				tempOpacity = opacity * matt * exeMatt;
			}else{
				tempOpacity = opacity * tempMatt * exeMatt;
			}
			
			outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
			outputColor.w = overlay.w + (1.0f - overlay.w)* bgCol.w;
			outputColor.xyz = outputColor.xyz*tempOpacity + invTemOpacity*bgCol.xyz;
			//outputColor.xyz = clamp( outputColor.xyz/outputColor.w, (float3)(0.0f), (float3)(1.0f) );
			outputColor.xyz = clamp( outputColor.xyz, (float3)(0.0f), (float3)(1.0f) );
			return outputColor; 
	
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
			bgCol = (float4)(bgCol.xyz*bgCol.w, bgCol.w);
			outputColor = overlay;
			
			if(ovlAlphaPreMul == 0)
			{
				tempOpacity = opacity * matt * exeMatt;
			}else{
				tempOpacity = opacity * tempMatt * exeMatt;
			}
			outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
			outputColor.w = overlay.w + (1.0f - overlay.w)* bgCol.w;
			outputColor.xyz = outputColor.xyz*tempOpacity + invTemOpacity*bgCol.xyz;
			outputColor.xyz = clamp( outputColor.xyz / outputColor.w, (float3)(0.0f), (float3)(1.0f) );
	
			return outputColor; 
	}
	
	outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
	outputColor.w = overlay.w + (1.0f - overlay.w)* bgCol.w;
	outputColor.xyz = outputColor.xyz*tempOpacity + invTemOpacity*bgCol.xyz;
	outputColor.xyz = clamp( outputColor.xyz, (float3)(0.0f), (float3)(1.0f) );
	
	return outputColor; 
	
}


__kernel void MAIN(__read_only image2d_t overlay, __read_only image2d_t background, __write_only image2d_t dest_data,  __global FilterParam* param,  float theta, int mode, int blendingMode, float kRender_Alpha, int ovlAlphaPreMul, int inPlace)
{
	const sampler_t samplerBG = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST; 
	const sampler_t samplerOVL = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_LINEAR;
	const sampler_t samplerOVLN = CLK_NORMALIZED_COORDS_FALSE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_LINEAR;
	
	const float eps = 1.0e-10f;
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));

	float2 resolution = (float2)((float)(param->width[1]),(float)(param->height[1]));
	float2 overlayRes = (float2)((float)(param->width[0]),(float)(param->height[0]));
	
	float2 fragCoord = (float2)(coordinate.x, coordinate.y)+0.5f;
	float2 tc = fragCoord/resolution.xy;
	float2 tempTc = tc;
	float2 tempTcExe = tc;  
	float2 onePixel = (float2)(1.0f)/resolution.xy;
	
	float roiX0 = param->origROI[0] - onePixel.x;
	float roiY0 = param->origROI[1] - onePixel.y;
	float roiX1 = param->origROI[2] + param->origROI[0] + onePixel.x;
	float roiY1 = param->origROI[3] + param->origROI[1] + onePixel.y;
	
	float resultX0 = param->resultROI[0] - onePixel.x;
	float resultY0 = param->resultROI[1] - onePixel.y;
	float resultX1 = param->resultROI[2] + param->resultROI[0] + onePixel.x;
	float resultY1 = param->resultROI[3] + param->resultROI[1] + onePixel.y;
/*
	float roiX0 = 0.0f;
	float roiY0 = 0.0f;
	float roiX1 = 1.0f;
	float roiY1 = 1.0f;
	
	float resultX0 = 0.0f;
	float resultY0 = 0.0f;
	float resultX1 = 0.7f;
	float resultY1 = 0.7f;
	theta = 30.0f;
	*/
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
	tc.x = ( tc.x - center.x )/(scalFactorX) + center.x ;
	tc.y = ( tc.y - center.y )/(scalFactorY) + center.y;

	float smoothGap = 2.0f/resolution.x; 
	float gap = fabs(sin(_theta * 2.0f)*3.0f);
	float pixelX = gap/resolution.x;
	float pixelY = gap/resolution.y;
	//float matt = (smoothstep(roiX0, roiX0 + pixelX,tc.x) - smoothstep(roiX1 - pixelX,roiX1, tc.x))* ( smoothstep(roiY0, roiY0 + pixelY,tc.y)-smoothstep(roiY1 - pixelY, roiY1, tc.y));
	
	float matt = step(roiX0,tc.x)*step(tc.x, roiX1 )*step(roiY0,tc.y)*step(tc.y, roiY1);
	
	float4 bgCol = read_imagef(background, samplerBG, tempTc);
	
	float4 ovlCol; 
	
	float2 RenderMode_Fill = (float2)(0.0f);
	
	float pixelOvlWidth = (roiX1-roiX0)*overlayRes.x;
	float pixelOvlHeight = (roiY1-roiY0)*overlayRes.y;
	float pixelResWidth = (resultX1 - resultX0)*resolution.x;
	float pixelResHeight = (resultY1 - resultY0)*resolution.y;
		
	float origRatio = pixelOvlHeight/pixelOvlWidth; 
	float resRatio = pixelResHeight/pixelResWidth; 
	float roiOrigRatio =  (roiY1-roiY0)/(roiX1-roiX0);
	if(mode == 0)
	{
		if(origRatio > resRatio)
		{
			scalFactorX = ((resultY1 - resultY0)/roiOrigRatio)*( (overlayRes.x/overlayRes.y) /(resolution.x/resolution.y)  )/(roiX1 - roiX0);
		}
		else 
		{
			scalFactorY =  ((resultX1 - resultX0)*roiOrigRatio)* ( (overlayRes.y/overlayRes.x) /(resolution.y/resolution.x)  )  /(roiY1 - roiY0);
		}
		RenderMode_Fill = (float2)( ( renderModeDirectCor.x - center.x )/(scalFactorX) + center.x,  ( renderModeDirectCor.y - center.y )/(scalFactorY) + center.y);
		ovlCol = read_imagef(overlay, samplerOVL, RenderMode_Fill);
		matt = step(roiX0,RenderMode_Fill.x)*step(RenderMode_Fill.x, roiX1 + onePixel.x)*step(roiY0,RenderMode_Fill.y)*step(RenderMode_Fill.y, roiY1 + onePixel.y);
		ovlCol = ovlCol*matt;
		
	}else if(mode == 1)
	{
			
		if(origRatio > resRatio)
		{
			scalFactorY =  ((resultX1 - resultX0)*roiOrigRatio)* ( (overlayRes.y/overlayRes.x) /(resolution.y/resolution.x)  )  /(roiY1 - roiY0);
		}
		else 
		{
			scalFactorX = ((resultY1 - resultY0)/roiOrigRatio)*( (overlayRes.x/overlayRes.y) /(resolution.x/resolution.y)  )/(roiX1 - roiX0);
		}
		RenderMode_Fill = (float2)( ( renderModeDirectCor.x - center.x )/(scalFactorX+eps) + center.x,  ( renderModeDirectCor.y - center.y )/(scalFactorY+eps) + center.y);
		ovlCol = read_imagef(overlay, samplerOVL, RenderMode_Fill);
		center = (float2)((resultX1-resultX0)*0.5f + resultX0, (resultY1-resultY0)*0.5f + resultY0);
		tempTc = rotateFunc(tempTc*resolution.xy,resolution.xy*center,_theta)/resolution.xy;
		float matt1 = step(resultX0,tempTc.x)*step(tempTc.x, resultX1 + onePixel.x )*step(resultY0,tempTc.y)*step(tempTc.y, resultY1 + onePixel.y);
		matt = matt*matt1;
		ovlCol = ovlCol*matt1;
	}else
	{
		if(fabs(theta) < 1.0e-5f)
		{
			// when  theta is zero, using resize to avoid the one pixel tolerance at the edge.
			int pixelResX = (int)(param->resultROI[0] * resolution.x + 0.5f);
			int pixelResY = (int)(param->resultROI[1] * resolution.y + 0.5f);
			int pixelResWidth = (int)(param->resultROI[2] * resolution.x + 0.5f);
			int pixelResHeight = (int)(param->resultROI[3] * resolution.y + 0.5f);
			
			int pixelOvlX = (int)(param->origROI[0] * overlayRes.x + 0.5f);
			int pixelOvlY = (int)(param->origROI[1] * overlayRes.y + 0.5f);
			int pixelOvlWidth = (int)(param->origROI[2] * overlayRes.x + 0.5f);
			int pixelOvlHeight = (int)(param->origROI[3] * overlayRes.y + 0.5f);
			
			float2 resizeCor = (float2)( (pixelOvlWidth - 1)/(float)(pixelResWidth - 1) *(fragCoord.x - pixelResX) + pixelOvlX,
									   (pixelOvlHeight - 1)/(float)(pixelResHeight - 1) *(fragCoord.y - pixelResY) + pixelOvlY
									  );
			
			matt = step((float)pixelOvlX,resizeCor.x)*step(resizeCor.x, (float)(pixelOvlX + pixelOvlWidth))*step((float)(pixelOvlY),resizeCor.y)*step(resizeCor.y, (float)(pixelOvlY + pixelOvlHeight) );	
			ovlCol = read_imagef(overlay, samplerOVLN, (int2)(resizeCor.x, resizeCor.y));
			
		}else{
			ovlCol = read_imagef(overlay, samplerOVL, tc);
		}
	}
	
	float exeMatt = 1.0f;
	float tempMatt = matt;
	matt = matt*ovlCol.w*exeMatt;
	
	float4 outputCol = blending( bgCol, ovlCol, matt, tempMatt, exeMatt, blendingMode, kRender_Alpha, ovlAlphaPreMul);
	write_imagef(dest_data, coordinate, outputCol);
}