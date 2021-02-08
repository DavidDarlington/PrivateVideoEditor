vec4 blending(vec4 backGround, vec4 ovl, float matt, float tempMatt, float exeMatt)
{
	float opacity = 1.0; 
	vec4 outputColor = vec4(0.0);
	vec4 overlay = ovl * tempMatt * exeMatt; 
	vec4 bgCol = backGround;
	float tempOpacity = opacity * matt * exeMatt;
	float invTemOpacity = 1.0 - tempOpacity;
	
	outputColor = overlay;
	tempOpacity = opacity * tempMatt * exeMatt;
	
	outputColor = clamp(outputColor, vec4(0.0), vec4(1.0));
	outputColor.a = overlay.a * overlay.a + (1.0 - overlay.a)* bgCol.a;
	return outputColor*tempOpacity + invTemOpacity*bgCol;
	
}
	
int inORout = PREFIX(inORout);
float visX0 = PREFIX(visX0);
float visY0 = PREFIX(visY0);
float visWidth = PREFIX(visWidth);
float visHeight = PREFIX(visHeight); 

vec4 FUNCNAME(vec2 tc)
{
	
	float progress = PREFIX(global_time);
	const float eps = 1.0e-10;
	
	tc = vec2(tc.x, 1.0 - tc.y);
	
	vec2 tempTc = tc;
	vec2 tempTcExe = tc; 

	float roiX0 = visX0;
	float roiY0 = visY0;
	float roiX1 = visX0 + visWidth;
	float roiY1 = visY0 + visHeight;
	
	float resultX0 = visX0 ;
	float resultY0 = visY0;
	float resultX1 = visX0 + visWidth;
	float resultY1 = visY0 + visHeight;
	vec4 bgCol = vec4(0.0);
	
	if(inORout == 0)
	{
		bgCol = INPUT1(vec2(tempTc.x, 1.0 - tempTc.y));
		progress = visWidth - ( 3.0 * progress * progress - 2.0 * progress* progress* progress ) * (visWidth);
	}else
	{
		bgCol = INPUT2(vec2(tempTc.x, 1.0 - tempTc.y));
		progress = visWidth +  ( ( 3.0 * progress * progress - 2.0 * progress* progress* progress ) - 1.0) * (visWidth);
	}
	//moveX(progress);
	resultX0 = resultX0 + progress;
	resultX1 = resultX1 + progress;
	
	vec2 roiCenter = vec2((roiX1-roiX0)*0.5 + roiX0, (roiY1-roiY0)*0.5 + roiY0);
	vec2 resultRoiCenter = vec2((resultX1-resultX0)*0.5 + resultX0, (resultY1-resultY0)*0.5 + resultY0);
	vec2 transl =  resultRoiCenter - roiCenter;
	
	float scalFactorX = (resultX1 - resultX0)/(roiX1 - roiX0);
	float scalFactorY = (resultY1 - resultY0)/(roiY1 - roiY0);

	vec2 tranTc;
    tranTc = tc  - transl;
	vec2 center = roiCenter;
	tranTc.x = ( tranTc.x - center.x )/(scalFactorX+eps) + center.x ;
	tranTc.y = ( tranTc.y - center.y )/(scalFactorY+eps) + center.y;

	float smoothGap = 2.0/iResolution.x; 
	float matt = step(roiX0,tranTc.x)*step(tranTc.x, roiX1)*step(roiY0,tranTc.y)*step(tranTc.y, roiY1);
	
	vec4 ovlCol; 
	if(inORout == 0)
	{
		ovlCol = INPUT2(vec2(tranTc.x, 1.0 - tranTc.y));
	
	}else
	{
		ovlCol = INPUT1(vec2(tranTc.x, 1.0 - tranTc.y));
	}
	
	float exeMatt = step(visX0,tempTcExe.x)*step(tempTcExe.x, visX0+visWidth)*step(visY0,tempTcExe.y)*step(tempTcExe.y, visY0+visHeight);
	float tempMatt = matt;
	matt = matt*ovlCol.a*exeMatt;
	
	vec4 outputCol = blending( bgCol, ovlCol, matt, tempMatt, exeMatt);
	return outputCol;
}