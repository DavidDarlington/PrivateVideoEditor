/********************************************************************
author: RuanShengQiang
date: 2017/3/21
********************************************************************/
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE |CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;

vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, tc);
}

float4 vblur(image2d_t src_data, vec2 tc, int pixelNum,  float4 roi,float pitch)
{
	if(step(roi.x, tc.x)*step(roi.y, tc.y)*step(tc.x, roi.z)*step(tc.y, roi.w)< 0.9f)
		return INPUT(src_data,tc);
	
	int Samples = pixelNum;
    if(pixelNum==0){
        Samples=1;
    }
	
	float scale = pitch / 640.0f;
	float4 color = (float4)(0.0f);
	for (int i = -Samples; i < Samples; i += 2) //operating at 2 samples for better performance
	{
		vec2 temp1 =  tc + (vec2)( (float)(i) / pitch * scale,0.0f);
		color += INPUT(src_data, temp1);
		
		temp1 =  tc + (vec2)( (float)(i+1) / pitch * scale,0.0f);
		color += INPUT(src_data, temp1);
	}
	return color/(float)(2*Samples);
}

float4 hblur(image2d_t src_data, vec2 tc, int pixelNum,  float4 roi,float pitch)
{
	if(step(roi.x, tc.x)*step(roi.y, tc.y)*step(tc.x, roi.z)*step(tc.y, roi.w)< 0.9f)
		return INPUT(src_data,tc);
	
	int Samples = pixelNum;
    if(pixelNum==0){
        Samples=1;
    }
	
	float scale = pitch / 640.0f;
	float4 color = (float4)(0.0f);
	for (int i = -Samples; i < Samples; i += 2) //operating at 2 samples for better performance
	{
		vec2 temp1 =  tc + (vec2)( 0.0f, (float)(i) / pitch * scale);
		color += INPUT(src_data, temp1);
		
		temp1 =  tc + (vec2)( 0.0f, (float)(i+1) / pitch * scale);
		color += INPUT(src_data, temp1);
	}
	return color/(float)(2*Samples);
}


float4 masic(image2d_t src_data, int2 gl_FragCoord, int kPixelNum, vec2 u_resolution)
{
	int pixel;
    if (u_resolution.y < 433.00001f)
		pixel = (kPixelNum + 5) / 5;
	else
		pixel = (int)(u_resolution.y / 433.0f * kPixelNum + 5) / 5;
	
	int2 masicCord = (gl_FragCoord.xy + pixel / 2) / pixel * pixel;
	vec4 masicLayer = INPUT(src_data,convert_float2(masicCord)/u_resolution);
	
	return masicLayer;
}

float4 masicBlur(image2d_t src_data, vec2 tc, float kPixelNum, vec2 u_resolution, float4 roi)
{
	
	int  pixel = (int)(kPixelNum*u_resolution.x);
	
	vec4 a = vblur(src_data, tc, pixel, roi,u_resolution.x);
	vec4 orig = INPUT(src_data,tc);
	vec2 tcTemp = fmod( tc*u_resolution.xy/(float)(pixel), (vec2)(1.0f, 1.0f) );
	float matt = step(0.02f,tcTemp.x)*step(tcTemp.x, 0.98f)*step(0.02f,tcTemp.y)*step(tcTemp.y, 0.98f);
	return (vec4)( mix(orig.xyz,a.xyz,matt), 1.0f);
}

