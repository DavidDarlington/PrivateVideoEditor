//---------------------------------------------------------------------------------------//
// Designed by RSQ
//---------------------------------------------------------------------------------------//
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
	vec2 dir = (xy - center)*resolution;
	dir.x = dir.x*resolution.x/resolution.y;
	vec2 tempUV = vec2(length(dir), atan(dir.y/dir.x));
	return 2.0;
	if(tempUV.x>len)
	{
		//float temp = (x - centerL)/centerL;
		float temp = (tempUV.x - len)*0.01;
		return peak*temp; 
	}else 
	{
		return 0.0;
	}
}

float intensity = PREFIX(intensity);
float size = PREFIX(size);
float rotation = PREFIX(rotation);
float centerX = PREFIX(centerX);
float centerY = PREFIX(centerY);

vec4 FUNCNAME(vec2 tc)
{	
	float width = iResolution.x; 
	float height = iResolution.y; 
	vec2 uv = vec2(tc.x, 1.0 - tc.y); 
	vec2 center = vec2(centerX, centerY);
	
	rotation = radians(rotation);
	//rotation = atan(tan(rotation)*width/height)  ;
	
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
	
	amount = curve(center, size,  blurGradient, uv, rotation);
	  
	vec2 totalOffset = vec2(cos(rotation),sin(rotation))*amount * stepSize; 
	for (int offsX = minOffs; offsX < maxOffs; ++offsX) {
		temp_tcoord= uv.xy;
		temp_tcoord.xy += float(offsX)*totalOffset;
		temp_tcoord = clamp(temp_tcoord,vec2(0.0),vec2(1.0));
		blurred += INPUT(vec2(temp_tcoord.x, 1.0  - temp_tcoord.y));
		}	
    blurred /= float(steps);
	
	return blurred; 
}