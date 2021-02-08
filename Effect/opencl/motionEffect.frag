//#define GL_NEED_MIPMAPS
#ifdef GL_ES
precision highp float;
#endif

#define rgb xyz
#define rgba xyzw

#define motionBlur 0.5
#define rotateblur 0.5

#define  release
#ifdef debug
float iGlobalTime = PREFIX(global_time);// iGlobalTime is the process of the transition, range [0.0,1.0]
vec2 curPos = vec2(0.5,sin(iGlobalTime*6.0));// current position [(0.0,0.0),(1.0,1.0)]
float curPosX = curPos.x; 
float curPosY = curPos.y; 
vec2 nextPos = vec2(0.5,sin(iGlobalTime*5.9));//next position range [(0.0,0.0),(1.0,1.0)]
float nextPosX = nextPos.x;
float nextPosY = nextPos.y;

float alpha = 100.0;//range [0,100]

float curRotate = sin(iGlobalTime*5.9)*360.0;//degree
float nextRotate = sin(iGlobalTime*5.0)*360.0;

float curScaleX = (sin(iGlobalTime*6.0));
float curScaleY = (sin(iGlobalTime*6.0));
float nextScaleX = (sin(iGlobalTime*5.9));//range [0,1]
float nextScaleY = (sin(iGlobalTime*5.9));//range [0,1]

float visX0 = 0.0;//PREFIX(visX0);
float visY0 = 0.0;//PREFIX(visY0);
float visWidth = 1.0;//PREFIX(visWidth);
float visHeight = 1.0;//PREFIX(visHeight);
float visTheta = 0.0;//PREFIX(visTheta);
int blendingMode = 0;//PREFIX(blendingMode);
float kRender_Alpha = 1.0;//PREFIX(kRender_Alpha);

#else  

float curPosX = PREFIX(curPosX);
float curPosY = PREFIX(curPosY);
float nextPosX = PREFIX(nextPosX);
float nextPosY = PREFIX(nextPosY);
float alpha = PREFIX(alpha);
float curRotate = PREFIX(curRotate);
float nextRotate = PREFIX(nextRotate);
float curScaleX = PREFIX(curScaleX);
float curScaleY = PREFIX(curScaleY);
float nextScaleX = PREFIX(nextScaleX);
float nextScaleY = PREFIX(nextScaleY);
float visX0 = PREFIX(visX0);
float visY0 = PREFIX(visY0);
float visWidth = PREFIX(visWidth);
float visHeight = PREFIX(visHeight);
float visTheta = PREFIX(visTheta);
int blendingMode = PREFIX(blendingMode);
float kRender_Alpha = PREFIX(kRender_Alpha);

#endif 


//designed by RuanShengQiang. 
vec4 colorDodge(vec4 bgCol, vec4 overlay )
{
	vec4 outputColor = bgCol/(1.0 - overlay);
	
	if(overlay.x >0.99999)
		outputColor.x = 1.0;
	if(overlay.y >0.99999)
		outputColor.y = 1.0;
	if(overlay.z >0.99999)
		outputColor.z = 1.0;
	
	return outputColor;
}

vec4 colorBurn(vec4 bgCol, vec4 overlay )
{
	
	vec4 outputColor = 1.0 - (1.0-bgCol) / overlay; 
			
	if(overlay.x < 0.000001)
		outputColor.x = 0.0;
	if(overlay.y < 0.000001)
		outputColor.y = 0.0;
	if(overlay.z < 0.000001)
		outputColor.z = 0.0;
	return outputColor;
}

vec4 colorDodgeForHardMix(vec4 bgCol, vec4 overlay )
{
	vec4 outputColor = bgCol/(1.0 - overlay);
	
	if(bgCol.x < 0.000001)
		outputColor.x = 0.0;
	if(bgCol.y < 0.000001)
		outputColor.y = 0.0;
	if(bgCol.z < 0.000001)
		outputColor.z = 0.0;
	
	return outputColor;
}