float4 circleMasic(image2d_t src_data, vec2 tc, vec2 u_resolution, float kPixelNum)
{
	int  pixel = (int)(kPixelNum*u_resolution.x);
	vec4 masicLayer = INPUT(src_data, tc);
	vec4 outputCol = (vec4)(0.0f);
	int dlPixelNum = pixel*2;
	vec2 center =  convert_float2( convert_int2( tc * u_resolution.xy + dlPixelNum/2)/ dlPixelNum * dlPixelNum )/u_resolution.xy ;
	vec2 bgCenter =  convert_float2( convert_int2( tc * u_resolution.xy )/ dlPixelNum * dlPixelNum )/u_resolution.xy ;
	float r = convert_float( convert_int( length( tc* u_resolution.xy - center* u_resolution.xy )  ) / pixel * pixel )/u_resolution.x ;
	float bar = (float)(pixel)/u_resolution.x;
	float smooth = 3.0f/u_resolution.x;
	float matt = 1.0f - smoothstep(bar-smooth, bar , r);
	vec4 masicCol = INPUT(src_data, center);
	vec4 orig = INPUT(src_data,bgCenter)*1.1f;
	return (vec4)(mix(orig.xyz,masicCol.xyz,matt ), 1.0f);
}

float4 ramp(image2d_t src_data, vec2 tc, vec2 u_resolution, float4 roi)
{
	
	vec4 leftBotCol = ( INPUT(src_data, (vec2)(roi.x,roi.y)) + INPUT(src_data, (vec2)(roi.x + 0.01f,roi.y)) + INPUT(src_data, (vec2)(roi.x ,roi.y+ 0.01f)) + INPUT(src_data, (vec2)(roi.x + 0.01f,roi.y + 0.01f)))/4.0f ;
	vec4 rightBotCol = ( INPUT(src_data, (vec2)(roi.z,roi.y)) + INPUT(src_data, (vec2)(roi.z + 0.01f,roi.y)) + INPUT(src_data, (vec2)(roi.z,roi.y+ 0.01f)) + INPUT(src_data, (vec2)(roi.z+ 0.01f,roi.y+ 0.01f)))/4.0f;
	vec4 leftTopCol = ( INPUT(src_data, (vec2)(roi.x,roi.w)) + INPUT(src_data, (vec2)(roi.x + 0.01f,roi.w)) + INPUT(src_data, (vec2)(roi.x,roi.w+ 0.01f)) + INPUT(src_data, (vec2)(roi.x,roi.w)+ 0.01f ))/4.0f;
	vec4 rightTopCol = ( INPUT(src_data, (vec2)(roi.z,roi.w)) + INPUT(src_data, (vec2)(roi.z + 0.01f,roi.w)) + INPUT(src_data, (vec2)(roi.z,roi.w + 0.01f)) + INPUT(src_data, (vec2)(roi.z,roi.w) + 0.01f))/4.0f;

	float xAlp =  (tc.x - roi.x)/(roi.z - roi.x);
	float yAlp = (tc.y - roi.y)/(roi.w - roi.y);
	
	vec4 col1 = mix(leftBotCol, rightBotCol, xAlp );
	vec4 col2 =  mix(leftTopCol, rightTopCol, xAlp );
	vec4 col3 = mix(col1, col2, yAlp );
	
	return col3;
}

float4 fadeGassian(image2d_t src_data, vec2 tc, vec2 u_resolution, float4 roi, int kPixelNum)
{
	
	float width = roi.z - roi.x;
	float height = roi.w - roi.y;
	float split = 103.0f - (float)(kPixelNum);
	if(kPixelNum<0.001f)
		split = 10000.0f;
	vec2  i_st = floor( tc * split )/split;
	float offset = 1.0f/split;
	vec2 temp;
	vec2 f_st = fract(tc * split, &temp);
	
	vec4 leftBotCol = INPUT(src_data, (vec2)(i_st.x,i_st.y)) ;
	vec4 rightBotCol = INPUT(src_data, (vec2)(i_st.x + offset,i_st.y)) ;
	vec4 leftTopCol = INPUT(src_data, (vec2)(i_st.x,i_st.y + offset)) ;
	vec4 rightTopCol = INPUT(src_data, (vec2)(i_st.x + offset,i_st.y + offset)) ;
	
	float xAlp =  f_st.x;
	float yAlp = f_st.y;
	
	vec4 col1 = mix(leftBotCol, rightBotCol, xAlp );
	vec4 col2 = mix(leftTopCol, rightTopCol, xAlp );
	vec4 col3 = mix(col1, col2, yAlp );
	
	return col3;
}

