/********************************************************************
author: RuanShengQiang
date: 2017/3/21
********************************************************************/
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE| CLK_FILTER_NEAREST;

vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, tc);
}

__kernel void MAIN(
      __read_only image2d_t input1,
      __write_only image2d_t dest_data,
      __global FilterParam* param,
	  float opacity,
	  float duration,
	  float enable,//if enable > 0.5, the effect is enabled;
	  float radius,
	  int colorR,
	  int colorG,
	  int colorB,
	  float iMouseX,
	  float iMouseY,
	  float clicked,// it should be used type "bool", but the client only can transimit the type "float".If this variable is set to be">0.5", it shows the mouse is left-clicked. 
	  float process)
{	
	int W = param->width[0];
	int H = param->height[0];
	
	float2 u_resolution = (float2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1))+0.5f;
	vec2 tc = (vec2)(fragCoord.x, fragCoord.y)/u_resolution.xy;
	vec4 orig = INPUT(input1,tc);
	
	float maxSize = u_resolution.x>=u_resolution.y?u_resolution.x:u_resolution.y;
    float rad = radius/1.2f+0.01f;
    vec3 rgb = (vec3)(colorR, colorG, colorB)/255.0f;
    vec4 img = INPUT(input1,tc);
	vec2 iMouse = (vec2)(iMouseX,iMouseY);
    if(enable>0.5f)
    {
		float alpha1;
		float r = length(tc*u_resolution - iMouse.xy)/maxSize;
		 r = r*(100.0f/rad)*(1.0f);
		if(clicked>0.5f)
		{
			float x = process;
			float a = 0.1f+0.1f*x;
			float b = 0.1f+0.3f*x;
			float opacity1; 
			float opacity2;
			if(x > 0.0f&&x<1.0f)
			{
				opacity1 = sin((1.34f*(1.0f-x))*(1.34f*(1.0f-x)+1.0f)); 
				opacity2 = sin((1.34f*x)*(1.34f*x+1.0f));
			}else{
				opacity1 = 0.0f;
				opacity2 = 0.0f;
			}

			if(r<6.28318531f*b)
			{
				float expo=  clamp( (cos(r/a) - 0.1f)*opacity1,0.0f,1.0f) + clamp( (cos(r/b) -0.1f)*opacity2,0.0f,1.0f) ;
				alpha1 = clamp( expo*(0.2f+opacity),0.0f,1.0f);
				img = (vec4)(mix(img.rgb, rgb,alpha1),1.0f);
				
			}
		}
    }
	write_imagef(dest_data, gl_FragCoord, img);
	
}