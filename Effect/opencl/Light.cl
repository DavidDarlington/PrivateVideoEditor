//---------------------------------------------------------------------------------------//
// Temperature functions
//---------------------------------------------------------------------------------------//

#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.1415926535897932f

float saturate1(float v) { return clamp(v, 0.0f, 1.0f); }
vec2  saturate2(vec2  v) { return clamp(v, (float2)(0.0f), (float2)(1.0f)); }
vec3  saturate3(vec3  v) { return clamp(v, (float3)(0.0f), (float3)(1.0f)); }
vec4  saturate4(vec4  v) { return clamp(v, (float4)(0.0f), (float4)(1.0f)); }

//---------------------------------------------------------------------------------------//
vec3 temperatureToRGB(float temperatureInKelvins)
{
	vec3 retColor;

	temperatureInKelvins = clamp(temperatureInKelvins, 1000.0f, 40000.0f) / 100.0f;

	if (temperatureInKelvins <= 66.0f)
	{
		retColor.x = 1.0f;
		retColor.y = saturate1(0.39008157876901960784f * log(temperatureInKelvins) - 0.63184144378862745098f);
	}
	else
	{
		float t = temperatureInKelvins - 60.0f;
		retColor.x = saturate1(1.29293618606274509804f * pow(t, -0.1332047592f));
		retColor.y = saturate1(1.12989086089529411765f * pow(t, -0.0755148492f));
	}

	if (temperatureInKelvins >= 66.0f)
		retColor.z = 1.0f;
	else if (temperatureInKelvins <= 19.0f)
		retColor.z = 0.0f;
	else
		retColor.z = saturate1(0.54320678911019607843f * log(temperatureInKelvins - 10.0f) - 1.19625408914f);

	return retColor;
}

float _abs(float a)
{
	if(a<0)
		return -a;
	else
		return a;
}
//---------------------------------------------------------------------------------------//
vec3 HSLtoRGB(vec3 HSL)
{
	
	float R = _abs(HSL.x * 6.0f - 3.0f) - 1.0f;
	
	float G = 2.0f - _abs(HSL.x * 6.0f - 2.0f);
	float B = 2.0f - _abs(HSL.x * 6.0f - 4.0f);
	
	vec3 RGB = saturate3((float3)(R, G, B));
	float C = (1.0f - _abs(2.0f * HSL.z - 1.0f)) * HSL.y;
	vec3 temp = (RGB - 0.5f) * C + (float3)(HSL.z);
	return temp;
}

//---------------------------------------------------------------------------------------//
vec3 RGBtoHSL(vec3 RGB)
{
	vec4 P = (RGB.y < RGB.z) ? (float4)(RGB.zy, -1.0f, 2.0f / 3.0f) : (float4)(RGB.yz, 0.0f, -1.0f / 3.0f);
	vec4 Q = (RGB.x < P.x) ? (float4)(P.xyw, RGB.x) : (float4)(RGB.x, P.yzx);
	float C = Q.x - min(Q.w, Q.y);
	float H = _abs((Q.w - Q.y) / (6.0f * C + 1e-10f) + Q.z);
	vec3 HCV = (float3)(H, C, Q.x);
	float L = HCV.z - HCV.y * 0.5f;
	float S = HCV.y / (1.0f - _abs(L * 2.0f - 1.0f) + 1e-10f);

	return (float3)(HCV.x, S, L);
}

//---------------------------------------------------------------------------------------//
float calTemperatureRadio(float temp)
{
	float ratio = 1.0f - (temp) / 11500.0f;
	ratio = _abs(ratio) * 1.7f;

	return ratio;
}

//---------------------------------------------------------------------------------------//
float luminance(vec3 color)
{
	float fmin = min(min(color.x, color.y), color.z);
	float fmax = max(max(color.x, color.y), color.z);

	return (fmin + fmax) / 2.0f;
}

//---------------------------------------------------------------------------------------//
vec3 mixColorAndTmpColor(vec3 orignalColor, vec3 temperateColor, float factor)
{
	vec3 ret;
	float ratio = factor;
	float orignalRatio = 1.0f - ratio;

	ret.x = clamp((orignalColor.x * orignalRatio + temperateColor.x * ratio), 0.0f, 1.0f);
	ret.y = clamp((orignalColor.y * orignalRatio + temperateColor.y * ratio), 0.0f, 1.0f);
	ret.z = clamp((orignalColor.z * orignalRatio + temperateColor.z * ratio), 0.0f, 1.0f);

	return ret;
}