float4 pullBlurV(image2d_t src_data, vec2 tc, vec2 u_resolution, float4 roi)
{
	
	float x0 = roi.x;
	float y0 = roi.y;
	float x1 = roi.z;
	float y1 = roi.w;
	
	vec4 leftCol = INPUT(src_data, (vec2)(x0,tc.y)) ;
	vec4 rightCol = INPUT(src_data,(vec2)(x1,tc.y)) ;
	
	vec4 bottomCol = INPUT(src_data,(vec2)(tc.x,y0)) ;
	vec4 topCol = INPUT(src_data, (vec2)(tc.x,y1)) ;
		
	float xAlp =  (tc.x - x0)/(x1 - x0);
	float yAlp = (tc.y - y0)/(y1 - y0);
	
	vec4 col1 = mix(leftCol, rightCol, xAlp );

	return col1;
}

float4 pullBlurH(image2d_t src_data, vec2 tc, vec2 u_resolution, float4 roi)
{	
	float x0 = roi.x;
	float y0 = roi.y;
	float x1 = roi.z;
	float y1 = roi.w;
	
	vec4 leftCol = INPUT(src_data, (vec2)(x0,tc.y)) ;
	vec4 rightCol = INPUT(src_data,(vec2)(x1,tc.y)) ;
	
	vec4 bottomCol = INPUT(src_data,(vec2)(tc.x,y0)) ;
	vec4 topCol = INPUT(src_data, (vec2)(tc.x,y1)) ;

	float xAlp =  (tc.x - x0)/(x1 - x0);
	float yAlp = (tc.y - y0)/(y1 - y0);
	
	vec4 col2 =  mix(bottomCol, topCol, yAlp );

	return col2;
}

static float curve(float x, float strength)
{
	float step = strength/4.0f;
	if(x<step)
		return -x/step + 1.0f;
	else if(x<1.0f - step)
		return 0.0f;
	else 
		return x/step + (1.0f - 1.0f/step);
		
}

float2 rotateFunc(float2 uv, float2 center, float theta)
{
	float2 temp;
	temp.x = dot((float2)(cos(theta), -sin(theta)), uv - center);
	temp.y = dot((float2)(sin(theta), cos(theta)), uv - center);
	return (temp+center);
}

float2 rotateToCenter(float2 uv, float2 center, float theta, float2 iResolution)
{
	float2 temp;
	temp.x = dot((float2)(cos(theta), -sin(theta)), (uv - center)*iResolution);
	temp.y = dot((float2)(sin(theta), cos(theta)), (uv - center)*iResolution);
	return temp/iResolution;
}

