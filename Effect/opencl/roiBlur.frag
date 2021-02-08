
#ifdef GL_ES
precision highp float;
#endif


vec4 vblur(vec2 tc, float scaleDir,  vec4 roi)
{
	if(step(roi.x, tc.x)*step(roi.y, tc.y)*step(tc.x, roi.z)*step(tc.y, roi.w)< 0.9)
		return INPUT(tc);
	
	int Samples = 20;
	vec4 color = vec4(0.0);
	
	for (int i = -Samples; i < Samples; i += 2) //operating at 2 samples for better performance
	{
		vec2 temp1 =  tc + vec2( float(i) / float(Samples)*scaleDir,0.0);
		color += INPUT(temp1);
		
		temp1 =  tc + vec2( float(i+1) / float(Samples)*scaleDir,0.0);
		color += INPUT(temp1);
	}
	return color/float(2*Samples);
}

vec4 hblur(vec2 tc, float scaleDir,  vec4 roi)
{
	if(step(roi.x, tc.x)*step(roi.y, tc.y)*step(tc.x, roi.z)*step(tc.y, roi.w)< 0.9)
		return INPUT(tc);
	
	int Samples = 20;
	vec4 color = vec4(0.0);
	for (int i = -Samples; i < Samples; i += 2) //operating at 2 samples for better performance
	{
		vec2 temp1 =  tc + vec2( 0.0, float(i) / float(Samples)*scaleDir);
		color += INPUT(temp1);
		
		temp1 =  tc + vec2( 0.0, float(i+1) / float(Samples)*scaleDir);
		color += INPUT(temp1);
	}
	return color/float(2*Samples);
}


vec4 masic(int kPixelNum, vec2 tc,vec2 u_resolution)
{
	int pixel;
    if (u_resolution.y < 433.00001f)
		pixel = (kPixelNum + 5) / 5;
	else
		pixel = int(u_resolution.y / 433.0 * float(kPixelNum) + 5.0) / 5;
	
	int a = ((int(gl_FragCoord.x) + pixel/2)/pixel )*pixel;
	int b = ((int(tc.y * u_resolution.y) + pixel/2)/pixel )*pixel;
	
	vec4 masicLayer = INPUT(vec2(float(a), float(b))/u_resolution);
	
	return masicLayer;
}

vec4 masicBlur(vec2 tc, float kPixelNum, vec2 u_resolution, vec4 roi)
{
	
	int  pixel = int(kPixelNum*u_resolution.x);
	
	vec4 a = vblur(tc, 0.05, roi);
	vec4 orig = INPUT(tc);
	vec2 tcTemp = mod( tc*u_resolution.xy/float(pixel), 1.0 );
	float matt = step(0.02,tcTemp.x)*step(tcTemp.x, 0.98)*step(0.02,tcTemp.y)*step(tcTemp.y, 0.98);
	return vec4( mix(orig.xyz,a.xyz,matt), 1.0);
}

vec4 ramp(vec2 tc, vec2 u_resolution, vec4 roi)
{
	
	vec4 leftBotCol = ( INPUT( vec2(roi.x,roi.y)) + INPUT( vec2(roi.x + 0.01,roi.y)) + INPUT(vec2(roi.x ,roi.y+ 0.01)) + INPUT(vec2(roi.x + 0.01,roi.y + 0.01)))/4.0 ;
	vec4 rightBotCol = ( INPUT( vec2(roi.z,roi.y)) + INPUT( vec2(roi.z + 0.01,roi.y)) + INPUT(vec2(roi.z,roi.y+ 0.01)) + INPUT(vec2(roi.z+ 0.01,roi.y+ 0.01)))/4.0;
	vec4 leftTopCol = ( INPUT( vec2(roi.x,roi.w)) + INPUT( vec2(roi.x + 0.01,roi.w)) + INPUT(vec2(roi.x,roi.w+ 0.01)) + INPUT(vec2(roi.x,roi.w)+ 0.01 ))/4.0;
	vec4 rightTopCol = ( INPUT( vec2(roi.z,roi.w)) + INPUT( vec2(roi.z + 0.01,roi.w)) + INPUT(vec2(roi.z,roi.w + 0.01)) + INPUT(vec2(roi.z,roi.w) + 0.01))/4.0;

	float xAlp =  (tc.x - roi.x)/(roi.z - roi.x);
	float yAlp = (tc.y - roi.y)/(roi.w - roi.y);
	
	vec4 col1 = mix(leftBotCol, rightBotCol, xAlp );
	vec4 col2 =  mix(leftTopCol, rightTopCol, xAlp );
	vec4 col3 = mix(col1, col2, yAlp );
	
	return col3;
}

