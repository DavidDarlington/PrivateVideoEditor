
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw

#define M_SQRT1_3_F 0.577350f
#define M_SQRT1_6_F 0.408248f
#define EPSILON			0.03f
#define ZERO_EPS 0.00001f

typedef struct
{
	int width[8];
	int height[8];
	float cur_time;
	float total_time;
	float origROI[4];
	float resultROI[4];
	float angle;
}FilterParam;

static float get_global_id0(__global FilterParam* param)
{
	return get_global_id(0) - (param->origROI[0]* param->width[0]);
}

static float get_global_id1(__global FilterParam* param)
{
	return get_global_id(1) - (param->origROI[1]* param->height[0]);
}
const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;

vec4 INPUTSRC(image2d_t src_data,__global FilterParam* param, vec2 tc)
{
	tc = (vec2)(tc.x, tc.y)*(vec2)(param->origROI[2], param->origROI[3]) + (vec2)(param->origROI[0], param->origROI[1]);
	return read_imagef(src_data, sampler, tc);
}

vec4 INPUT(image2d_t ovelay1,  __global FilterParam* param, vec2 tc)
{
	return read_imagef(ovelay1, sampler, (vec2)(tc.x,tc.y) );
}
vec3 rgb2lms(vec3 rgb){
    vec3 lms;
    lms.x = 0.0402f * rgb.z + 0.5783f * rgb.y + 0.3811f * rgb.x;
    lms.y = 0.0782f * rgb.z + 0.7244f * rgb.y + 0.1967f * rgb.x;
    lms.z = 0.8444f * rgb.z + 0.1288f * rgb.y + 0.0241f * rgb.x;
    return lms;
}
vec3 lms2lab(vec3 lms){
    vec3 lab;
    lab.x = M_SQRT1_3_F*(lms.x + lms.y + lms.z);
    lab.y = M_SQRT1_6_F*(lms.x + lms.y) -2.0f * M_SQRT1_6_F * lms.z;
    lab.z = M_SQRT1_2_F*(lms.x - lms.y);
    return lab;
}
vec3 lab2lms(vec3 lab){
    vec3 lms;
    lms.x = M_SQRT1_3_F * lab.x + M_SQRT1_6_F * lab.y + M_SQRT1_2_F * lab.z;
    lms.y = M_SQRT1_3_F * lab.x + M_SQRT1_6_F * lab.y - M_SQRT1_2_F * lab.z;
    lms.z = M_SQRT1_3_F * lab.x - 2.0f * M_SQRT1_6_F * lab.y ;
    return lms;
}
vec3 lms2rgb(vec3 lms){
    vec3 rgb;
    rgb.z = 0.0497f * lms.x-0.2439f*lms.y+ 1.2045f*lms.z;
    rgb.y = -1.2186f * lms.x+2.3809f*lms.y-0.1624f*lms.z;
    rgb.x = 4.4679f * lms.x-3.5873f*lms.y+0.1193f*lms.z;
    return rgb;
}
__kernel  void MAIN(
      __read_only image2d_t src_data,
      __write_only image2d_t dest_data,        
	  __global FilterParam* param,	
		float mean_b,
		float mean_g,
		float mean_r,
		float stddb,
        float stddg,
        float stddr,
        int strength,
        float mean_b1,
		float mean_g1,
		float mean_r1,
		float stddb1,
        float stddg1,
        float stddr1
	 )
{

	int W = get_global_size(0);
	int H = get_global_size(1);
	int textH = param->height[0];;
	
	int w = get_global_id(0);
	int h = get_global_id(1);
	float2 resolution = (float2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id0( param), get_global_id1( param));
	vec2 tc = ((vec2)(fragCoord.x, fragCoord.y) + (vec2)(0.5f))/resolution.xy;
	vec4 orig = INPUTSRC(src_data, param, tc);
    vec3 orig_rgb = orig.xyz;
    vec3 lms = rgb2lms(orig_rgb);
    vec3 min_mat = (vec3)(EPSILON,EPSILON,EPSILON);
	vec3 img_lms = fmax(lms,min_mat);
    img_lms=log2(img_lms);
    vec3 log_10 = (vec3)(log2(10.0f));
	img_lms = img_lms/log_10;
    vec3 img_lab = lms2lab(img_lms);

    vec3 koef = (vec3)(stddb / stddb1, stddg / stddg1, stddr / stddr1);
	
	if(stddb1 < ZERO_EPS)
		koef.x = 1.0f;
	if(stddg1 < ZERO_EPS)
		koef.y = 1.0f;
	if(stddr1 < ZERO_EPS)
		koef.z = 1.0f;
		
	koef.xyz = clamp(koef.xyz,0.0f,1.5f);
    vec3 mean_src = (vec3)(mean_b1,mean_g1,mean_r1);
    vec3 mean_tg = (vec3)(mean_b, mean_g, mean_r);

    img_lab = (img_lab - mean_src)* koef;
    vec3 result = img_lab + mean_tg;
	img_lms = lab2lms(result);

	img_lms=exp(img_lms);
	img_lms = pow(img_lms, log(10.0f));
    vec3 img_rgb = lms2rgb(img_lms);
    float alpha = (float)(strength)/100.0f;
	vec3 outColor = mix(orig_rgb, img_rgb, alpha);
	outColor = clamp(outColor,0.0f,1.0f);
	vec4 retColor = (vec4)(outColor.x,outColor.y,outColor.z,orig.w);
	write_imagef(dest_data, gl_FragCoord, retColor);
}

__kernel void transform(
    __read_only image2d_t src_data,
    __write_only image2d_t dest_data,
	  __global FilterParam* param
    )
{
    int W = get_global_size(0);
	int H = get_global_size(1);
	int textH = param->height[0];;
	
	int w = get_global_id(0);
	int h = get_global_id(1);
	float2 resolution = (float2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id0( param), get_global_id1( param));
	vec2 tc = ((vec2)(fragCoord.x, fragCoord.y) + (vec2)(0.5f))/resolution.xy;
	vec4 orig = INPUTSRC(src_data, param, tc);
    vec3 orig_rgb = orig.xyz;
    vec3 lms = rgb2lms(orig_rgb);
    vec3 min_mat = (vec3)(EPSILON,EPSILON,EPSILON);
	vec3 img_lms = fmax(lms,min_mat);
    img_lms=log2(img_lms);
    vec3 log_10 = (vec3)(log2(10.0f));
	img_lms = img_lms/log_10;
    vec3 img_lab = lms2lab(img_lms);
    vec4 retColor = (vec4)(img_lab.zyx,1.0f);
    write_imagef(dest_data,gl_FragCoord,retColor);
}