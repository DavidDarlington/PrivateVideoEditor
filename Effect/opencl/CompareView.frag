#ifdef GL_ES
precision highp float;
#endif

int mode = PREFIX(mode);

vec2 scale(vec2 tc, vec2 scale, vec2 center)
{
    return (tc - center)*scale + center;
}

vec4 FUNCNAME(vec2 tc)
{
	vec4 color1 = INPUT1(tc);
	vec4 color2 = INPUT2(tc);
	vec2 fgRes = eff0_resolution.xy; 
	
	if (mode == 0) // Left/Right
		if (tc.x <= 0.5)
			return color1;
		else
			return color2;
	else if (mode == 1)
		if (tc.y <= 0.5)
			return color2;
		else
			return color1;
	
	if (tc.x <= 0.5)
	{
		tc.x = tc.x  * 2.0;
        vec2 cc = scale(tc, vec2(1.0, 2.0), vec2(0.5,0.5));
		float matt = step(0.0, cc.x) * step(cc.x, 1.0) * step(0.0, cc.y) * step(cc.y, 1.0);
		return  INPUT1(cc)*matt;
	}else
    {
        tc.x = (tc.x - 0.5)  * 2.0;
		vec2 cc = scale(tc, vec2(1.0, 2.0), vec2(0.5,0.5));
		float matt = step(0.0, cc.x) * step(cc.x, 1.0) * step(0.0, cc.y) * step(cc.y, 1.0);
		return  INPUT2(cc)*matt;
    }
}




  
