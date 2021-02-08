/********************************************************************
author: RuanShengQiang
date: 2017/3/21
********************************************************************/
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;

vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, tc);
}

__kernel void MAIN(
      __read_only image2d_t input1,
      __write_only image2d_t dest_data,
      __global FilterParam* param,
	  float radius,
	  int colorR,
	  int colorG,
	  int colorB,
	  float opacity,
	  float softness,
	  float enable,
	  float iMouseX,
	  float iMouseY)
{	
	int W = param->width[0];
	int H = param->height[0];
	
	float2 resolution = (float2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1)) + 0.5f;
	vec2 tc = (vec2)(fragCoord.x, fragCoord.y)/resolution.xy;
	vec4 img = INPUT(input1,tc);
    float rad = radius/4.0f;
    vec3 rgb = (vec3)(colorR,colorG,colorB)/255.0f;
    float soft = softness/50.0f;
	vec4 gl_FragColor = img;
	vec2 iMouse = (vec2)(iMouseX,iMouseY);
	
	if(enable>0.5f)
    {
		float alpha = clamp(opacity,0.0f,1.0f);
		float r = length(tc*resolution - iMouse.xy)/resolution.x;
		if(r<rad+soft)
		{
			float expo= 1.0f - smoothstep(rad-soft,rad+soft,r);//clamp(exp(-(soft*soft)*r*r/rad/rad)+softness*0.1f,0.0f,1.0f);
			alpha = clamp(alpha * expo ,0.0f,1.0f);
			gl_FragColor = (vec4)(mix(img.rgb,rgb,alpha),1.0f);
		}
	}
	 write_imagef(dest_data, gl_FragCoord, gl_FragColor);
}