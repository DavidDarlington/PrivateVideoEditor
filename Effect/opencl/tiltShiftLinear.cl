#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;

static vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, tc);
}

static vec2 rotateFunc(vec2 uv, vec2 center, float theta, vec2 iResolution)
{

	vec2 temp;
	uv = uv*iResolution.xy;
	center = center*iResolution.xy;
	
	temp.x = dot((vec2)(cos(theta), -sin(theta)), uv - center);
	temp.y = dot((vec2)(sin(theta), cos(theta)), uv - center);
	return (temp+center)/iResolution.xy;
}

static float curve(vec2 center, float len, float peak, vec2 xy, float theta, vec2 iResolution)
{
	vec2 tempUV = rotateFunc(xy, center, theta, iResolution);
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
		return 0.0f;
	}
}

static float curveRadius(vec2 center, float len, float peak, vec2 xy, vec2 resolution)
{
	vec2 dir = (xy - center)*resolution;
	dir.x = dir.x*resolution.x/resolution.y;
	vec2 tempUV = (vec2)(length(dir), atan(dir.y/dir.x));
	return 2.0f;
	if(tempUV.x>len)
	{
		//float temp = (x - centerL)/centerL;
		float temp = (tempUV.x - len)*0.01f;
		return peak*temp; 
	}else 
	{
		return 0.0f;
	}
}

__kernel void linearTiltH(
      __read_only image2d_t src_data,
      __write_only image2d_t dest_data,
      int width, 
	  int height,
	  float intensity,
	  float size,
	  float rotation,
	  float centerX,
	  float centerY)
{	
	//size /= 2.0f;
	vec2 center = (vec2)(centerX, centerY);
	
	rotation = radians(rotation);
	
	//rotation = atan(tan(rotation)*width/height)  ;
	
	float blurGradient = 1.0f; // 0.0 - 1.0
	int W = width;
	int H = height;
	vec2 iResolution = (vec2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1)) + 0.5f;
	vec2 uv = fragCoord/iResolution.xy;
	
	const float stepSize    = 0.018f*intensity;
	const float steps       = 20.0f;
	int minOffs     = -(steps / 2.0f);
	int maxOffs     = - minOffs;

    float amount;
    vec4 blurred;
    blurred = (vec4)(0.0f, 0.0f, 0.0f, 0.0f);
    vec2 temp_tcoord;
	//blurred.x = INPUT(src_data, uv).x;
	float prop = iResolution.x/iResolution.y;
	
	amount = curve(center, size,  blurGradient, uv, rotation, iResolution);
	  
	vec2 totalOffset = (vec2)(cos(rotation),sin(rotation))*amount * stepSize; 
	for (int offsX = minOffs; offsX < maxOffs; ++offsX) {
		temp_tcoord= uv.xy;
		temp_tcoord.xy += offsX*totalOffset;
		blurred += INPUT(src_data, temp_tcoord);
		}	
    blurred /= (float)(steps);
	write_imagef(dest_data, gl_FragCoord,  blurred );
}

	  
__kernel void linearTiltV(
      __read_only image2d_t src_data,
      __write_only image2d_t dest_data,
      int width, 
	  int height,
	  float intensity,
	  float size,
	  float rotation,
	  float centerX,
	  float centerY)
{	
	
	size /= 2.0f;
	vec2 center = (vec2)(centerX, centerY);
	rotation = radians(rotation);
	rotation = atan(tan(rotation)*width/height);
	
	float blurGradient = 1.0f; // 0.0 - 1.0
	int W = width;
	int H = height;
	vec2 iResolution = (vec2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1)) + 0.5f;
	vec2 uv = fragCoord/iResolution.xy;
	
	const float stepSize    = 0.018f*intensity;
	const float steps       = 20.0f;
	int minOffs     = -(steps / 2.0f);
	int maxOffs     = - minOffs;

    float amount;
    vec4 blurred;
    blurred = (vec4)(0.0f, 0.0f, 0.0f, 0.0f);
    vec2 temp_tcoord;
	blurred.x = INPUT(src_data, uv).x;//color order RGBA
	float prop = iResolution.x/iResolution.y;

	amount = curve(center, size,  blurGradient, uv, rotation, iResolution);
	 
	vec2 totalOffset = (vec2)(cos(rotation),sin(rotation)) * stepSize *amount;  
	for (int offsX = minOffs; offsX < maxOffs; ++offsX) {
				temp_tcoord= uv.xy;
				temp_tcoord.xy += offsX*totalOffset;
				blurred += INPUT(src_data, temp_tcoord);
	}
    blurred /= (float)(steps);
	write_imagef(dest_data, gl_FragCoord,  blurred );
}		  