//---------------------------------------------------------------------------------------//
// Tint functions
//---------------------------------------------------------------------------------------//
vec3 calNewTintPixel(vec3 color, float r, float g, float b)
{
	float gray = color.x * 0.3f + color.y * 0.59f + color.z * 0.11f;
	float rr = r * gray + color.x;
	float gg = g * gray + color.y;
	float bb = b * gray + color.z;

	vec3 ret = (float3)(rr, gg, bb);

	return ret;
}

//---------------------------------------------------------------------------------------//
// Exposure functions
//---------------------------------------------------------------------------------------//
vec4 calPowColor(vec4 color, float exposure)
{
	vec4 ret = color * exposure;
	ret.w = color.w;
	ret = clamp(ret, (float4)(0.0f), (float4)(1.0f));

	return ret;
}

//---------------------------------------------------------------------------------------//
// Brightness functions
//---------------------------------------------------------------------------------------//
float calBrightValue(float bright)
{
	float brightValue = 0.0f;

	if (bright > 0.0f)
	{
		brightValue = 1.0f + bright / 100.0f;
	}
	else
	{
		brightValue = 1.0f - 1.0f / (0.99f + bright / 253.0f);
		brightValue *= 0.6f;
	}

	return brightValue;
}

//---------------------------------------------------------------------------------------//
vec4 newBrightness(vec4 color, float bright)
{
	vec4 ret;

	if (bright > 0.0f)
		ret = color * bright;
	else
		ret = color + bright;

	ret.w = color.w;
	ret = clamp(ret, (float4)(0.0f), (float4)(1.0f));

	return ret;
}

//---------------------------------------------------------------------------------------//
// Contrast functions
//---------------------------------------------------------------------------------------//
vec3 calContrastValue(float contrast)
{
	float contrastValue = 0.0f;
	int contrastVal = 0;
	int nHigh = 0;
	int nStretch = 0;
	vec3 ret;

	if (contrast > 0.0f)
		contrastValue = 1.0f / (1.0f - contrast / 255.0f) - 1.0f;
	else
		contrastValue = contrast / 255.0f;

	contrastVal = (int)((contrastValue * 100.0f) / 2.0f);
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

	ret.x = (float)(contrastVal) / 255.0f;
	ret.y = (float)(nHigh) / 255.0f;
	ret.z = (float)(nStretch) / 255.0f;

	return ret;
}

//---------------------------------------------------------------------------------------//
vec4 calContrastColor(vec4 color, float contrastVal, float nHigh, float nStretch)
{
	vec4 ret;

	if (contrastVal > 0.0f)
	{
		if (color.z <= contrastVal)
			ret.z = 0.0f;
		else if (color.z > nHigh)
			ret.z = 1.0f;
		else
			ret.z = (color.z - contrastVal) / nStretch;

		if (color.y <= contrastVal)
			ret.y = 0.0f;
		else if (color.y > nHigh)
			ret.y = 1.0f;
		else
			ret.y = (color.y - contrastVal) / nStretch;

		if (color.x <= contrastVal)
			ret.x = 0.0f;
		else if (color.x > nHigh)
			ret.x = 1.0f;
		else
			ret.x = (color.x - contrastVal) / nStretch;
	}
	else
	{
		ret.z = (color.z * nStretch) - contrastVal;
		ret.y = (color.y * nStretch) - contrastVal;
		ret.x = (color.x * nStretch) - contrastVal;
	}

	ret.w = color.w;
	ret = clamp(ret, (float4)(0.0f), (float4)(1.0f));

	return ret;
}

//---------------------------------------------------------------------------------------//
// Vibrance functions
//---------------------------------------------------------------------------------------//
vec4 mixLumaAndColor(vec4 color, float lumaValue, float lumaMask, float vibrance)
{
	vec4 ret;

	float radio = 1.0f + vibrance * lumaMask;
	float repersed = 1.0f - radio;

	ret = color * radio + lumaValue * repersed;
	ret = clamp(ret, (float4)(0.0f), (float4)(1.0f));
	ret.w = color.w;

	return ret;
}

