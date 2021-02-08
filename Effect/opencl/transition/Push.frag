#ifdef GL_ES
precision highp float;
#endif

#define PI 3.141592653589

// General parameters
float progress = PREFIX(global_time)/PREFIX(total_time);
vec2 resolution = iResolution;

float GetParabolaMap(float t, float T)	
{
	return (3.0 * T * t * t - 2.0 * t * t * t) / (T * T);
}

float GetSinusoidalMap(float t, float T)	
{
	return t - T * sin(2.0 * PI * t / T) / (2.0 * PI);
}

vec4 FUNCNAME(vec2 tc) {

    vec4 fragOutColor=vec4(0.0);
    float iPro = GetSinusoidalMap(progress, 1.0); 	
	iPro = GetParabolaMap(iPro, 1.0) ;
	if(tc.x - iPro > 0.0)
	{
		fragOutColor =  INPUT1(vec2(tc.x - iPro, tc.y));
	}else
	{
		fragOutColor =  INPUT2(vec2(tc.x - iPro + 1.0, tc.y));
	}
    
    return fragOutColor;
}