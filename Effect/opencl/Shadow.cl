/*{
	"GUID":"D4A1FDF7-FD14-490e-8D29-177AEC4DED39"
}*/

#define MAKE_GREY_EASY(b, g, r) (((b) + (g) + (g) + (r)) / 4.0f)
#define AmMAX(a, b) ((a) < (b) ? (b) : (a))
#define AmMAX3(a, b, c) AmMAX(AmMAX(a, b), c)
#define ChannelBlend_Overlay(B,L) ((B) < 128.0f) ? ((B) * (L) / 128.0f ): (255.0f - (((255.0f - (B)) * (255.0f - (L))) / 128.0f)) 

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_FILTER_LINEAR;
#define vec2 float2
#define vec3 float3
#define vec4 float4

vec4 INPUT(image2d_t input1, vec2 tc)
{
	return read_imagef(input1, sampler, tc);
}

__kernel void MAIN(__read_only image2d_t input1,__write_only image2d_t dest_data, __global FilterParam* param)
{
	int W = param->width[0];
	int H = param->height[0];
	float iGlobalTime = param->cur_time / param->total_time;
	
	int w = get_global_id(0);
	int h = get_global_id(1);
	float2 iResolution = (float2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 tc = (vec2)(fragCoord.x, fragCoord.y)/iResolution.xy;
	
    vec4 top0 = INPUT(input1,(vec2)(fragCoord.x, fragCoord.y + 1.0f)/iResolution.xy) * (vec4)(255.0f);
    vec4 top1 = INPUT(input1,(vec2)(fragCoord.x + 1.0f, fragCoord.y + 1.0f)/iResolution.xy) * (vec4)(255.0f);
	
    vec4 top2 = INPUT(input1,(vec2)(fragCoord.x + 2.0f, fragCoord.y + 1.0f)/iResolution.xy) * (vec4)(255.0f);
    
    float ntop0 = MAKE_GREY_EASY(top0.x, top0.y, top0.z);
    float ntop1 = MAKE_GREY_EASY(top1.x, top1.y, top1.z);
    float ntop2 = MAKE_GREY_EASY(top2.x, top2.y, top2.z);
    
    vec4 mid0 = INPUT(input1,(vec2)(fragCoord.x, fragCoord.y)/iResolution.xy) * (vec4)(255.0f);
    vec4 mid1 = INPUT(input1,(vec2)(fragCoord.x + 1.0f, fragCoord.y)/iResolution.xy) * (vec4)(255.0f);
    vec4 mid2 = INPUT(input1,(vec2)(fragCoord.x + 2.0f, fragCoord.y)/iResolution.xy) * (vec4)(255.0f);
    
    float nmid0 = MAKE_GREY_EASY(mid0.x, mid0.y, mid0.z);
    float nmid1 = MAKE_GREY_EASY(mid1.x, mid1.y, mid1.z);
    float nmid2 = MAKE_GREY_EASY(mid2.x, mid2.y, mid2.z);
   
    vec4 bom0 = INPUT(input1,(vec2)(fragCoord.x, fragCoord.y - 1.0f)/iResolution.xy) * (vec4)(255.0f);
    vec4 bom1 = INPUT(input1,(vec2)(fragCoord.x + 1.0f, fragCoord.y - 1.0f)/iResolution.xy) * (vec4)(255.0f);
    vec4 bom2 = INPUT(input1,(vec2)(fragCoord.x + 2.0f, fragCoord.y - 1.0f)/iResolution.xy) * (vec4)(255.0f);
    
    float nbom0 = MAKE_GREY_EASY(bom0.x, bom0.y, bom0.z);
    float nbom1 = MAKE_GREY_EASY(bom1.x, bom1.y, bom1.z);
    float nbom2 = MAKE_GREY_EASY(bom2.x, bom2.y, bom2.z);
    
    float value1 = AmMAX3(ntop0, ntop1, ntop2);
    float value2 = AmMAX3(nmid0, nmid1, nmid2);
    float value3 = AmMAX3(nbom0, nbom1, nbom2);
    
    value1 = AmMAX3(value1, value2, value3);
    float tmp =  (nmid0 * (16777216.0f / (value1 + 8.0f))) / 65536.0f;
    value2 = min(tmp, 255.0f);
    value3 = ChannelBlend_Overlay(value2,nmid0);
	
	write_imagef(dest_data, gl_FragCoord, (vec4)(value3/255.0f, value3/255.0f, value3/255.0f, 1.0f) ); 
}
