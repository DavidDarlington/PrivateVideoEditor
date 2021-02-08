#ifdef GL_ES
precision highp float;
#endif


float u_exposure = PREFIX(u_exposure);
float u_brightness = PREFIX(u_brightness);
float u_contrast = PREFIX(u_contrast);
float u_vib = PREFIX(u_vib);
float u_sat = PREFIX(u_sat);

// Exposure functions
//---------------------------------------------------------------------------------------//
vec4 calPowColor(vec4 color, float exposure)
{
	vec4 ret = color * exposure;
	ret.a = color.a;
	ret = clamp(ret, vec4(0.0), vec4(1.0));

	return ret;
}

//---------------------------------------------------------------------------------------//
float luminance(vec3 color)
{
	float fmin = min(min(color.r, color.g), color.b);
	float fmax = max(max(color.r, color.g), color.b);

	return (fmin + fmax) / 2.0;
}

//---------------------------------------------------------------------------------------//
// Brightness functions
//---------------------------------------------------------------------------------------//
float calBrightValue(float bright)
{
	float brightValue = 0.0;

	if (bright > 0.0)
	{
		brightValue = 1.0 + bright / 100.0;
	}
	else
	{		
		brightValue = 1.0 - 1.0 / (0.99 + bright / 253.0);
		//brightValue = ((-255.0)*(1.0 / (0.99 + bright / 253.0) - 1.0));
		brightValue *= 0.6;
	}

	return brightValue;
}

//---------------------------------------------------------------------------------------//
vec4 newBrightness(vec4 color, float bright)
{
	vec4 ret;

	if (bright > 0.0)
		ret = color * bright;
	else
		ret = color + bright;

	ret.a = color.a;
	ret = clamp(ret, vec4(0.0), vec4(1.0));

	return ret;
}

//---------------------------------------------------------------------------------------//
// Contrast functions
//---------------------------------------------------------------------------------------//
vec3 calContrastValue(float contrast)
{
	float contrastValue = 0.0;
	int contrastVal = 0;
	int nHigh = 0;
	int nStretch = 0;
	vec3 ret;

	if (contrast > 0.0)
		contrastValue = 1.0 / (1.0 - contrast / 255.0) - 1.0;
	else
		contrastValue = contrast / 255.0;

    contrastVal = int((contrastValue * 100.0) / 2.0);
	nHigh = 255 - contrastVal;

	if (nHigh < contrastVal)
	{
		nHigh = 127;
		contrastVal = 120;
	}
	if (contrastVal < -127)
		contrastVal = -120;

	if (contrastVal >= 0)
		nStretch = 255 - 2 * contrastVal;
	else
		nStretch = 255 + 2 * contrastVal;

    ret.x = float(contrastVal) / 255.0;
    ret.y = float(nHigh) / 255.0;
    ret.z = float(nStretch) / 255.0;

	return ret;
}

//---------------------------------------------------------------------------------------//
vec4 calContrastColor(vec4 color, float contrastVal, float nHigh, float nStretch)
{
	vec4 ret;

    if (contrastVal > 0.0)
	{
		if (color.r <= contrastVal)
			ret.r = 0.0;
		else if (color.r > nHigh)
			ret.r = 1.0;
		else
			ret.r = (color.r - contrastVal) / nStretch;

		if (color.g <= contrastVal)
			ret.g = 0.0;
		else if (color.g > nHigh)
			ret.g = 1.0;
		else
			ret.g = (color.g - contrastVal) / nStretch;

		if (color.b <= contrastVal)
			ret.b = 0.0;
		else if (color.b > nHigh)
			ret.b = 1.0;
		else
			ret.b = (color.b - contrastVal) / nStretch;
	}
	else
	{
		ret.r = (color.r * nStretch) - contrastVal;
		ret.g = (color.g * nStretch) - contrastVal;
		ret.b = (color.b * nStretch) - contrastVal;
	}

	ret.a = color.a;
	//ret = clamp(ret, vec4(0.0), vec4(1.0));

	return ret;
}

