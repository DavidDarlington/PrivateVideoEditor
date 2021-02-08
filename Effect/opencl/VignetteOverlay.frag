vec4 getTex(vec2 tc)
{
	vec4 color = INPUT2(tc);
    color.r *= 0.90;
	color.g *= 0.96;
	return color;
}
 
vec4 FUNCNAME(vec2 tc) 
{
	vec2 uv = tc;
	float vigAmt = 2.0;
	float vignette = (1.-vigAmt*(uv.y-.5)*(uv.y-.5))*(1.-vigAmt*(uv.x-.5)*(uv.x-.5));
    vec4 color = getTex(tc);
    float diff_vignette = smoothstep(0.2, 0.8,1.0 - vignette);
	//color.rgb = color.rgb * vignette;
    if (diff_vignette > 0.0)
    {
        color.r = mix(color.r, getTex(uv + vec2(0.005,0.0)).r, diff_vignette*2.0);
        color.b = mix(color.b, getTex(uv - vec2(0.005,0.0)).b, diff_vignette*2.0);
    }
    vignette = smoothstep(0.0, 0.7, vignette);
	color.rgb = color.rgb * vignette;
	color.rgb = abs(color.rgb - INPUT1(uv).rgb);
	return mix(INPUT2(tc), color, float(PREFIX(alpha)) / 100.0);
}