vec4 colorBurnForHardMix(vec4 bgCol, vec4 overlay )
{
	
	vec4 outputColor = 1.0 - (1.0-bgCol) / overlay; 
			
	if(bgCol.x > 0.9999999)
		outputColor.x = 1.0;
	if(bgCol.y > 0.9999999)
		outputColor.y = 1.0;
	if(bgCol.z > 0.9999999)
		outputColor.z = 1.0;
	return outputColor;
}

//tempMatt: matt without alpha
//matt: matt with altph.

vec4 blending(vec4 backGround, vec4 ovl, float matt, float tempMatt, float exeMatt, int blendingMode, float opacity)
{
	vec4 outputColor = vec4(0.0);
	vec4 overlay = ovl * tempMatt * exeMatt; 
	vec4 bgCol = backGround;
	float tempOpacity = opacity * matt * exeMatt;
	float invTemOpacity = 1.0 - tempOpacity;
	
	// glsl cannot use swith ~~
	if(0 == blendingMode)
	{
		// normal,
			//outputColor.xyz = (overlayNor2 + (1.0f - matt)*bgCol.a*bgCol.xyz)/bgCol.a;
			//outputColor.xyz = (overlayNor2 + (1.0f - matt)*bgCol.xyz);
			outputColor = overlay;
			//tempOpacity = opacity * tempMatt * exeMatt;
	}else if(1 == blendingMode)
	{
		// Darken
			outputColor = min(overlay,bgCol);
	}else if(2 == blendingMode)
	{//multiply
			outputColor = bgCol * overlay; 
	}else if(3 == blendingMode)
	 //  color burn // 1 - (1-Target) / Blend
	{
			vec4 temp = (1.0-bgCol) / overlay; 
			if(bgCol.x > 0.99999)
				temp.x = 0.0;
			if(bgCol.y > 0.99999)
				temp.y = 0.0;
			if(bgCol.z > 0.99999)
				temp.z = 0.0;
			outputColor = 1.0 - temp ;
	}else if(4 == blendingMode)
	{// Linear burn
			outputColor = overlay + bgCol -1.0;
	}else if(6 == blendingMode)
	{
		//screen
			outputColor =  1.0 - (1.0-bgCol)*(1.0-overlay);
	}else if(7 == blendingMode)
	{	//
			outputColor = bgCol/(1.0 - overlay);
		
			 if (bgCol.x < 0.00001)
				outputColor.x = 0.0;
			if (bgCol.y < 0.00001)
				outputColor.y = 0.0;
			if (bgCol.z < 0.00001)
				outputColor.z = 0.0;
	}else if(8 == blendingMode)
	{
			outputColor = overlay + bgCol;
	}else if(9 == blendingMode)
		 //overlay // (Target > 0.5f) * (1 - (1-2*(Target-0.5)) * (1-Blend)) + (Target <= 0.5f) * ((2*Target) * Blend)
	{
			vec3 a = vec3( (bgCol.x > 0.5?1.0:0.0), (bgCol.y > 0.5?1.0:0.0), (bgCol.z > 0.5?1.0:0.0) );
			vec3 b = vec3((bgCol.x <=  0.5?1.0:0.0), (bgCol.y <=  0.5?1.0:0.0), (bgCol.z <=  0.5?1.0:0.0) );
			outputColor.xyz = a * (1.0 - (1.0-2.0*(bgCol.xyz-0.5)) * (1.0-overlay.xyz)) + b * ((2.0*bgCol.xyz) * overlay.xyz);
	}else if(10 == blendingMode)
		//Soft Light // 
	{
		vec3 a = vec3( (overlay.x > 0.5?1.0:0.0), (overlay.y > 0.5?1.0:0.0),  (overlay.z > 0.5?1.0:0.0) );
		vec3 b = vec3( (overlay.x <=  0.5?1.0:0.0), (overlay.y <=  0.5?1.0:0.0),  (overlay.z <=  0.5?1.0:0.0) );
		outputColor.xyz = a * (2.0*bgCol.xyz*(1.0 - overlay.xyz) + sqrt(bgCol.xyz)*(2.0*overlay.xyz - 1.0)) + b * (2.0*bgCol.xyz*overlay.xyz + bgCol.xyz*bgCol.xyz*(1.0 - 2.0*overlay.xyz));
	}else if(11 == blendingMode)
		//Hard Light //(Blend > 0.5) * (1 - (1-Target) * (1-2*(Blend-0.5))) + (Blend <= 0.5) * (Target * (2*Blend))
	{
			vec3 a = vec3((overlay.x > 0.5?1.0:0.0), (overlay.y > 0.5?1.0:0.0), (overlay.z > 0.5?1.0:0.0) );
			vec3 b = vec3((overlay.x <=  0.5?1.0:0.0),(overlay.y <=  0.5?1.0:0.0), (overlay.z <=  0.5?1.0:0.0) );
			outputColor.xyz = a * (1.0 - (1.0-bgCol.xyz) * (1.0-2.0*(overlay.xyz-0.5))) + b * (bgCol.xyz * (2.0*overlay.xyz));
	}else if(12 == blendingMode)
		//vivid light //// (Blend > 0.5) * (1 - (1-Target) / (2*(Blend-0.5))) + (Blend <= 0.5) * (Target / (1-2*Blend))
	{
			vec3 a = vec3( (overlay.x > 0.5?1.0:0.0), (overlay.y > 0.5?1.0:0.0), (overlay.z > 0.5?1.0:0.0) );
			vec3 b = vec3( (overlay.x <=  0.5?1.0:0.0),(overlay.y <=  0.5?1.0:0.0),(overlay.z <=  0.5?1.0:0.0) );
			outputColor.xyz = b * colorBurn(bgCol,(2.0*overlay)).xyz + a * colorDodge(bgCol, (2.0*(overlay - 0.5))).xyz;
	}else if(13 == blendingMode)// Linear Light//  (Blend > 0.5) * (Target + 2*(Blend-0.5)) + (Blend <= 0.5) * (Target + 2*Blend - 1)
	{
			vec3 a = vec3((overlay.x > 0.5?1.0:0.0),(overlay.y > 0.5?1.0:0.0), (overlay.z > 0.5?1.0:0.0) );
			vec3 b = vec3((overlay.x <=  0.5?1.0:0.0),(overlay.y <=  0.5?1.0:0.0),(overlay.z <= 0.5?1.0:0.0) );
			outputColor.xyz = a* (bgCol.xyz + 2.0*(overlay.xyz - 0.5)) + b* (bgCol.xyz + 2.0*overlay.xyz - 1.0);
	}else if(14 == blendingMode)	
		//PIN Light// (Blend > 0.5) * (max(Target,2*(Blend-0.5))) + (Blend <= 0.5) * (min(Target,2*Blend)))
	{
			vec3 a = vec3((overlay.x > 0.5?1.0:0.0),(overlay.y > 0.5?1.0:0.0),(overlay.z > 0.5?1.0:0.0) );
			vec3 b = vec3( (overlay.x <=  0.5?1.0:0.0),(overlay.y <=  0.5?1.0:0.0),(overlay.z <=  0.5?1.0:0.0) );
			outputColor.xyz = a* (max(bgCol.xyz,2.0*(overlay.xyz-0.5))) + b * (min(bgCol.xyz, 2.0*overlay.xyz));
	}else if(15 == blendingMode)	
			// hardmix  (VividLight(A,B) < 128) ? 0 : 255
	{
			vec3 a = vec3((overlay.x > 0.5?1.0:0.0),(overlay.y > 0.5?1.0:0.0), (overlay.z > 0.5?1.0:0.0) );
			vec3 b = vec3((overlay.x <=  0.5?1.0:0.0),(overlay.y <= 0.5?1.0:0.0), (overlay.z <=  0.5?1.0:0.0) );
			outputColor.xyz = b * colorBurnForHardMix(bgCol,(2.0*overlay)).xyz + a * colorDodgeForHardMix(bgCol, (2.0*(overlay - 0.5))).xyz;
			outputColor.xyz = vec3( (outputColor.x >= 0.5?1.0:0.0), (outputColor.y >= 0.5?1.0:0.0),(outputColor.z >= 0.5?1.0:0.0));
			//outputColor.xyz = (vec3)( (float)(overlay.x + bgCol.x >= 1.0f?1.0f:0.0f), (float)(overlay.y + bgCol.y >= 1.0f?1.0f:0.0f),(float)(overlay.z + bgCol.z >= 1.0f?1.0f:0.0f));
	}else if(16 == blendingMode)	
	{//Difference
			outputColor = abs( overlay - bgCol );
	}else if(17 == blendingMode)
	{
		//exclusion // 0.5 - 2*(Target-0.5)*(Blend-0.5)
			outputColor = 0.5 - 2.0*(overlay-0.5)*(bgCol-0.5);
	}else if(18 == blendingMode)
	{//Lighten // max(Target,Blend)   
			outputColor = max(overlay,bgCol);
	}else if(19 == blendingMode)
	{ // hollow in 
			outputColor = bgCol*overlay.a;
			outputColor = clamp(outputColor,vec4(0.0), vec4(1.0));
			return outputColor;
	}else if(20 == blendingMode)
	{// hollow out 
			outputColor = bgCol*(1.0 - overlay.a);
			outputColor = clamp(outputColor,vec4(0.0), vec4(1.0));
			return outputColor;
	}else if(21 == blendingMode)
	{// backGround hollow in 
			outputColor = overlay*bgCol.a*opacity;
			outputColor = clamp(outputColor,vec4(0.0), vec4(1.0));
			return outputColor;
	}else
	{
			outputColor = overlay;
			tempOpacity = opacity * tempMatt * exeMatt;
	}	
	
	outputColor = clamp(outputColor,vec4(0.0), vec4(1.0));
	outputColor.a = tempOpacity + (invTemOpacity)* bgCol.a;
    float fOpacity = opacity * tempMatt;
    outputColor.xyz = outputColor.xyz*fOpacity + invTemOpacity*bgCol.xyz;
    outputColor = clamp(outputColor,vec4(0.0), vec4(1.0));
	return outputColor;
}

