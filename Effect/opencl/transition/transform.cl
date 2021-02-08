#define rgb xyz
#define rgba xyzw
#define motionBlur 0.001f
#define rotateblur 0.001f
#define radialBlur 0.001f
const sampler_t samplerBG = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST; 
const sampler_t samplerOVL = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_LINEAR;
const sampler_t samplerOVLNN = CLK_NORMALIZED_COORDS_FALSE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_LINEAR;
const sampler_t samplerOVLN = CLK_NORMALIZED_COORDS_FALSE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_NEAREST;

float2 rotateFunc(float2 uv, float2 center, float theta)
{
	float2 temp;
	temp.x = dot((float2)(cos(theta), -sin(theta)), uv - center);
	temp.y = dot((float2)(sin(theta), cos(theta)), uv - center);
	return (temp+center);
}
float my_fmod(float x,float y){
	return x - y * floor (x/y);
}
float4 blur(__read_only image2d_t overlay,float2 uv,
        int i, 
        int Samples,
        float2 dir,  
        float4 roi)
{
	
	float2 temp = uv + (float)(i) / (float)(Samples)*dir;
	//float grid = (step(temp.x,1.0)-step(temp.x,0.0))*(step(temp.y,1.0)-step(temp.y,0.0));
	float2 tempUV = (float2)(temp.x, temp.y);
	float grid = (step(roi.x, temp.x)-step(roi.z,temp.x))*(step(roi.y, temp.y)-step(roi.w, temp.y));    
    float4 fgCol = read_imagef(overlay, samplerOVL, tempUV)*grid;    
    return fgCol;
}
__kernel void MAIN(__read_only image2d_t overlay, __write_only image2d_t dest_data,  __global FilterParam* param,  float theta,int samperType,
                    float curPosX,
					float curPosY,
					float nextPosX, 
					float nextPosY,
					float nextRotate,
					float curScaleX,
					float curScaleY,
					float nextScaleX,
					float nextScaleY,
                    int needMotionBlur)
{	
	const float eps = 1.0e-10f;
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));

	float2 resolution = (float2)((float)(param->width[1]),(float)(param->height[1]));
	float2 overlayRes = (float2)((float)(param->width[0]),(float)(param->height[0]));
	
	float2 fragCoord = (float2)(coordinate.x, coordinate.y)+(float2)(0.5f,0.5f);
	
	float2 tc = fragCoord/resolution.xy;
	float2 tempTc = tc;
	float curRotate = theta;
	float grid = 1.0f;
	
	float4 ovlCol=(float4)(0.0f); 
	
	float roiX0 = param->origROI[0];
	float roiY0 = param->origROI[1];
	float roiX1 = param->origROI[2] + param->origROI[0];
	float roiY1 = param->origROI[3] + param->origROI[1];
		
	float resultX0 = param->resultROI[0];
	float resultY0 = param->resultROI[1];
	float resultX1 = param->resultROI[2] + param->resultROI[0];
	float resultY1 = param->resultROI[3] + param->resultROI[1];	
	
	//samperType=0:nearest
	//samperType=1:linear
	//samperType=2:bicubic
	
	float2 roiCenter = (float2)((roiX1-roiX0)*0.5f + roiX0, (roiY1-roiY0)*0.5f + roiY0);//overlay
	float2 resultRoiCenter = (float2)((resultX1 - resultX0)*0.5f + resultX0, (resultY1 - resultY0)*0.5f + resultY0);
	float2 transl =  resultRoiCenter - roiCenter;//
	
	float scalFactorX = (resultX1 - resultX0)/(roiX1 - roiX0);
	float scalFactorY = (resultY1 - resultY0)/(roiY1 - roiY0);
	
	float _theta = -0.0174532925199433f*theta;
	tc = tc  - transl;
	float2 center = roiCenter;
	tc = rotateFunc(tc*resolution.xy,resolution.xy*center,_theta)/resolution.xy;//rotate
	float2  renderModeDirectCor = tc;
	tc.x = ( tc.x - center.x )/(scalFactorX) + center.x ;//scale
	tc.y = ( tc.y - center.y )/(scalFactorY) + center.y;//scale
	
    float2 curPos = (float2)(curPosX, curPosY);// current position [(0.0,0.0),(1.0,1.0)]
	float2 nextPos  = (float2)(nextPosX, nextPosY);//next position range [(0.0,0.0),(1.0,1.0)]
	float2 curScale = (float2)(curScaleX, curScaleY) ; //range [0,1]
	float2 nextScale = (float2)(nextScaleX, nextScaleY);//range [0,1]
    float radialBlurStrength = length(nextScale - curScale);
    float detaRotate = nextRotate - curRotate;
	float2 radialDir = radialBlur*(tc - center)*radialBlurStrength ;
    float2 RotateDir = rotateblur*rotateFunc(normalize(tc - center) * resolution.xy, (float2)(0.0f), - 1.570796f) * length(tc - center)*detaRotate*0.01745329f;
    float2 dir = motionBlur*normalize((nextPos - curPos+0.0001f)*resolution.xy)*length(nextPos - curPos+0.00001f)*(fragCoord.xy-resolution.xy/2.0f)/resolution.xy;
    float dirRota = (180.0f+theta)*0.01745329f;
    dir = rotateFunc(dir * resolution.xy, (float2)(0.0f), dirRota);
    float2 totalDir = radialDir + dir;
    int Samples = 2;
	float4 roi = (float4)(roiX0, roiY0, roiX1, roiY1);
    ovlCol = read_imagef(overlay, samplerOVL, tc);

	//matt = step(roiX0,tc.x)*step(tc.x, roiX1 )*step(roiY0,tc.y)*step(tc.y, roiY1);//roi
    grid = (step(roi.x, tc.x)-step(roi.z,tc.x))*(step(roi.y, tc.y)-step(roi.w, tc.y));    
    float srcWidth =overlayRes.x;
    float srcHeight = overlayRes.y;       
    float one_PixelX = 1.0f/srcWidth;
    float one_PixelY = 1.0f/srcHeight;
    float featherMatt = 1.0f;
    const float half_PI = 90.0f;
    float mod_curRotate = fmod(curRotate,half_PI);
    float alias = 0.0f;
    if((fabs(mod_curRotate))>1.0e-5f){
        alias = 1.0f;
    }
    if(fabs(theta) > 1.0e-5f){ 
        float featherX = smoothstep(roiX0, roiX0 + one_PixelX, tc.x) * (1.0f - smoothstep(roiX1 - one_PixelX, roiX1, tc.x));
        float featherY = smoothstep(roiY0, roiY0 + one_PixelY, tc.y) * (1.0f - smoothstep(roiY1 - one_PixelY, roiY1, tc.y));
        featherMatt = featherX*featherY;           
    }
    float4 color = (float4)(0.0f);
    if(needMotionBlur==1){
        for(int i = 0; i < Samples; i+=2)	{
		    float4 retColor = blur(overlay,tc, i, Samples, totalDir,roi);
            color+=retColor;
		    retColor = blur(overlay,tc, i+1, Samples, totalDir,roi);
            color+=retColor;
        }
	    ovlCol = (float4)(color/(float)(Samples));
        ovlCol *=featherMatt;
    }else{
        ovlCol *= grid * (step(0.5f,alias)*(featherMatt - 1.0f)+1.0f);
    }
	write_imagef(dest_data, coordinate, ovlCol);
}