//---------------------------------------------------------------------------------------//
// Saturation functions
//---------------------------------------------------------------------------------------//
vec4 calNewColor(vec4 color, float saturation)
{
	vec4 ret;

	float average = (color.z + color.y + color.x) / 3.0f;
	float mult = 1.0f - 1.0f / (1.5f - saturation);
	if (saturation > 0.0f)
	{
		ret.z = color.z + (average - color.z) * mult;
		ret.y = color.y + (average - color.y) * mult;
		ret.x = color.x + (average - color.x) * mult;
	}
	else
	{
		ret.z = color.z + (average - color.z) * (-saturation);
		ret.y = color.y + (average - color.y) * (-saturation);
		ret.x = color.x + (average - color.x) * (-saturation);
	}

	ret.w = color.w;
	ret = clamp(ret, (float4)(0.0f), (float4)(1.0f));

	return ret;
}

//---------------------------------------------------------------------------------------//
// HighLight & Shadow functions
//---------------------------------------------------------------------------------------//
float enHanceColor(float color, float coff)
{
	float adjust = coff * color;
	float val = 1.0f - (1.0f - adjust) * (1.0f - color);

	return val;
}

//---------------------------------------------------------------------------------------//
vec4 calHighlight(vec4 color, float highLight)
{
	vec4 ret;
	float lumaince = highLight * (max(color.z, max(color.y, color.x)));

	ret.z = enHanceColor(color.z, lumaince);
	ret.y = enHanceColor(color.y, lumaince);
	ret.x = enHanceColor(color.x, lumaince);
	ret.w = color.w;

	ret = clamp(ret, (float4)(0.0f), (float4)(1.0f));

	return ret;
}

//---------------------------------------------------------------------------------------//
vec4 calShadow(vec4 color, float shadow)
{
	vec4 ret;
	float lumaince = shadow * (1.0f - max(color.z, max(color.y, color.x)));

	ret.z = enHanceColor(color.z, lumaince);
	ret.y = enHanceColor(color.y, lumaince);
	ret.x = enHanceColor(color.x, lumaince);
	ret.w = color.w;

	ret = clamp(ret, (float4)(0.0f), (float4)(1.0f));

	return ret;
}

//---------------------------------------------------------------------------------------//
// HDRWhiteLevel & HDRBlackLevel functions
//---------------------------------------------------------------------------------------//
vec4 calWhiteLevelPixel(vec4 color, float level)
{
	vec4 ret;
	float lumaince = level * (max(color.z, max(color.y, color.x)));

	ret.z = enHanceColor(color.z, lumaince);
	ret.y = enHanceColor(color.y, lumaince);
	ret.x = enHanceColor(color.x, lumaince);

	if (lumaince > 0.0f)
	{
		ret.z = enHanceColor(ret.z, lumaince);
		ret.y = enHanceColor(ret.y, lumaince);
		ret.x = enHanceColor(ret.x, lumaince);
	}

	ret.w = color.w;

	ret = clamp(ret, (float4)(0.0f), (float4)(1.0f));

	return ret;
}

//---------------------------------------------------------------------------------------//
vec4 calBlackLevelPixel(vec4 color, float level)
{
	vec4 ret;
	float lumaince = level * (1.0f - max(color.z, max(color.y, color.x)));

	ret.z = enHanceColor(color.z, lumaince);
	ret.y = enHanceColor(color.y, lumaince);
	ret.x = enHanceColor(color.x, lumaince);
	ret.w = color.w;

	ret = clamp(ret, (float4)(0.0f), (float4)(1.0f));

	return ret;
}

//---------------------------------------------------------------------------------------//
// Vignette functions
//---------------------------------------------------------------------------------------//
float highLightColor(float color, float coff)
{
	float adjust = coff * color;
	float val = 1.0f - (1.0f - adjust) * (1.0f - color);

	return val;
}

//---------------------------------------------------------------------------------------//
float generateGradient(vec2 pos, vec2 center, float featherRatio, float sizeRatio, float roundNess)
{
	float maskVal = 1.0f;
	float a = 0.2f * center.x * (1.0f + 4.0f * sizeRatio);
	float b = 0.2f * center.y * (1.0f + 4.0f * sizeRatio);
	float diff = _abs(a - b) * roundNess;

	if (diff >= 0.0f)
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

	float bandPixel = featherRatio * ((a > b ? a : b) / 2.0f) + 3.0f;
	float arguFactor = (float)(3.14159265358979323846f) / bandPixel;

	float sa = a;
	float sb = b;
	float ea = a + bandPixel;
	float eb = b + bandPixel;

	float dx = _abs(pos.x - center.x);
	float dy = _abs(pos.y - center.y);
	float factor1 = dx / sa;
	float factor2 = dy / sb;
	float factor3 = dx / ea;
	float factor4 = dy / eb;
	float dist1 = factor1 * factor1 + factor2 * factor2 - 1.0f;
	float dist2 = factor3 * factor3 + factor4 * factor4 - 1.0f;

	if (dist1 <= 0.0f)
	{
		maskVal = 1.0f;
	}
	else if (dist2 >= 0.0f)
	{
		maskVal = 0.0f;
	}
	else
	{
		float k = dy / (dx + 0.000001f);

		k *= k;
		float temp = k / (eb * eb) + 1.0f / (ea * ea);
		float xx = 1.0f / temp;
		float yy = k * xx;
		float dist = sqrt(xx + yy) - distance(pos, center);
		dist = bandPixel - dist;

		temp = arguFactor * dist;
		maskVal = 0.5f * (1.0f + cos(temp));
	}

	return maskVal;
}

