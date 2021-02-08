
// texture coordinate
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.1415926535897932f

//---------------------------------------------------------------------------------------//
// Sharpen functions
//---------------------------------------------------------------------------------------//

vec4 calColor(vec4 center, vec4 left, vec4 right, vec4 top, vec4 bottom, float amount)
{
	vec4 ret;

	ret.x   = center.x   * 4.0f - left.x   - right.x   - top.x   - bottom.x  ;
	ret.y = center.y * 4.0f - left.y - right.y - top.y - bottom.y;
	ret.z = center.z * 4.0f - left.z - right.z - top.z - bottom.z;

	ret.x   = ret.x   * amount + center.x  ;
	ret.y = ret.y * amount + center.y;
	ret.z = ret.z * amount + center.z;
	ret.w = center.w;

	ret = clamp(ret, (vec4)(0.0f), (vec4)(1.0f));

	return ret;
}

//---------------------------------------------------------------------------------------//
// HSL functions
//---------------------------------------------------------------------------------------//
vec3 HSL_RGBtoHSL(vec3 RGB)
{
	vec3 hsl;
	float R = RGB.x;
	float G = RGB.y;
	float B = RGB.z;
	float Max = 0.0f;
	float Min = 0.0f;
	float H = 0.0f;
	float S = 0.0f;
	float L = 0.0f;

	Min = min(R, min(G, B));
	Max = max(R, max(G, B));

	if (Min == Max)
	{
		H = 2.0f / 3.0f;
		S = 0.0f;
		L = R;
	}
	else
	{
		L = (Max + Min) / 2.0f;

		if (L < 0.5f)
			S = (Max - Min) / (Max + Min);
		else
			S = (Max - Min) / (2.0f - Max - Min);

		if (R == Max)
			H = (G - B) / (Max - Min);
		else if (G == Max)
			H = 2.0f + (B - R) / (Max - Min);
		else
			H = 4.0f + (R - G) / (Max - Min);

		H = H / 6.0f;
		if (H < 0.0f)
			H = H + 1.0f;
	}

	hsl.x = H * 360.0f;
	hsl.y = S;
	hsl.z = L;

	return hsl;
}

//---------------------------------------------------------------------------------------//
vec3 HSL_HSLtoRGB(vec3 HSL)
{
	vec3 RGB;
	float H = HSL.x / 360.0f;
	float S = HSL.y;
	float L = HSL.z;
	float R = 0.0f;
	float G = 0.0f;
	float B = 0.0f;
	float var_1 = 0.0f;
	float var_2 = 0.0f;
	float tempr = 0.0f;
	float tempg = 0.0f;
	float tempb = 0.0f;

	if (S == 0.0f)
	{
		R = G = B = L;
	}
	else
	{
		if (L < 0.5f)
			var_2 = L * (1.0f + S);
		else
			var_2 = (L + S) - (L * S);

		var_1 = 2.0f * L - var_2;

		tempr = H + 1.0f / 3.0f;
		if (tempr > 1.0f)
			tempr = tempr - 1.0f;

		tempg = H;

		tempb = H - 1.0f / 3.0f;
		if (tempb < 0.0f)
			tempb = tempb + 1.0f;

		// Red
		if (tempr < 1.0f / 6.0f)
			R = var_1 + (var_2 - var_1) * 6.0f * tempr;
		else if (tempr < 0.5f)
			R = var_2;
		else if (tempr < 2.0f / 3.0f)
			R = var_1 + (var_2 - var_1) * ((2.0f / 3.0f) - tempr) * 6.0f;
		else
			R = var_1;
		// Green
		if (tempg < 1.0f / 6.0f)
			G = var_1 + (var_2 - var_1) * 6.0f * tempg;
		else if (tempg < 0.5f)
			G = var_2;
		else if (tempg < 2.0f / 3.0f)
			G = var_1 + (var_2 - var_1) * ((2.0f / 3.0f) - tempg) * 6.0f;
		else
			G = var_1;
		// Blue
		if (tempb < 1.0f / 6.0f)
			B = var_1 + (var_2 - var_1) * 6.0f * tempb;
		else if (tempb < 0.5f)
			B = var_2;
		else if (tempb < 2.0f / 3.0f)
			B = var_1 + (var_2 - var_1) * ((2.0f / 3.0f) - tempb) * 6.0f;
		else
			B = var_1;
	}

	RGB.x   = R;
	RGB.y = G;
	RGB.z = B;

	return RGB;
}

//---------------------------------------------------------------------------------------//
float calTransperency(vec3 hsl_Val, float minDegreeVal, float maxDegreeVal)
{
	float adjustRadio = 0.0f;

	if (minDegreeVal > maxDegreeVal)
	{
		if (hsl_Val.x >= minDegreeVal)
		{
			adjustRadio = (hsl_Val.x - minDegreeVal) / (360.0f - minDegreeVal);
		}
		else if (hsl_Val.x <= maxDegreeVal)
		{
			adjustRadio = 1.0f - hsl_Val.x / maxDegreeVal;
		}
		else
		{
			adjustRadio = 0.0f;
		}
	}
	else
	{
		if (hsl_Val.x > minDegreeVal && hsl_Val.x < maxDegreeVal)
		{
			float dist = (hsl_Val.x - minDegreeVal);
			dist = 2.0f * dist / (maxDegreeVal - minDegreeVal);
			if (dist <= 1.0f)
				adjustRadio = dist;
			else
				adjustRadio = 2.0f - dist;
		}
		else
		{
			adjustRadio = 0.0f;
		}
	}

	return adjustRadio;
}