vec4 fadeGassian( vec2 tc, vec2 u_resolution, vec4 roi, float kPixelNum)
{
	
	float width = roi.z - roi.x;
	float height = roi.w - roi.y;
	float split = 103.0 - kPixelNum;
	if(kPixelNum<0.001)
		split = 10000.0;
	vec2  i_st = floor( tc * split )/split;
	float offset = 1.0/split;
	vec2 temp;
	vec2 f_st = fract(tc * split);
	
	vec4 leftBotCol = INPUT( vec2(i_st.x,i_st.y)) ;
	vec4 rightBotCol = INPUT(vec2(i_st.x + offset,i_st.y)) ;
	vec4 leftTopCol = INPUT(vec2(i_st.x,i_st.y + offset)) ;
	vec4 rightTopCol = INPUT(vec2(i_st.x + offset,i_st.y + offset)) ;
	
	float xAlp =  f_st.x;
	float yAlp = f_st.y;
	
	vec4 col1 = mix(leftBotCol, rightBotCol, xAlp );
	vec4 col2 = mix(leftTopCol, rightTopCol, xAlp );
	vec4 col3 = mix(col1, col2, yAlp );
	
	return col3;
}

vec4 pullBlurV( vec2 tc, vec2 u_resolution, vec4 roi)
{
	
	float x0 = roi.x;
	float y0 = roi.y;
	float x1 = roi.z;
	float y1 = roi.w;
	
	vec4 leftCol = INPUT(vec2(x0,tc.y)) ;
	vec4 rightCol = INPUT(vec2(x1,tc.y)) ;
	
	vec4 bottomCol = INPUT(vec2(tc.x,y0)) ;
	vec4 topCol = INPUT(vec2(tc.x,y1)) ;
		
	float xAlp =  (tc.x - x0)/(x1 - x0);
	float yAlp = (tc.y - y0)/(y1 - y0);
	
	vec4 col1 = mix(leftCol, rightCol, xAlp );

	return col1;
}

vec4 pullBlurH(vec2 tc, vec2 u_resolution, vec4 roi)
{	
	float x0 = roi.x;
	float y0 = roi.y;
	float x1 = roi.z;
	float y1 = roi.w;
	
	vec4 leftCol = INPUT(vec2(x0,tc.y)) ;
	vec4 rightCol = INPUT(vec2(x1,tc.y)) ;
	
	vec4 bottomCol = INPUT(vec2(tc.x,y0)) ;
	vec4 topCol = INPUT(vec2(tc.x,y1)) ;

	float xAlp =  (tc.x - x0)/(x1 - x0);
	float yAlp = (tc.y - y0)/(y1 - y0);
	
	vec4 col2 =  mix(bottomCol, topCol, yAlp );

	return col2;
}
 float curve(float x, float strength)
{
	float step = strength/4.0;
	if(x<step)
		return -x/step + 1.0;
	else if(x<1.0 - step)
		return 0.0;
	else 
		return x/step + (1.0 - 1.0/step);
		
}

vec2 rotateToCenter(vec2 uv, vec2 center, float theta, vec2 iResolution)
{
	vec2 temp;
	temp.x = dot(vec2(cos(theta), -sin(theta)), (uv - center)*iResolution);
	temp.y = dot(vec2(sin(theta), cos(theta)), (uv - center)*iResolution);
	return temp/iResolution;
}

vec2 rotateFunc(vec2 uv, vec2 center, float theta)
{
	vec2 temp;
	temp.x = dot(vec2(cos(theta), -sin(theta)), uv - center);
	temp.y = dot(vec2(sin(theta), cos(theta)), uv - center);
	return temp + center;
}