//---------------------------------------------------------------------------------------//
vec4 vignettePixel(vec4 color, float maskValue, float amountVal, float exposureVal, float highlights)
{
	vec4 ret;

	float R = color.z;
	float G = color.y;
	float B = color.x;

	float outR = (1.0f + amountVal) * R;
	float outG = (1.0f + amountVal) * G;
	float outB = (1.0f + amountVal) * B;

	float factor1 = maskValue * exposureVal;
	float factor2 = maskValue * 2.0f;
	factor2 = factor2 - 1.0f;
	factor2 = 0.5f * (1.0f - factor2);

	R = (float)(R * factor1 + outR * factor2);
	G = (float)(G * factor1 + outG * factor2);
	B = (float)(B * factor1 + outB * factor2);

	if (maskValue < 1.0f)
	{
		float factor = 1.0f - maskValue;
		factor = pow(factor, 2.0f);
		float lumaince = factor * highlights * (1.0f - (R + G + B) / 3.0f);
		R = highLightColor(R, lumaince);
		G = highLightColor(G, lumaince);
		B = highLightColor(B, lumaince);
	}

	ret.z = clamp(R, 0.0f, 1.0f);
	ret.y = clamp(G, 0.0f, 1.0f);
	ret.x = clamp(B, 0.0f, 1.0f);
	ret.w = color.w;

	return ret;
}

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_FILTER_NEAREST;
__kernel  void MAIN(
      __read_only image2d_t src_data,
      __write_only image2d_t dest_data,        //Data in global memory
	  __global FilterParam* param,
		// HighLight parameter
		float u_highLight,
		// Shadow parameter
		float u_shadow,
		// HDR white&black level parameter
		float u_whiteLevel,
		float u_blackLevel	
	 )
{

	int W = param->width[0];
	int H = param->height[0];
	float2 u_resolution = (float2)(W,H);
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 uv = (vec2)(fragCoord.x + 0.5f, fragCoord.y + 0.5f)/u_resolution.xy;
	vec4 color = read_imagef(src_data, sampler, uv).zyxw;
	vec4 retColor = color;
	vec4 origColor = color;
	
	if (u_highLight != 0.0f) // highLight
	{
		float coff = u_highLight / 100.0f;
		vec4 color = retColor;

		retColor = calHighlight(color, coff);
	}

	if (u_shadow != 0.0f) // shadow
	{
		float coff = u_shadow / 100.0f;
		if (u_shadow > 0.0f)
			coff *= 2.0f;
		else
			coff /= 2.0f;

		vec4 color = retColor;

		retColor = calShadow(color, coff);
	}

	if (u_whiteLevel != 0.0f) // white level
	{
		float whiteCoff = u_whiteLevel / 100.0f;
		vec4 color = retColor;

		retColor = calWhiteLevelPixel(color, whiteCoff);
	}

	if (u_blackLevel != 0.0f) // black level
	{
		float blackCoff = u_blackLevel / 100.0f;

		if (u_blackLevel > 0.0f)
			blackCoff /= 2.0f;
		else
			blackCoff *= 2.0f;

		vec4 color = retColor;

		retColor = calBlackLevelPixel(color, blackCoff);
	}

	float resultX0 = param->resultROI[0];
	float resultY0 = param->resultROI[1];
	float resultX1 = param->resultROI[2]+param->resultROI[0];
	float resultY1 = param->resultROI[3]+param->resultROI[1];
	
	float matt = step(resultX0,uv.x)*step(uv.x, resultX1)*step(resultY0,uv.y)*step(uv.y, resultY1);
	
	retColor = origColor*(1.0f - matt)  + retColor*matt; 
	
	write_imagef(dest_data, coordinate, (vec4)(retColor.zyx, color.w));
}
