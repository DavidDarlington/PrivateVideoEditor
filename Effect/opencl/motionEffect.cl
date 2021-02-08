/*************************************************
author: RuanShengQiang
date: 2017/4/18
**************************************************/

#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw

#define motionBlur 0.5f

#define rotateblur 0.5f

/*
#define  release
#ifdef debug
float iGlobalTime = PREFIX(global_time);// iGlobalTime is the process of the transition, range [0.0,1.0]
vec2 curPos = vec2(0.5,sin(iGlobalTime*6.0));// current position [(0.0,0.0),(1.0,1.0)]
vec2 nextPos = vec2(0.5,sin(iGlobalTime*5.9));//next position range [(0.0,0.0),(1.0,1.0)]
float alpha = 100.0f;//range [0,100]
float curRotate = sin(iGlobalTime*5.9)*360.0;//degree
float nextRotate = sin(iGlobalTime*5.0)*360.0;
vec2 curScale = vec2(sin(iGlobalTime*6.0)); //range [0,1]
vec2 nextScale = vec2(sin(iGlobalTime*5.9));//range [0,1]
#else  
vec2 curPos = PREFIX(curPos);// current position [(0.0,0.0),(1.0,1.0)]
vec2 nextPos  = PREFIX(nextPos);//next position range [(0.0,0.0),(1.0,1.0)]
float alpha = PREFIX(alpha);//range [0,100]
float curRotate = PREFIX(curRotate);//degree
float nextRotate = PREFIX(nextRotate);
vec2 curScale = PREFIX(curScale) ; //range [0,1]
vec2 nextScale = PREFIX(nextScale);//range [0,1]
#endif 
*/
const sampler_t Sampler = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR; 

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