//---------------------------------------------------------------------------------------//
vec3 doAdjustHue(vec3 origColor, vec3 hsl_Val, float alphaVal, float hueVal)
{
	float hueValue = hueVal;
	if (hueValue > 0.0f)
		hueValue *= 1.2f;

	hsl_Val.x += hueValue;

	if (hsl_Val.x < 0.0f)
		hsl_Val.x += 360.0f;

	if (hsl_Val.x > 360.0f)
		hsl_Val.x -= 360.0f;

	vec3 color = HSL_HSLtoRGB(hsl_Val);

	float factor = 1.0f - alphaVal;

	vec3 ret = origColor * factor + color * alphaVal;
	ret = clamp(ret, (vec3)(0.0f), (vec3)(1.0f));

	return ret;
}

//---------------------------------------------------------------------------------------//
vec3 doAdjustStaturation(vec3 origColor, vec3 hsl_Val, float alphaVal, float satRadio)
{
	hsl_Val.y *= (1.0f + satRadio);
	hsl_Val.y = clamp(hsl_Val.y, 0.0f, 1.0f);
	vec3 color = HSL_HSLtoRGB(hsl_Val);

	float factor = 1.0f - alphaVal;

	vec3 ret = origColor * factor + color * alphaVal;
	ret = clamp(ret, (vec3)(0.0f), (vec3)(1.0f));

	return ret;
}