vec2 scaleFunc(vec2 uv, vec2 scale,vec2 center)
{

	return (uv - center)/(scale) + center ;

}
vec2 rotateFunc(vec2 uv, vec2 center, float theta, vec2 iResolution)
{
	vec2 temp;
	vec2 xy = uv*iResolution.xy;
	vec2 unNormalCenter = center*iResolution.xy;
	
	temp.x = dot(vec2(cos(theta), -sin(theta)), xy - unNormalCenter);
	temp.y = dot(vec2(sin(theta), cos(theta)), xy - unNormalCenter);
	return (temp+unNormalCenter)/iResolution.xy;
}

vec4 color = vec4(0.0);
float pixelX = 1.0/iResolution.x;
float pixelY = 1.0/iResolution.y;
void blur(vec2 uv,
				vec2 origUv,
				int i, 
				int Samples,
				vec2 dir,
				float ratio,
				vec2 iResolution,
				float alpha,
				vec4 roi
                )
{
	
	vec2 temp = uv + float(i) / float(Samples)*dir;
	//float grid = (step(temp.x,1.0)-step(temp.x,0.0))*(step(temp.y,1.0)-step(temp.y,0.0));
	vec2 tempUV = vec2(temp.x, temp.y);
	float grid = (step(roi.r, temp.x)-step(roi.b,temp.x))*(step(roi.g, temp.y)-step(roi.a, temp.y));    
	vec4 fgCol = INPUT1( vec2(tempUV.x, 1.0-tempUV.y) )*grid;
    
	color += fgCol;
}