float4 blending(float4 backGround, float4 ovl, float matt, float tempMatt, float exeMatt, int blendingMode, float opacity)
{
	float4 outputColor = (float4)(0.0f);
	float4 overlay = ovl * tempMatt * exeMatt; 
	float4 bgCol = backGround;
	float tempOpacity = opacity * matt * exeMatt;
	float invTemOpacity = 1.0f - tempOpacity;
	switch(blendingMode)
	{
		case 0:// normal,
			//outputColor.xyz = (overlayNor2 + (1.0f - matt)*bgCol.w*bgCol.xyz)/bgCol.w;
			//outputColor.xyz = (overlayNor2 + (1.0f - matt)*bgCol.xyz);
			outputColor = overlay;
			//tempOpacity = opacity * tempMatt * exeMatt;
			break;
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
		case 6: //screen
			outputColor =  1.0f - (1.0f-bgCol)*(1.0f-overlay);
			break;
		case 7: //color dodge
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
		case 8://Linear Dodge
			outputColor = overlay + bgCol;
			break;
		case 9: //overlay // (Target > 0.5f) * (1 - (1-2*(Target-0.5)) * (1-Blend)) + (Target <= 0.5f) * ((2*Target) * Blend)
		{
			float3 a = (float3)( (bgCol.x > 0.5f?1.0f:0.0f), (bgCol.y > 0.5f?1.0f:0.0f), (bgCol.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)((bgCol.x <=  0.5f?1.0f:0.0f), (bgCol.y <=  0.5f?1.0f:0.0f), (bgCol.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a * (1.0f - (1.0f-2.0f*(bgCol.xyz-0.5f)) * (1.0f-overlay.xyz)) + b * ((2.0f*bgCol.xyz) * overlay.xyz);
		}
			break;
		case 10: //Soft Light // 
		{
			float3 a = (float3)( (overlay.x > 0.5f?1.0f:0.0f), (overlay.y > 0.5f?1.0f:0.0f),  (overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (overlay.x <=  0.5f?1.0f:0.0f), (overlay.y <=  0.5f?1.0f:0.0f),  (overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a * (2.0f*bgCol.xyz*(1.0f - overlay.xyz) + sqrt(bgCol.xyz)*(2.0f*overlay.xyz - 1.0f)) \
							+ b * (2.0f*bgCol.xyz*overlay.xyz + bgCol.xyz*bgCol.xyz*(1.0f - 2.0f*overlay.xyz));
		}
			break;	
		case 11://Hard Light //(Blend > 0.5) * (1 - (1-Target) * (1-2*(Blend-0.5))) + (Blend <= 0.5) * (Target * (2*Blend))
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a * (1.0f - (1.0f-bgCol.xyz) * (1.0f-2.0f*(overlay.xyz-0.5f))) + b * (bgCol.xyz * (2.0f*overlay.xyz));

			break;
		}		
		case 12://vivid light //// (Blend > 0.5) * (1 - (1-Target) / (2*(Blend-0.5))) + (Blend <= 0.5) * (Target / (1-2*Blend))
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			
			outputColor.xyz = b * colorBurn(bgCol,(2.0f*overlay)).xyz + a * colorDodge(bgCol, (2.0f*(overlay - 0.5f))).xyz;
			
		}
			break;
		case 13:// Linear Light//  (Blend > 0.5) * (Target + 2*(Blend-0.5)) + (Blend <= 0.5) * (Target + 2*Blend - 1)
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a* (bgCol.xyz + 2.0f*(overlay.xyz - 0.5f)) + b* (bgCol.xyz + 2.0f*overlay.xyz - 1.0f);
		}
			break;
			
		case 14: //PIN Light// (Blend > 0.5) * (max(Target,2*(Blend-0.5))) + (Blend <= 0.5) * (min(Target,2*Blend)))
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a* (max(bgCol.xyz,2.0f*(overlay.xyz-0.5f))) + b * (min(bgCol.xyz, 2.0f*overlay.xyz));
		}
			break;
		case 15: // hardmix  (VividLight(A,B) < 128) ? 0 : 255
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = b * colorBurnForHardMix(bgCol,(2.0f*overlay)).xyz + a * colorDodgeForHardMix(bgCol, (2.0f*(overlay - 0.5f))).xyz;
			outputColor.xyz = (float3)( (float)(outputColor.x >= 0.5f?1.0f:0.0f), (float)(outputColor.y >= 0.5f?1.0f:0.0f),(float)(outputColor.z >= 0.5f?1.0f:0.0f));
			//outputColor.xyz = (float3)( (float)(overlay.x + bgCol.x >= 1.0f?1.0f:0.0f), (float)(overlay.y + bgCol.y >= 1.0f?1.0f:0.0f),(float)(overlay.z + bgCol.z >= 1.0f?1.0f:0.0f));
		}
			break;
			
		case 16://Difference
			outputColor = fabs( overlay - bgCol );
			break;
		case 17://exclusion // 0.5 - 2*(Target-0.5)*(Blend-0.5)
			outputColor = 0.5f - 2.0f*(overlay-0.5f)*(bgCol-0.5f);
			break;
		case 18://Lighten // max(Target,Blend)   
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
		default:
			outputColor = overlay;
			tempOpacity = opacity * tempMatt * exeMatt;
			break;	
	}
	
	outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
	outputColor.w = tempOpacity + invTemOpacity* bgCol.w;
    float fOpacity = opacity * tempMatt * exeMatt;
    outputColor.xyz = outputColor.xyz *fOpacity+bgCol.xyz*invTemOpacity;
    outputColor.xyz = clamp( outputColor.xyz, (float3)(0.0f), (float3)(1.0f) );
	return outputColor;
}

static vec2 scaleFunc(vec2 uv, vec2 scale,vec2 center)
{

	return (uv - center)/(scale) + center ;

}
static vec2 rotateFunc(vec2 uv, vec2 center, float theta, vec2 iResolution)
{
	vec2 temp;
	vec2 xy = uv*iResolution.xy;
	vec2 unNormalCenter = center*iResolution.xy;
	
	temp.x = dot((vec2)(cos(theta), -sin(theta)), xy - unNormalCenter);
	temp.y = dot((vec2)(sin(theta), cos(theta)), xy - unNormalCenter);
	return (temp+unNormalCenter)/iResolution.xy;
}

static void blur(vec2 uv,
				vec2 origUv,
				int i, 
				int Samples,
				vec2 dir,
				float ratio,
				vec2 iResolution,
				float alpha,
				__read_only image2d_t background,
				__read_only image2d_t overlay,
                vec4 roi,
				vec4* color)
{
	vec2 temp = uv + (float)(i) / (float)(Samples)*dir;
    float grid = (step(roi.x, temp.x)-step(roi.z,temp.x))*(step(roi.y, temp.y)-step(roi.w, temp.y));
	//float grid = (step(temp.x,1.0f)-step(temp.x,0.0f))*(step(temp.y,1.0f)-step(temp.y,0.0f));
	//vec4 bgCol = read_imagef(background, Sampler, (float2)(origUv.x, origUv.y ));
    
	vec4 fgCol = read_imagef(overlay, Sampler, (float2)(temp.x, temp.y))*grid;
	
	*color += fgCol;//mix( bgCol, fgCol,grid*fgCol.w*alpha/100.0f)*ratio;
}

float2 _rotate(float2 uv, float2 center, float theta)
{
	float2 temp;
	temp.x = dot((float2)(cos(theta), -sin(theta)), uv - center);
	temp.y = dot((float2)(sin(theta), cos(theta)), uv - center);
	return (temp+center);
}

__kernel void MAIN(__read_only image2d_t overlay, __read_only image2d_t background, __write_only image2d_t dest_data,  __global FilterParam* param, 
					float curPosX,
					float curPosY,
					float nextPosX, 
					float nextPosY,
					float alpha,
					float curRotate,
					float nextRotate,
					float curScaleX,
					float curScaleY,
					float nextScaleX,
					float nextScaleY,
					float visX0,
					float visY0,
					float visWidth ,
					float visHeight,
					float visTheta,
					int blendingMode,
					float kRender_Alpha
					)
{
	
					
					
	vec2 curPos = (vec2)(curPosX, curPosY);// current position [(0.0,0.0),(1.0,1.0)]
	vec2 nextPos  = (vec2)(nextPosX, nextPosY);//next position range [(0.0,0.0),(1.0,1.0)]
	vec2 curScale = (vec2)(curScaleX, curScaleY) ; //range [0,1]
	vec2 nextScale = (vec2)(nextScaleX, nextScaleY);//range [0,1]
	int Samples = 8; //multiple of 2
	vec4 color = (vec4)(0.0f);
	
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));

	float2 resolution = (float2)((float)(param->width[1]),(float)(param->height[1]));
	float2 overlayRes = (float2)((float)(param->width[0]),(float)(param->height[0]));

    
 	float x0 = param->origROI[0];
	float y0 = param->origROI[1];
    float roi_w=param->origROI[2];
    float roi_h=param->origROI[3];
	float x1 = x0 + roi_w;
	float y1 = y0 + roi_h;
    float4 ovlRoi=(float4)(x0,y0,roi_w,roi_h);

    curScale = curScale/(float2)(roi_w, roi_h);
	nextScale = nextScale/(float2)(roi_w, roi_h);
    float2 roiCenter = (float2)(x0 + (x1 - x0)/2.0f, y0 + (y1 - y0)/2.0f);
	
	float2 fragCoord = (float2)(get_global_id(0), get_global_id(1))+0.5f;
	float2 uv = fragCoord/resolution.xy;
	float2 origUv = uv;
	float2 center = roiCenter;
	vec2 dir = motionBlur*normalize((nextPos - curPos+0.0001f)*resolution.xy)*length(nextPos - curPos+0.00001f)* (fragCoord.xy-resolution.xy/2.0f)/resolution.xy;
	
    const float half_PI = 90.0f;
    float mod_curRotate = fmod(curRotate,half_PI);
    float alias = 0.0f;
    if((fabs(mod_curRotate))>1.0e-5f){
        alias = 1.0f;
    }
    
	curRotate = - curRotate;
	nextRotate = - nextRotate;
    
	float processRota = curRotate*0.01745329f;
	float dirRota = -(180.0f-curRotate)*0.01745329f;
	uv = uv +center- curPos;

	uv = rotateFunc(uv,center,processRota, resolution);
	dir = rotateFunc(dir, (vec2)(0.0f), dirRota,resolution);
	
	uv = scaleFunc(uv,curScale,center);//scaling
	vec2 scaleDir= dir/(length(curScale)+0.00001f);

    float radialBlurStrength = length(nextScale - curScale);
    float radialBlur = 1.5f;
    // if(radialBlurStrength>0.01f){
    //     radialBlur = 0.5f;
    // }
    if(radialBlurStrength<0.001f){
        radialBlur = 5.0f;   
    }
    // if(radialBlurStrength>0.0001f){
    //     radialBlur = 50.0f;
    // }
    // if(radialBlurStrength>0.00001f){
    //     radialBlur = 300.0f;
    // }
	vec2 radialDir = radialBlur*(uv - center)*radialBlurStrength;
	float detaRotate = (nextRotate - curRotate);
	vec2 RotateDir = rotateblur*rotateFunc(normalize(uv - center), (vec2)(0.0f), - 1.570796f, resolution) * length(uv - center)*detaRotate*0.01745329f;
	
	vec2 totalDir = radialDir+ RotateDir + dir;
	
	float count = 0.0f;
	float grid = (step(uv.x,1.0f)-step(uv.x,0.0f))*(step(uv.y,1.0f)-step(uv.y,0.0f));
    float4 roi = (float4)(x0,y0,x1,y1);
	for (int i = 0; i < Samples; i += 2) //operating at 2 samples for better performance
	{	
	
		blur(uv,origUv, i, Samples, totalDir, 1.0f, resolution, alpha ,background, overlay,roi, &color);
		blur(uv,origUv, i+1, Samples, totalDir, 1.0f, resolution, alpha ,background, overlay,roi, &color);
	}
	//vec4 bgCol = read_imagef(background, Sampler, (float2)(origUv.x, origUv.y));
    vec4 bgCol = (vec4)(0.0f);
	vec4 ovlCol = (vec4)(color/(float)(Samples));

    float pixelX = 2.0f/resolution.x;
    float pixelY = 2.0f/resolution.y;
    float featherX = smoothstep(roi.x, roi.x + pixelX, uv.x) * (1.0f - smoothstep(roi.z - pixelX, roi.z, uv.x));
    float featherY = smoothstep(roi.y, roi.y + pixelY, uv.y) * (1.0f - smoothstep(roi.w - pixelY, roi.w, uv.y));
    float featherMatt = featherX*featherY;   
    ovlCol*=(step(0.5f,alias)*(featherMatt - 1.0f)+1.0f);
	float2 tempTcExe = origUv; 
	if(fabs(visTheta)>1.0e-10f)
	{
		vec2 center = (vec2)(0.0f);
		center.x = visX0 + (visWidth)/2.0f;
		center.y = visY0 + (visHeight)/2.0f;
		tempTcExe = _rotate(tempTcExe*resolution.xy,resolution.xy*center,-radians(visTheta))/resolution.xy;
	}
	
	float tempMatt = step(visX0,tempTcExe.x)*step(tempTcExe.x, visX0+visWidth)*step(visY0,tempTcExe.y)*step(tempTcExe.y, visY0+visHeight);
	
	float4 outputCol = blending( bgCol, ovlCol, ovlCol.w, tempMatt, 1.0f, 0, kRender_Alpha*alpha/100.0f);
	
	write_imagef(dest_data, (int2)(coordinate.x, coordinate.y), outputCol);
	
}