__kernel void MAIN(
      __read_only image2d_t input1,
      __write_only image2d_t dest_data,
      __global FilterParam* param,
	  int KType,
	  int nPixelNum,
	  int nTransparency)
{	
	float kPixelNum = nPixelNum/100.0f;
	float kTransparency = nTransparency/100.0f;
	
	int W = param->width[0];
	int H = param->height[0];
	vec2 u_resolution = (vec2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1)) + 0.5f;
	vec2 tc = (vec2)(fragCoord.x, fragCoord.y)/u_resolution.xy;
	
	float visTheta = -radians(param->angle);
	
	float roiX0 = param->resultROI[0];
	float roiY0 = param->resultROI[1];
	float roiX1 = param->resultROI[0] + param->resultROI[2];
	float roiY1 = param->resultROI[1] +  param->resultROI[3];
	vec2 roiCenter = (vec2)(param->resultROI[0] + param->resultROI[2]/2.0f, param->resultROI[1] +  param->resultROI[3]/2.0f);
	vec2 rotatRoiXY0 = fabs( rotateToCenter((vec2)(roiX0, roiY0), roiCenter, visTheta, u_resolution ));
	vec2 rotatRoiXY1 = fabs( rotateToCenter((vec2)(roiX0, roiY1 ), roiCenter, visTheta,u_resolution ));
	vec2 halfSize = fmax(rotatRoiXY0,rotatRoiXY1);
	
	roiX0 = roiCenter.x - halfSize.x; 
	roiY0 = roiCenter.y - halfSize.y;
	roiX1 = roiCenter.x + halfSize.x; 
	roiY1 = roiCenter.y + halfSize.y;
	
	float visX0 = param->resultROI[0];
	float visY0 = param->resultROI[1];
	float visWidth = param->resultROI[2];
	float visHeight = param->resultROI[3];
	float2 center = (float2)(0.0f);
	
	float2 tempTcExe = tc; 
	if(fabs(visTheta)>1.0e-10f)
	{
		center.x = visX0 + (visWidth)/2.0f;
		center.y = visY0 + (visHeight)/2.0f;
		tempTcExe = rotateFunc(tempTcExe*u_resolution.xy,u_resolution.xy*center, visTheta)/u_resolution.xy;
	}
	float exeMatt = step(visX0,tempTcExe.x)*step(tempTcExe.x, visX0+visWidth)*step(visY0,tempTcExe.y)*step(tempTcExe.y, visY0+visHeight);
	
	vec4 orig = INPUT(input1,tc);
	vec4 outputCol = (vec4)(0.0f);
	vec4 colV = (vec4)(0.0f);
	vec4 colH =  (vec4)(0.0f);
	
	///KType = 5;
	switch(KType)
	{
		case 0:
			outputCol = vblur(input1, tc, nPixelNum ,(float4)(roiX0, roiY0, roiX1, roiY1),u_resolution.x);
			break;
		case 1:
			outputCol = hblur(input1, tc, nPixelNum ,(float4)(roiX0, roiY0, roiX1, roiY1),u_resolution.x);
			break;
		case 2:
			outputCol = masic(input1, gl_FragCoord, nPixelNum, u_resolution);
			break;
		case 3:
			outputCol =  fadeGassian(input1, tc, u_resolution, (float4)(roiX0, roiY0, roiX1, roiY1), nPixelNum);
			break;
		case 4:
			outputCol =  pullBlurV(input1, tc, u_resolution, (float4)(roiX0, roiY0, roiX1, roiY1));
            float tx =  (tc.x - roiX0)/(roiX1 - roiX0);
            float ta = (1.0f - curve(tx, kPixelNum))*0.3f;
            outputCol = outputCol * (1.0f - ta);
			break;	
		case 5:
			outputCol =  pullBlurH(input1, tc, u_resolution, (float4)(roiX0, roiY0, roiX1, roiY1));
            float ty = (tc.y - roiY0)/(roiY1 - roiY0);
            float tb = (1.0f - curve(ty, kPixelNum))*0.3f;
            outputCol = outputCol * (1.0f - tb);
			break;
		case 6:
		
			colV = pullBlurV(input1, tc, u_resolution, (float4)(roiX0, roiY0, roiX1, roiY1));
			colH = pullBlurH(input1, tc, u_resolution, (float4)(roiX0, roiY0, roiX1, roiY1));
			
			float x = (tc.x - roiX0)/(roiX1 - roiX0);
			float y = (tc.y - roiY0)/(roiY1 - roiY0);
			
			float a = (1.0f - curve(x, kPixelNum))*0.5f;
			float b = 0.5f * curve(y, kPixelNum) + 0.5f;
			float c = a*b*2.0f;
			
			outputCol = colV * (1.0f - c)  + colH * c;
			break;
	}
	if(exeMatt>0.0f)
		write_imagef(dest_data, gl_FragCoord, (float4)( mix(orig.xyz, outputCol.xyz, kTransparency), orig.w));
	else
		write_imagef(dest_data, gl_FragCoord, orig);
}