//---------------------------------------------------------------------------------------//
vec3 doAdjustBrightness(vec3 origColor, vec3 hsl_Val, float alphaVal, float brightnessRadio)
{
	hsl_Val.z *= (1.0f + brightnessRadio / 8.0f);
	hsl_Val.z = clamp(hsl_Val.z, 0.0f, 1.0f);
	vec3 color = HSL_HSLtoRGB(hsl_Val);

	float factor = 1.0f - alphaVal;

	vec3 ret = origColor * factor + color * alphaVal;
	ret = clamp(ret, (vec3)(0.0f), (vec3)(1.0f));

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
	float diff = fabs(a - b) * roundNess;

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

	float dx = fabs(pos.x - center.x);
	float dy = fabs(pos.y - center.y);
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

	float R = color.x  ;
	float G = color.y;
	float B = color.z;

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

	ret.x   = clamp(R, 0.0f, 1.0f);
	ret.y = clamp(G, 0.0f, 1.0f);
	ret.z = clamp(B, 0.0f, 1.0f);
	ret.w = color.w;

	return ret;
}
//---------------------------------------------------------------------------------------//
const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_FILTER_NEAREST;
__kernel void MAIN(
      __read_only image2d_t src_data,
      __write_only image2d_t dest_data,        //Data in global memory
	  __global FilterParam* param,
	float Red_degreeMinVal,
	float Red_degreeMaxVal,
	float Red_hueVal,
	float Red_satVal,
	float Red_brightnessVal,
	float Orange_degreeMinVal,
	float Orange_degreeMaxVal,
	float Orange_hueVal,
	float Orange_satVal,
	float Orange_brightnessVal,
	float Yellow_degreeMinVal,
	float Yellow_degreeMaxVal,
	float Yellow_hueVal,
	float Yellow_satVal,
	float Yellow_brightnessVal,
	float Green_degreeMinVal,
	float Green_degreeMaxVal,
	float Green_hueVal,
	float Green_satVal,
	float Green_brightnessVal,
	float Magenta_degreeMinVal,
	float Magenta_degreeMaxVal,
	float Magenta_hueVal,
	float Magenta_satVal,
	float Magenta_brightnessVal,
	float Purple_degreeMinVal,
	float Purple_degreeMaxVal,
	float Purple_hueVal,
	float Purple_satVal,
	float Purple_brightnessVal,
	float Blue_degreeMinVal,
	float Blue_degreeMaxVal,
	float Blue_hueVal,
	float Blue_satVal,
	float Blue_brightnessVal,
	float Aqua_degreeMinVal,
	float Aqua_degreeMaxVal,
	float Aqua_hueVal,
	float Aqua_satVal,
	float Aqua_brightnessVal)
{

	int W = param->width[0];
	int H = param->height[0];
	float2 u_resolution = (float2)(W,H);
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	
	vec2 uv = (vec2)(fragCoord.x + 0.5f, fragCoord.y + 0.5f)/u_resolution.xy;
	vec2 textureCoord = uv; 
	
	vec4 color = read_imagef(src_data, sampler, uv);
	vec4 origColor = color;
	vec4 retColor = color;

	int imageWidth = W ;
	int imageHeight = H;
	
	if (Red_hueVal != 0.0f || Red_satVal != 0.0f || Red_brightnessVal != 0.0f) // Red HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Red_degreeMinVal, Red_degreeMaxVal);
		vec3 newColor;

		if (Red_hueVal != 0.0f)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Red_hueVal);
		else
			newColor = color.rgb;
		
		if (Red_satVal != 0.0f)
		{
			float satRadio = Red_satVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Red_brightnessVal != 0.0f)
		{
			float brightnessRadio = Red_brightnessVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = (vec4)(newColor, color.w);
	}

	if (Orange_hueVal != 0.0f || Orange_satVal != 0.0f || Orange_brightnessVal != 0.0f) // Orange HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Orange_degreeMinVal, Orange_degreeMaxVal);
		vec3 newColor;

		if (Orange_hueVal != 0.0f)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Orange_hueVal);
		else
			newColor = color.rgb;

		if (Orange_satVal != 0.0f)
		{
			float satRadio = Orange_satVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Orange_brightnessVal != 0.0f)
		{
			float brightnessRadio = Orange_brightnessVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = (vec4)(newColor, color.w);
	}

	if (Yellow_hueVal != 0.0f || Yellow_satVal != 0.0f || Yellow_brightnessVal != 0.0f) // Yellow HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Yellow_degreeMinVal, Yellow_degreeMaxVal);
		vec3 newColor;

		if (Yellow_hueVal != 0.0f)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Yellow_hueVal);
		else
			newColor = color.rgb;

		if (Yellow_satVal != 0.0f)
		{
			float satRadio = Yellow_satVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Yellow_brightnessVal != 0.0f)
		{
			float brightnessRadio = Yellow_brightnessVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = (vec4)(newColor, color.w);
	}

	if (Green_hueVal != 0.0f || Green_satVal != 0.0f || Green_brightnessVal != 0.0f) // Green HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Green_degreeMinVal, Green_degreeMaxVal);
		vec3 newColor;

		if (Green_hueVal != 0.0f)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Green_hueVal);
		else
			newColor = color.rgb;

		if (Green_satVal != 0.0f)
		{
			float satRadio = Green_satVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Green_brightnessVal != 0.0f)
		{
			float brightnessRadio = Green_brightnessVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = (vec4)(newColor, color.w);
	}

	if (Magenta_hueVal != 0.0f || Magenta_satVal != 0.0f || Magenta_brightnessVal != 0.0f) // Magenta HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Magenta_degreeMinVal, Magenta_degreeMaxVal);
		vec3 newColor;

		if (Magenta_hueVal != 0.0f)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Magenta_hueVal);
		else
			newColor = color.rgb;

		if (Magenta_satVal != 0.0f)
		{
			float satRadio = Magenta_satVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Magenta_brightnessVal != 0.0f)
		{
			float brightnessRadio = Magenta_brightnessVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = (vec4)(newColor, color.w);
	}

	if (Purple_hueVal != 0.0f || Purple_satVal != 0.0f || Purple_brightnessVal != 0.0f) // Purple HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Purple_degreeMinVal, Purple_degreeMaxVal);
		vec3 newColor;

		if (Purple_hueVal != 0.0f)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Purple_hueVal);
		else
			newColor = color.rgb;

		if (Purple_satVal != 0.0f)
		{
			float satRadio = Purple_satVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Purple_brightnessVal != 0.0f)
		{
			float brightnessRadio = Purple_brightnessVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = (vec4)(newColor, color.w);
	}

	if (Blue_hueVal != 0.0f || Blue_satVal != 0.0f || Blue_brightnessVal != 0.0f) // Blue HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Blue_degreeMinVal, Blue_degreeMaxVal);
		vec3 newColor;

		if (Blue_hueVal != 0.0f)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Blue_hueVal);
		else
			newColor = color.rgb;

		if (Blue_satVal != 0.0f)
		{
			float satRadio = Blue_satVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Blue_brightnessVal != 0.0f)
		{
			float brightnessRadio = Blue_brightnessVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = (vec4)(newColor, color.w);
	}

	if (Aqua_hueVal != 0.0f || Aqua_satVal != 0.0f || Aqua_brightnessVal != 0.0f) // Aqua HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Aqua_degreeMinVal, Aqua_degreeMaxVal);
		vec3 newColor;

		if (Aqua_hueVal != 0.0f)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Aqua_hueVal);
		else
			newColor = color.rgb;

		if (Aqua_satVal != 0.0f)
		{
			float satRadio = Aqua_satVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Aqua_brightnessVal != 0.0f)
		{
			float brightnessRadio = Aqua_brightnessVal / 100.0f;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = (vec4)(newColor, color.w);
	}

	float resultX0 = param->resultROI[0];
	float resultY0 = param->resultROI[1];
	float resultX1 = param->resultROI[2]+param->resultROI[0];
	float resultY1 = param->resultROI[3]+param->resultROI[1];

	float matt = step(resultX0,uv.x)*step(uv.x, resultX1)*step(resultY0,uv.y)*step(uv.y, resultY1);
	
	retColor = origColor*(1.0f - matt)  + retColor*matt; 
	
	write_imagef(dest_data, coordinate, (vec4)(retColor.xyz, color.w));

}
