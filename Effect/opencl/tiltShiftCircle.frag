vec2 rotateFunc(vec2 uv, vec2 center, float theta)
{
	vec2 temp;
	uv = uv*iResolution.xy;
	center = center*iResolution.xy;
	
	temp.x = dot(vec2(cos(theta), -sin(theta)), uv - center);
	temp.y = dot(vec2(sin(theta), cos(theta)), uv - center);
	return (temp+center)/iResolution.xy;
}

float curve(vec2 center, float len, float peak, vec2 xy, float theta)
{
	vec2 tempUV = rotateFunc(xy, center, theta);
	float centerL = center.x - len;
	float centerR = center.x + len;
	if(centerL > centerR)
		centerL = centerR;
	if(tempUV.x<centerL)
	{
		//float temp = (x - centerL)/centerL;
		float temp = (centerL - tempUV.x);
		return temp; 
	}else if(tempUV.x>centerR)
	{
		//float temp = (x - centerR)/(1.0f - centerR);
		float temp = (tempUV.x - centerR);
		return temp; 
	}else 
	{
		return 0.0;
	}
}


float curveRadius(vec2 center, float len, float peak, vec2 xy, vec2 resolution)
{
	vec2 dir = (xy - center);
	//dir.x = dir.x*resolution.x/resolution.y;
	dir.y*=resolution.y/resolution.x;
	vec2 tempUV = vec2(length(dir), atan(dir.y/dir.x));
	if(tempUV.x>len)
	{
		//float temp = (x - centerL)/centerL;
		float temp = (tempUV.x - len);
		return peak*temp; 
	}else 
	{
		return 0.0;
	}
}

float intensity = PREFIX(intensity);
float size = PREFIX(size);
float centerX = PREFIX(centerX);
float centerY = PREFIX(centerY);

vec4 FUNCNAME(vec2 tc)
{	
	float width = iResolution.x; 
	float height = iResolution.y; 
	vec2 uv = vec2(tc.x, 1.0 - tc.y); 
	vec2 center = vec2(centerX, centerY);
	
	float blurGradient = 1.0; // 0.0 - 1.0
	
	float stepSize    = 0.018*intensity;
	float steps       = 20.0;
	int minOffs     = -int(steps / 2.0);
	int maxOffs     = -int(minOffs);

    float amount;
    vec4 blurred;
    blurred = vec4(0.0, 0.0, 0.0, 0.0);
    vec2 temp_tcoord;
	blurred.z = INPUT(vec2(uv.x, 1.0-uv.y)).z;
	float prop = iResolution.x/iResolution.y;
	
	amount = curveRadius(center, size,  blurGradient, uv, iResolution);
	vec2 dir = uv - center;
	vec2 tempUV = vec2(length(dir), atan(dir.y/dir.x));
	vec2 offsUV = vec2(amount*cos(tempUV.y), amount*sin(tempUV.y ));
	
	for (int offsX = minOffs; offsX < maxOffs; ++offsX) {
		temp_tcoord= uv.xy;
		temp_tcoord.xy += float(offsX) * stepSize * offsUV;
		temp_tcoord = clamp(temp_tcoord,vec2(0.0),vec2(1.0));
		blurred += INPUT(vec2(temp_tcoord.x, 1.0  - temp_tcoord.y));
		}
	blurred /= float(steps);
	
	return blurred; 
}