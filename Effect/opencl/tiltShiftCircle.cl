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

static float2 rotateFunc(float2 uv, float2 center, float theta)
{
	float2 temp;
	temp.x = dot((float2)(cos(theta), -sin(theta)), uv - center);
	temp.y = dot((float2)(sin(theta), cos(theta)), uv - center);
	return (temp+center);
}

static float curveRadius(vec2 center, float len, float peak, vec2 xy, vec2 resolution)
{
	vec2 dir = (xy - center);
	//dir.x = dir.x*resolution.x/resolution.y;
	dir.y*=resolution.y/resolution.x;
	vec2 tempUV = (vec2)(length(dir), atan(dir.y/dir.x));
	if(tempUV.x>len)
	{
		//float temp = (x - centerL)/centerL;
		float temp = (tempUV.x - len);
		return peak*temp; 
	}else 
	{
		return 0.0f;
	}
}
	  
 __kernel void tiltShiftCircleH(
      __read_only image2d_t src_data,
      __write_only image2d_t dest_data,
      int width, 
	  int height,
	  float intensity,
	  float size,
	  float centerX,
	  float centerY)
{	
	vec2 center = (vec2)(centerX, centerY);
	
	float blurGradient = 1.0f; // 0.0 - 1.0
	int W = width;
	int H = height;
	vec2 iResolution = (vec2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	float2 fragCoord = (float2)(get_global_id(0), get_global_id(1));
	float2 uv = fragCoord/iResolution.xy;
	
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
	
	amount = curveRadius(center, size,  blurGradient, uv, iResolution);
	vec2 dir = uv - center;
	vec2 tempUV = (vec2)(length(dir), atan(dir.y/dir.x));
	
	vec2 offsUV = (vec2)(amount*cos(tempUV.y), amount*sin(tempUV.y));
	for (int offsX = minOffs; offsX < maxOffs; ++offsX) {
		temp_tcoord= uv.xy;
		temp_tcoord.xy += offsX* stepSize *offsUV;
		blurred+= INPUT(src_data, temp_tcoord);
	}
		
    blurred /= (float)(steps);
	write_imagef(dest_data, gl_FragCoord,  blurred);
}

__kernel void tiltShiftCircleV(
      __read_only image2d_t src_data,
      __write_only image2d_t dest_data,
      int width, 
	  int height,
	  float intensity,
	  float size,
	  float centerX,
	  float centerY)
{	
	vec2 center = (vec2)(centerX, centerY);
	
	float blurGradient = 1.0f; // 0.0 - 1.0
	int W = width;
	int H = height;
	vec2 iResolution = (vec2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	float2 fragCoord = (float2)(get_global_id(0), get_global_id(1));
	float2 uv = fragCoord/iResolution.xy;
	
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
	
	amount = curveRadius(center, size,  blurGradient, uv, iResolution);
	vec2 dir = uv - center;
	vec2 tempUV = (vec2)(length(dir), atan(dir.y/dir.x));
	
	vec2 offsUV = (vec2)(amount*cos(tempUV.y), amount*sin(tempUV.y ));
	for (int offsX = minOffs; offsX < maxOffs; ++offsX) {
		temp_tcoord= uv.xy;
		temp_tcoord.xy += offsX* stepSize *offsUV;
		blurred += INPUT(src_data, temp_tcoord);
	}
		
    blurred/= (float)(steps);
	write_imagef(dest_data, gl_FragCoord,  blurred);
}