vec4 FUNCNAME(vec2 tc) {
	
	int KType = PREFIX(Type);
	float kTransparency = float(PREFIX(Opacity))/100.0;
	float kPixelNum = float(PREFIX(Intensity))/100.0;
    int NPixelNum = int(PREFIX(Intensity));
	float FPixelNum = float(PREFIX(Intensity));
	vec4 result_roi = PREFIX(result_roi);
	
	// result_roi.y = 1.0 - result_roi.y - result_roi.a;
	
	float visTheta = radians(PREFIX(roi_angle));
   
	float roiX0 =  result_roi.x;
	float roiY0 = result_roi.y;
	
	
    if (result_roi.z < 0.0) {
        result_roi.z *= -1.0;
        result_roi.x -= result_roi.z;
        roiX0 = result_roi.x;        
    }

    if (result_roi.a < 0.0) {
        result_roi.a *= -1.0;
        result_roi.y -= result_roi.a;
	    roiY0 = result_roi.y;

    }
    float roiX1 = result_roi.x + result_roi.z;
	float roiY1 =  result_roi.y + result_roi.a;
	
	vec2 roiCenter = vec2(result_roi.x + result_roi.z/2.0, (result_roi.y + result_roi.a/2.0));
	vec2 rotatRoiXY0 = abs( rotateToCenter(vec2(roiX0, roiY0), roiCenter, visTheta, iResolution.xy ));
	vec2 rotatRoiXY1 = abs( rotateToCenter(vec2(roiX0, roiY1), roiCenter, visTheta, iResolution.xy ));
	vec2 halfSize = max(rotatRoiXY0,rotatRoiXY1);
	
	roiX0 = roiCenter.x - halfSize.x; 
	roiY0 = roiCenter.y + halfSize.y;
	roiX1 = roiCenter.x + halfSize.x; 
	roiY1 = roiCenter.y - halfSize.y;
	
	float visX0 = result_roi.x;
	float visY0 = result_roi.y;
	float visWidth = result_roi.z;
	float visHeight = result_roi.a;
	vec2 center = vec2(0.0);
	
	vec2 tempTcExe = tc; 
	if(abs(visTheta)>1.0e-10)
	{
		center.x = visX0 + (visWidth)/2.0;
		center.y = visY0 + (visHeight)/2.0;
		tempTcExe = rotateFunc(tempTcExe*iResolution.xy,iResolution.xy*center,visTheta)/iResolution.xy;
	}
	float exeMatt = step(visX0,tempTcExe.x)*step(tempTcExe.x, visX0+visWidth)*step(visY0,tempTcExe.y)*step(tempTcExe.y, visY0+visHeight);
	
	
	vec4 orig = INPUT(tc);
	
	vec4 outputCol = vec4(0.0);
	
	vec4 colV = vec4(0.0);
	vec4 colH =  vec4(0.0);
	
	vec4 roi = vec4(roiX0, roiY0, roiX1, roiY1);
	int Samples = NPixelNum;
    if(NPixelNum==0){
        Samples = 1;
    }
	vec4 color = vec4(0.0);

	if(KType == 0)
	{
		float scaleDir = iResolution.x / 640.0;
		if(step(roi.x, tc.x)*step(roi.y, tc.y)*step(tc.x, roi.z)*step(tc.y, roi.w)< 0.9)
			outputCol =  INPUT(tc);
		
		for (int i = -Samples; i < Samples; i += 2) //operating at 2 samples for better performance
		{
			vec2 temp1 =  tc + vec2( float(i) / iResolution.x*scaleDir,0.0);
			color += INPUT(temp1);
			
			temp1 =  tc + vec2( float(i+1) / iResolution.x*scaleDir,0.0);
			color += INPUT(temp1);
		}
		outputCol = color/float(2*Samples);
	}else if(KType == 1)
	{
        float scaleDir = iResolution.x / 640.0;
		if(step(roi.x, tc.x)*step(roi.y, tc.y)*step(tc.x, roi.z)*step(tc.y, roi.w)< 0.9)
			outputCol =  INPUT(tc);
	
		for (int i = -Samples; i < Samples; i += 2) //operating at 2 samples for better performance
		{
			vec2 temp1 =  tc + vec2( 0.0, float(i) / iResolution.x*scaleDir);
			color += INPUT(temp1);
			
			temp1 =  tc + vec2( 0.0,  float(i+1) / iResolution.x*scaleDir);
			color += INPUT(temp1);
		}
		outputCol = color/float(2*Samples);
	}else if(KType == 2)
	{
		outputCol = masic(NPixelNum, tc,iResolution.xy);
	}else if(KType == 3)
	{
		outputCol =  fadeGassian(tc, iResolution.xy, vec4(roiX0, roiY0, roiX1, roiY1), FPixelNum);
	}
	else if(KType == 4)
	{	
		outputCol =  pullBlurV(tc, iResolution.xy, vec4(roiX0, roiY0, roiX1, roiY1));
        float tx =  (tc.x - roiX0)/(roiX1 - roiX0);
        float ta = (1.0 - curve(tx, kPixelNum))*0.3;
        outputCol = outputCol * (1.0 - ta) + orig * ta;
	}else if(KType == 5)
	{
		outputCol =  pullBlurH(tc, iResolution.xy, vec4(roiX0, roiY0, roiX1, roiY1));
        float ty = (tc.y - roiY0)/(roiY1 - roiY0);
        float tb = (1.0 - curve(ty, kPixelNum))*0.3;
        outputCol = outputCol * (1.0 - tb) + orig * tb;
	}else if(KType == 6)
	{
		colV = pullBlurV(tc, iResolution, vec4(roiX0, roiY0, roiX1, roiY1));
		colH = pullBlurH(tc, iResolution, vec4(roiX0, roiY0, roiX1, roiY1));
			
		float x = (tc.x - roiX0)/(roiX1 - roiX0);
		float y = (tc.y - roiY0)/(roiY1 - roiY0);
			
		float a = (1.0 - curve(x, kPixelNum))*0.5;
		float b = 0.5 * curve(y, kPixelNum) + 0.5;
		float c = a*b*2.0;
			
		outputCol = colV * (1.0 - c)  + colH * c;
	}
	
	if(exeMatt>0.0)
		return vec4( mix(orig.xyz, outputCol.xyz, kTransparency), orig.w );
	else
		return orig;
}

