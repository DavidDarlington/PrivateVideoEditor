// author: RuanShengQiang 
// date: 2017/6/21
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.141592653589f

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;

vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, (vec2)(tc.x, 1.0f - tc.y));
}

float Linear_ease(float begin, float change, float duration, float time) {
    return change * time / duration + begin;
}

float Exponential_easeInOut(float begin, float change, float duration, float time) {
    if (time == 0.0f)
        return begin;
    else if (time == duration)
        return begin + change;
    time = time / (duration / 2.0f);
    if (time < 1.0f)
        return change / 2.0f * pow(2.0f, 10.0f * (time - 1.0f)) + begin;
    return change / 2.0f * (-pow(2.0f, -10.0f * (time - 1.0f)) + 2.0f) + begin;
}

float Sinusoidal_easeInOut(float begin, float change, float duration, float time) {
    return -change / 2.0f * (cos(PI * time / duration) - 1.0f) + begin;
}

/* random number between 0 and 1 */
float random(vec3 scale,float seed, vec3 gl_FragCoord) {
    /* use the fragment position for randomness */
	float temp;
    return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453f + seed,&temp);
}

vec4 crossFade(vec2 uv,float dissolve, __read_only image2d_t input1,__read_only image2d_t input2) {
    return mix(INPUT(input1, uv), INPUT(input2, uv), dissolve);
}


__kernel void MAIN(__read_only image2d_t input1, __read_only image2d_t input2, __write_only image2d_t dstImg,__global FilterParam* param)
{
	float progress = param->cur_time / param->total_time;	int W = param->width[2];	int H = param->height[2];	int w = get_global_id(0);
	int h = get_global_id(1);
	float2 resolution = (float2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 p = ((vec2)(fragCoord.x, fragCoord.y) + (vec2)(0.5f)) /resolution.xy;
	
	vec3 vec3FragCoord = (vec3)(fragCoord,0.0f);
	
	vec2 center = (vec2)(Linear_ease(0.25f, 0.5f, 1.0f, progress), 0.5f);
    float dissolve = Exponential_easeInOut(0.0f, 1.0f, 1.0f, progress);

    // Mirrored sinusoidal loop. 0->strength then strength->0
    float strength = Sinusoidal_easeInOut(0.0f, 0.5f, 0.5f, progress);

    vec4 color = (vec4)(0.0f);
    float total = 0.0f;
    vec2 toCenter = center - p;

    /* randomize the lookup values to hide the fixed number of samples */
    float offset = random((vec3)(12.9898f, 78.233f, 151.7182f), 0.0f,vec3FragCoord);

    for (float t = 0.0f; t <= 10.0f; t += 1.0f) {
        float percent = (t + offset) / 10.0f;
        float weight = 4.0f * (percent - percent * percent);
        color += crossFade(p + toCenter * percent * strength, dissolve,input1,input2) * weight;
        total += weight;
    }
	
	write_imagef(dstImg, (int2)(w, H - h -1), color / total);
}