vec2 _rotate(vec2 uv, vec2 center, float theta)
{
	vec2 temp;
	temp.x = dot(vec2(cos(theta), -sin(theta)), uv - center);
	temp.y = dot(vec2(sin(theta), cos(theta)), uv - center);
	return (temp+center);
}


vec4 FUNCNAME(vec2 tc) {
	float tmpAlpha = kRender_Alpha*PREFIX(alpha)/100.0;
	vec2 uv= vec2(tc.x, 1.0 - tc.y);//gl_FragCoord.xy/iResolution.xy;
	vec2 resolution = iResolution.xy;
					
	vec2 curPos = vec2(curPosX, curPosY);// current position [(0.0,0.0),(1.0,1.0)]
	vec2 nextPos  = vec2(nextPosX, nextPosY);//next position range [(0.0,0.0),(1.0,1.0)]
	vec2 curScale = vec2(curScaleX, curScaleY) ; //range [0,1]
	vec2 nextScale = vec2(nextScaleX, nextScaleY);//range [0,1]
	
	vec4 ovlRoi = PREFIX(orig_roi);
 	float x0 = ovlRoi.r;
	float y0 = ovlRoi.g;
	float x1 = ovlRoi.r + ovlRoi.b;
	float y1 = ovlRoi.g + ovlRoi.a;
	
	curScale = curScale/vec2(ovlRoi.b, ovlRoi.a);
	nextScale = nextScale/vec2(ovlRoi.b, ovlRoi.a);
	
	vec2 roiCenter = vec2(x0 + (x1 - x0)/2.0, y0 + (y1 - y0)/2.0);
		
	vec2 tempUv = uv; 
	vec2 center = roiCenter;

	vec2 dir = motionBlur*normalize((nextPos - curPos+0.0001)*resolution.xy)*length(nextPos - curPos+0.00001)*(gl_FragCoord.xy-resolution.xy/2.0)/resolution.xy;
    const float half_PI = 90.0;
    float mod_curRotate = mod(curRotate,half_PI);
    float alias = 0.0;
    if(abs(mod_curRotate) > 0.001){
        alias = 1.0;
    }
	curRotate = - curRotate;
	nextRotate = - nextRotate;

    
   

	float processRota = curRotate*0.01745329;
	float dirRota = -(180.0-curRotate)*0.01745329;
	uv = uv +center- curPos;

	uv = rotateFunc(uv,center,processRota, resolution);
	dir = rotateFunc(dir, vec2(0.0), dirRota,resolution);
	
	uv = scaleFunc(uv,curScale,center);//scaling
	
	float matt = step(x0,uv.x)*step(uv.x, x1 )*step(y0,uv.y)*step(uv.y, y1);
	
	vec2 scaleDir= dir/(length(curScale)+0.00001);

    float radialBlurStrength = length(nextScale - curScale);
    float radialBlur = 1.5;
    // if(radialBlurStrength>0.01){
    //     radialBlur = 1.5;
    // }
    if(radialBlurStrength < 0.001){
        radialBlur = 5.0;   
    }
    // else if(radialBlurStrength>0.0001){
    //     radialBlur = 10.0;
    // }
    // else if(radialBlurStrength>0.00001){
    //     radialBlur = 300.0;
    // }
    
	vec2 radialDir = radialBlur*(uv - center)*radialBlurStrength ;
	float detaRotate = (nextRotate - curRotate);
	vec2 RotateDir = rotateblur*rotateFunc(normalize(uv - center), vec2(0.0), - 1.570796, resolution) * length(uv - center)*detaRotate*0.01745329;
	vec2 totalDir = radialDir+ RotateDir + dir;
	float count = 0.0;
	int Samples = 8;
	vec4 roi = vec4(x0, y0, x1, y1);
	
	for(int i = 0; i < 8; i++)	
		blur(uv,tempUv, i, 8, totalDir, 1.0, resolution, alpha, roi);
	
	vec4 bgCol = vec4(0.0);
	vec4 ovlCol = vec4(color/float(Samples));
    float featherX = smoothstep(roi.r, roi.r + 2.0*pixelX, uv.x) * (1.0 - smoothstep(roi.b - 2.0*pixelX, roi.b, uv.x));
    float featherY = smoothstep(roi.g, roi.g + 2.0*pixelY, uv.y) * (1.0 - smoothstep(roi.a - 2.0*pixelY, roi.a, uv.y));
    float featherMatt = featherX*featherY;
    ovlCol *=(step(0.5,alias)*(featherMatt-1.0)+1.0);
   
	vec4 outputCol = blending( bgCol, ovlCol, ovlCol.a, 1.0, 1.0, 0, tmpAlpha);
	
	return outputCol;
	
}
