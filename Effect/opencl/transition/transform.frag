#define GL_NEED_MIPMAPS
#ifdef GL_ES
precision highp float;
#endif
#define motionBlur 0.001
#define rotateblur 0.001
#define radialBlur 0.001

vec2 rotateFunc(vec2 uv, vec2 center, float theta)
{
	vec2 temp;
	temp.x = dot(vec2(cos(theta), -sin(theta)), uv - center);
	temp.y = dot(vec2(sin(theta), cos(theta)), uv - center);
	return (temp+center);
}
vec4 blur(vec2 uv,
        int i, 
        int Samples,
        vec2 dir,  
        vec4 roi)
{
	
	vec2 temp = uv + float(i) / float(Samples)*dir;
	//float grid = (step(temp.x,1.0)-step(temp.x,0.0))*(step(temp.y,1.0)-step(temp.y,0.0));
	vec2 tempUV = vec2(temp.x, temp.y);
	float grid = (step(roi.r, temp.x)-step(roi.b,temp.x))*(step(roi.g, temp.y)-step(roi.a, temp.y));    
	vec4 fgCol = INPUT( vec2(tempUV.x, 1.0-tempUV.y) )*grid;    
    return fgCol;
}
vec4 FUNCNAME(vec2 tc)
{	
	tc= vec2(tc.x, 1.0 - tc.y);//gl_FragCoord.xy/iResolution.xy;
	vec2 overlayRes = eff0_resolution;
    vec2 resolution =iResolutionOrig;
    vec4 result_roi = PREFIX(result_roi);
    vec4 origin_roi = PREFIX(orig_roi);
	float theta = PREFIX(theta);
	int samperType = PREFIX(samperType);

	float roiX0 = origin_roi.x;
	float roiY0 = origin_roi.y;
	float roiX1 = origin_roi.x + origin_roi.z;
	float roiY1 = origin_roi.y + origin_roi.w;
		
	float resultX0 = result_roi.x;
	float resultY0 = result_roi.y;
	float resultX1 = result_roi.x + result_roi.z;
	float resultY1 = result_roi.y + result_roi.w;	
	
	//samperType=0:nearest
	//samperType=1:linear
	
	vec2 roiCenter = vec2((roiX1-roiX0)*0.5 + roiX0, (roiY1-roiY0)*0.5 + roiY0);//overlay
	vec2 resultRoiCenter = vec2((resultX1 - resultX0)*0.5 + resultX0, (resultY1 - resultY0)*0.5 + resultY0);
	vec2 transl =  resultRoiCenter - roiCenter;//
	
	float scalFactorX = (resultX1 - resultX0)/(roiX1 - roiX0);
	float scalFactorY = (resultY1 - resultY0)/(roiY1 - roiY0);
	
	float _theta = -0.0174532925199433*theta;
	tc = tc  - transl;
	vec2 center = roiCenter;
	tc = rotateFunc(tc*resolution.xy,resolution.xy*center,_theta)/resolution.xy;//rotate
	vec2  renderModeDirectCor = tc;
	tc.x = ( tc.x - center.x )/(scalFactorX) + center.x ;//scale
	tc.y = ( tc.y - center.y )/(scalFactorY) + center.y;//scale



    float curRotate = theta;
    float nextRotate = PREFIX(nextRotate);
    float curPosX = PREFIX(curPosX);
    float curPosY = PREFIX(curPosY);
    float nextPosX = PREFIX(nextPosX);
    float nextPosY = PREFIX(nextPosY);
    float curScaleX = PREFIX(curScaleX);
    float curScaleY = PREFIX(curScaleY);
    float nextScaleX = PREFIX(nextScaleX);
    float nextScaleY = PREFIX(nextScaleY);
    int needMotionBlur = PREFIX(needMotionBlur);

    vec2 curPos = vec2(curPosX, curPosY);// current position [(0.0,0.0),(1.0,1.0)]
	vec2 nextPos  = vec2(nextPosX, nextPosY);//next position range [(0.0,0.0),(1.0,1.0)]
	vec2 curScale = vec2(curScaleX, curScaleY) ; //range [0,1]
	vec2 nextScale = vec2(nextScaleX, nextScaleY);//range [0,1]
    float radialBlurStrength = length(nextScale - curScale);
    float detaRotate = nextRotate - curRotate;
	vec2 radialDir = radialBlur*(tc - center)*radialBlurStrength ;
    vec2 RotateDir = rotateblur*rotateFunc(normalize(tc - center) * resolution.xy, vec2(0.0), - 0.01745329) * length(tc - center)*detaRotate*0.01745329;
    vec2 dir = motionBlur*normalize((nextPos - curPos+0.0001)*resolution.xy)*length(nextPos - curPos+0.00001)*(gl_FragCoord.xy-resolution.xy/2.0)/resolution.xy;
    float dirRota = (180.0+theta)*0.01745329;
    dir = rotateFunc(dir * resolution.xy, vec2(0.0), dirRota);
    vec2 totalDir = radialDir + dir;
	int Samples = 2;
	vec4 roi = vec4(roiX0, roiY0, roiX1, roiY1);
    vec4 ovlCol = INPUT(vec2(tc.x,1.0-tc.y));
    
    float srcWidth =overlayRes.x;
    float srcHeight = overlayRes.y;       
    float one_PixelX = 1.0/srcWidth;
    float one_PixelY = 1.0/srcHeight;
    float featherMatt = 1.0;
    const float half_PI = 90.0;
    float mod_curRotate = mod(theta,half_PI);
    float abs_curRotate = abs(mod_curRotate);
    if(abs_curRotate > 0.001){              
    
        float featherX = smoothstep(roiX0, roiX0 + one_PixelX, tc.x) * (1.0 - smoothstep(roiX1 - one_PixelX, roiX1, tc.x));
        float featherY = smoothstep(roiY0, roiY0 + one_PixelY, tc.y) * (1.0 - smoothstep(roiY1 - one_PixelY, roiY1, tc.y));
        featherMatt = featherX*featherY;           
    }
    float grid = (step(roi.r, tc.x)-step(roi.b,tc.x))*(step(roi.g, tc.y)-step(roi.a, tc.y));    
    vec4 color = vec4(0.0);
    ovlCol *= grid * featherMatt;
    if(needMotionBlur==1){
        for(int i = 0; i < Samples; i+=2)	{
		    vec4 retColor = blur(tc, i, Samples, totalDir,roi);
            color+=retColor;
            retColor = blur(tc, i+1, Samples, totalDir,roi);
            color+=retColor;
        }
	    ovlCol = vec4(color/float(Samples));
        ovlCol *=featherMatt;
    }
	return ovlCol;
	
}