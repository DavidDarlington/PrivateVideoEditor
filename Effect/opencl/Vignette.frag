
#ifdef GL_ES
precision highp float;
#endif

float u_vignette_amount = PREFIX(amount);
float u_vignette_feather = PREFIX(feather);
float u_vignette_highlights = PREFIX(highlights);
float u_vignette_size = PREFIX(size);
float u_vignette_roundness = PREFIX(roundness);
float u_vignette_exposure = PREFIX(exposure);

//---------------------------------------------------------------------------------------//
// Vignette functions
//---------------------------------------------------------------------------------------//
float highLightColor(float color, float coff)
{
	float adjust = coff * color;
	float val = 1.0 - (1.0 - adjust) * (1.0 - color);

	return val;
}

//---------------------------------------------------------------------------------------//
float generateGradient(vec2 pos, vec2 center, float featherRatio, float sizeRatio, float roundNess)
{
	float maskVal = 1.0;
	float a = 0.2 * center.x * (1.0 + 4.0 * sizeRatio);
	float b = 0.2 * center.y * (1.0 + 4.0 * sizeRatio);
	float diff = abs(a - b) * roundNess;

	if (diff >= 0.0)
	{
		if (a > b)
			a -= diff;
		else if (a == b)
		{
			a = a;
			b = b;
		}
		else
			b -= diff;
	}

	float bandPixel = featherRatio * ((a > b ? a : b) / 2.0) + 3.0;
	float arguFactor = float(3.14159265358979323846) / bandPixel;

	float sa = a;
	float sb = b;
	float ea = a + bandPixel;
	float eb = b + bandPixel;

	float dx = abs(pos.x - center.x);
	float dy = abs(pos.y - center.y);
	float factor1 = dx / sa;
	float factor2 = dy / sb;
	float factor3 = dx / ea;
	float factor4 = dy / eb;
	float dist1 = factor1 * factor1 + factor2 * factor2 - 1.0;
	float dist2 = factor3 * factor3 + factor4 * factor4 - 1.0;

	if (dist1 <= 0.0)
	{
		maskVal = 1.0;
	}
	else if (dist2 >= 0.0)
	{
		maskVal = 0.0;
	}
	else
	{
		float k = dy / (dx + 0.000001);

		k *= k;
		float temp = k / (eb * eb) + 1.0 / (ea * ea);
		float xx = 1.0 / temp;
		float yy = k * xx;
		float dist = sqrt(xx + yy) - distance(pos, center);
		dist = bandPixel - dist;

		temp = arguFactor * dist;
		maskVal = 0.5 * (1.0 + cos(temp));
	}

	return maskVal;
}

//---------------------------------------------------------------------------------------//
vec4 vignettePixel(vec4 color, float maskValue, float amountVal, float exposureVal, float highlights)
{
	vec4 ret;

	float R = color.r;
	float G = color.g;
	float B = color.b;

	float outR = (1.0 + amountVal) * R;
	float outG = (1.0 + amountVal) * G;
	float outB = (1.0 + amountVal) * B;

	float factor1 = maskValue * exposureVal;
	float factor2 = maskValue * 2.0;
	factor2 = factor2 - 1.0;
	factor2 = 0.5 * (1.0 - factor2);

	R = float(R * factor1 + outR * factor2);
	G = float(G * factor1 + outG * factor2);
	B = float(B * factor1 + outB * factor2);

	if (maskValue < 1.0)
	{
		float factor = 1.0 - maskValue;
		factor = pow(factor, 2.0);
		float lumaince = factor * highlights * (1.0 - (R + G + B) / 3.0);
		R = highLightColor(R, lumaince);
		G = highLightColor(G, lumaince);
		B = highLightColor(B, lumaince);
	}

	ret.r = clamp(R, 0.0, 1.0);
	ret.g = clamp(G, 0.0, 1.0);
	ret.b = clamp(B, 0.0, 1.0);
	ret.a = color.a;

	return ret;
}

vec4 FUNCNAME(vec2 tc)
{
	 vec2 uv = tc;
	vec4 color = INPUT(tc).bgra;
	vec4 retColor = color;
	vec2 u_resolution = iResolution.xy;
	
	if (u_vignette_amount != 0.0 || u_vignette_exposure != 0.0)
	{
		float amountRatio = u_vignette_amount / 100.0;
		float featherRatio = u_vignette_feather / 100.0;
		float coffHighlight = u_vignette_highlights / 100.0;
		float sizeRatio = u_vignette_size / 100.0;
		float roundRatio = u_vignette_roundness / 100.0;
		float exposureRatio = u_vignette_exposure / 100.0;
		vec2 position;
		vec2 center;

		coffHighlight = (2.0 * coffHighlight - 1.0) * abs(amountRatio);
		exposureRatio = pow(2.0, exposureRatio);

		position.x = uv.x * float(u_resolution.x);
		position.y = uv.y * float(u_resolution.y);

		center.x = float(u_resolution.x / 2.);
		center.y = float(u_resolution.y / 2.);

		float maskValue = generateGradient(position, center, featherRatio, sizeRatio, roundRatio);

		vec4 color = retColor;

		retColor = vignettePixel(color, maskValue, amountRatio, exposureRatio, coffHighlight);
	}

	return retColor.bgra;
}