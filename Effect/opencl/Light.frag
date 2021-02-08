
#ifdef GL_ES
precision highp float;
#endif

float u_highLight = PREFIX(u_highLight);
float u_shadow = PREFIX(u_shadow);
float u_whiteLevel = PREFIX(u_whiteLevel);
float u_blackLevel = PREFIX(u_blackLevel);

// HighLight & Shadow functions
//---------------------------------------------------------------------------------------//
float enHanceColor(float color, float coff)
{
	float adjust = coff * color;
	float val = 1.0 - (1.0 - adjust) * (1.0 - color);

	return val;
}

//---------------------------------------------------------------------------------------//
vec4 calHighlight(vec4 color, float highLight)
{
	vec4 ret;
	float lumaince = highLight * (max(color.r, max(color.g, color.b)));

	ret.r = enHanceColor(color.r, lumaince);
	ret.g = enHanceColor(color.g, lumaince);
	ret.b = enHanceColor(color.b, lumaince);
	ret.a = color.a;

	ret = clamp(ret, vec4(0.0), vec4(1.0));

	return ret;
}

//---------------------------------------------------------------------------------------//
vec4 calShadow(vec4 color, float shadow)
{
	vec4 ret;
	float lumaince = shadow * (1.0 - max(color.r, max(color.g, color.b)));

	ret.r = enHanceColor(color.r, lumaince);
	ret.g = enHanceColor(color.g, lumaince);
	ret.b = enHanceColor(color.b, lumaince);
	ret.a = color.a;

	ret = clamp(ret, vec4(0.0), vec4(1.0));

	return ret;
}

//---------------------------------------------------------------------------------------//
// HDRWhiteLevel & HDRBlackLevel functions
//---------------------------------------------------------------------------------------//
vec4 calWhiteLevelPixel(vec4 color, float level)
{
	vec4 ret;
	float lumaince = level * (max(color.r, max(color.g, color.b)));

	ret.r = enHanceColor(color.r, lumaince);
	ret.g = enHanceColor(color.g, lumaince);
	ret.b = enHanceColor(color.b, lumaince);

	if (lumaince > 0.0)
	{
		ret.r = enHanceColor(ret.r, lumaince);
		ret.g = enHanceColor(ret.g, lumaince);
		ret.b = enHanceColor(ret.b, lumaince);
	}

	ret.a = color.a;

	ret = clamp(ret, vec4(0.0), vec4(1.0));

	return ret;
}

//---------------------------------------------------------------------------------------//
vec4 calBlackLevelPixel(vec4 color, float level)
{
	vec4 ret;
	float lumaince = level * (1.0 - max(color.r, max(color.g, color.b)));

	ret.r = enHanceColor(color.r, lumaince);
	ret.g = enHanceColor(color.g, lumaince);
	ret.b = enHanceColor(color.b, lumaince);
	ret.a = color.a;

	ret = clamp(ret, vec4(0.0), vec4(1.0));

	return ret;
}

vec4 FUNCNAME(vec2 tc)
{
	 vec2 uv = tc;
	vec4 color = INPUT(tc).bgra;
	vec4 retColor = color;
	vec2 u_resolution = iResolution.xy;
	
	if (u_highLight != 0.0) // highLight
	{
		float coff = u_highLight / 100.0;
		vec4 color = retColor;

		retColor = calHighlight(color, coff);
	}

	if (u_shadow != 0.0) // shadow
	{
		float coff = u_shadow / 100.0;
		if (u_shadow > 0.0)
			coff *= 2.0;
		else
			coff /= 2.0;

		vec4 color = retColor;

		retColor = calShadow(color, coff);
	}

	if (u_whiteLevel != 0.0) // white level
	{
		float whiteCoff = u_whiteLevel / 100.0;
		vec4 color = retColor;

		retColor = calWhiteLevelPixel(color, whiteCoff);
	}

	if (u_blackLevel != 0.0) // black level
	{
		float blackCoff = u_blackLevel / 100.0;

		if (u_blackLevel > 0.0)
			blackCoff /= 2.0;
		else
			blackCoff *= 2.0;

		vec4 color = retColor;

		retColor = calBlackLevelPixel(color, blackCoff);
	}

	return retColor.bgra;
}