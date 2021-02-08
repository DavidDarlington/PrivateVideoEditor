// author: RuanShengQiang 
// date: 2017/6/1
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP | CLK_FILTER_LINEAR;

vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, (vec2)(tc.x, 1.0f - tc.y));
}

float _abs(float a)
{
	if(a<0.0f)
		return -a;
	else
		return a;
}

bool inBounds (vec2 p,vec2 resolution) {
  float xMax = resolution.x / resolution.y / 2.0f;
  vec2 temp1 = (vec2)(-xMax, -0.5f);
  vec2 temp2 = (vec2)(xMax, 0.5f);
  return temp1.x<p.x && temp1.y<p.y && p.x < temp2.x && p.y <temp2.y;
 // return all(lessThan((vec2)(-xMax, -0.5f), p)) && all(lessThan(p, (vec2)(xMax, 0.5f)));
}

__kernel void MAIN(__read_only image2d_t input1, __read_only image2d_t input2, __write_only image2d_t dstImg,__global FilterParam* param)
{
	//const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;
	
	float progress = param->cur_time / param->total_time;	int W = param->width[2];	int H = param->height[2];	int w = get_global_id(0);
	int h = get_global_id(1);
	float curPos = progress*2.0f;

	float2 resolution = (float2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 uv = ((vec2)(fragCoord.x, fragCoord.y) + (vec2)(0.5f)) /resolution.xy;
	
	float4 gl_FragColor = (vec4)(0.0f);
	vec2 r = (vec2)(fragCoord.xy - 0.5f*resolution.xy)/resolution.y;
	float xMax = resolution.x / resolution.y;
	vec2 q;
	float angle;
	if(progress < 0.5f)
	{
	  angle = progress * 10.f*3.1415926f; 
  
	  q.x =   cos(angle)*r.x + sin(angle)*r.y;
	  q.y = - sin(angle)*r.x + cos(angle)*r.y;
	  q = q * (vec2)(1.0f + progress *50.f);
	  
	  if(inBounds(q, resolution))
	  {
		vec2 rp = q+(vec2)(xMax / 2.f, 0.5f);
		gl_FragColor = INPUT(input1, (vec2)(rp.x / xMax, rp.y));
	  }
    
	}
	else
	{
	  angle = (1.0f - progress) * 10.f*3.1415926f; 
  
	  q.x =   cos(angle)*r.x + sin(angle)*r.y;
	  q.y = - sin(angle)*r.x + cos(angle)*r.y;
	  
	  q = q * (vec2)(50.0f - progress *49.f);
	  
	  if(inBounds(q,resolution))
	  {
		vec2 rp = q+(vec2)(xMax / 2.f, 0.5f);
		gl_FragColor = INPUT(input2, (vec2)(rp.x / xMax, rp.y));
	  }
	}
	write_imagef(dstImg, (int2)(w, H - h - 1), gl_FragColor);
}