//---------------------------------------------------------------------------------------//
// Vibrance functions
//---------------------------------------------------------------------------------------//
vec4 mixLumaAndColor(vec4 color, float lumaValue, float lumaMask, float vibrance)
{
	vec4 ret;

	float radio = 1.0 + vibrance * lumaMask;
	float repersed = 1.0 - radio;

	ret = color * radio + lumaValue * repersed;
	ret = clamp(ret, vec4(0.0), vec4(1.0));
	ret.a = color.a;

	return ret;
}

//---------------------------------------------------------------------------------------//
// Saturation functions
//---------------------------------------------------------------------------------------//

vec4 calNewColor(vec4 color, float saturation)
{
	float rgbMax = max(color.z, max(color.y, color.x));
	float rgbMin = min(color.z, min(color.y, color.x));
	float delta = rgbMax - rgbMin;

	if (delta == 0.0)
		return color;

	float dValue = rgbMax + rgbMin;
	float L = dValue / 2.0;
	float S = 0.0;

	if (L < 0.5)
		S = delta / dValue;
	else
		S = delta / (2.0 - dValue);

	float alpha = 0.0;
	vec4 ret;

	if (saturation >= 0.0)
	{
		if ((saturation + S) >= 1.0)
			alpha = S;
		else
			alpha = 1.0 - saturation;

		alpha = 1.0 / alpha - 1.0;

		ret.x  = clamp(color.x	 + (color.x	- L ) * alpha, 0.0, 1.0);
		ret.y  = clamp(color.y + (color.y  - L) * alpha, 0.0, 1.0);
		ret.z  = clamp(color.z  + (color.z	- L) * alpha, 0.0, 1.0);
		ret.a = color.a;
	}
	else
	{
		alpha = saturation;

		ret.x		= clamp(L + (color.x   - L ) * (1.0 + alpha), 0.0, 1.0);
		ret.y	= clamp(L + (color.y - L ) * (1.0 + alpha), 0.0, 1.0);
		ret.z		= clamp(L + (color.z  - L ) * (1.0 + alpha), 0.0, 1.0);
		ret.a = color.a;
	}
	return ret;
}

vec4 FUNCNAME(vec2 tc)
{
	vec2 uv = tc;
	vec4 color = INPUT(tc).bgra;
	vec4 retColor = color;

	if (u_exposure != 0.0) // exposure
	{
		float exposureValue = u_exposure / 50.0;
		exposureValue *= 0.6;
		float powValue = pow(2.0, exposureValue);
		vec4 color = retColor;

		retColor = calPowColor(color, powValue);
	}

	if (u_brightness != 0.0) // brightness
	{
		float brightValue = calBrightValue(u_brightness);
		vec4 color = retColor;

		retColor = newBrightness(color, brightValue);
	}

	if (u_contrast != 0.0) // contrast
	{
		vec3 resultVal = calContrastValue(u_contrast);
		vec4 color = retColor;

		retColor = calContrastColor(color, resultVal.x, resultVal.y, resultVal.z);
	}

	if (u_vib != 0.0) // vibrance
	{
		float vibrance = u_vib / 100.0;
		vibrance *= 0.8;
		vec4 color = retColor;
		float luma = luminance(color.rgb);
		vec4 mask = color - luma;
		mask = clamp(mask, vec4(0.0), vec4(1.0));
		float lumaMask = 1.0 - luminance(mask.rgb);

		retColor = mixLumaAndColor(color, luma, lumaMask, vibrance);
	}

	if (u_sat != 0.0) // saturation
	{
		float saturation = u_sat / 200.0;
		vec4 color = retColor;

		retColor = calNewColor(color, saturation);
	}
	//return vec4(0.0,0.0,1.0,1.0);
	return retColor.bgra;
}