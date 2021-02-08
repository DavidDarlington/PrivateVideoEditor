
#ifdef GL_ES
precision highp float;
#endif

float temperature = PREFIX(u_temperature)/200.0;
float tint = PREFIX(u_tint)/200.0;
int bEnableWB = PREFIX(bEnableWB);
float u_rgain = PREFIX(u_rgain);
float u_ggain = PREFIX(u_ggain);
float u_bgain = PREFIX(u_bgain);

int bEnableLUT = PREFIX(bEnableLUT);
int lutDim = PREFIX(lutDim);
int lutCol = PREFIX(lutCol);
int lutRow = PREFIX(lutRow);

int bEnableColor = PREFIX(bEnableColor);
float u_exposure = PREFIX(u_exposure);
float u_brightness = PREFIX(u_brightness);
float u_contrast = PREFIX(u_contrast);
float u_vib = PREFIX(u_vib);
float u_sat = PREFIX(u_sat);

int bEnableLight = PREFIX(bEnableLight);
float u_highLight = PREFIX(u_highLight);
float u_shadow = PREFIX(u_shadow);
float u_whiteLevel = PREFIX(u_whiteLevel);
float u_blackLevel = PREFIX(u_blackLevel);

int bEnableHSL = PREFIX(bEnableHSL);
float Red_degreeMinVal = PREFIX(Red_degreeMinVal);
float Red_degreeMaxVal = PREFIX(Red_degreeMaxVal);
float Red_hueVal = PREFIX(Red_hueVal);
float Red_satVal = PREFIX(Red_satVal);
float Red_brightnessVal = PREFIX(Red_brightnessVal);

float Orange_degreeMinVal = PREFIX(Orange_degreeMinVal);
float Orange_degreeMaxVal = PREFIX(Orange_degreeMaxVal);
float Orange_hueVal = PREFIX(Orange_hueVal);
float Orange_satVal = PREFIX(Orange_satVal);
float Orange_brightnessVal = PREFIX(Orange_brightnessVal);

float Yellow_degreeMinVal = PREFIX(Yellow_degreeMinVal);
float Yellow_degreeMaxVal = PREFIX(Yellow_degreeMaxVal);
float Yellow_hueVal = PREFIX(Yellow_hueVal);
float Yellow_satVal = PREFIX(Yellow_satVal);
float Yellow_brightnessVal = PREFIX(Yellow_brightnessVal);

float Green_degreeMinVal = PREFIX(Green_degreeMinVal);
float Green_degreeMaxVal = PREFIX(Green_degreeMaxVal);
float Green_hueVal = PREFIX(Green_hueVal);
float Green_satVal = PREFIX(Green_satVal);
float Green_brightnessVal = PREFIX(Green_brightnessVal);

float Magenta_degreeMinVal = PREFIX(Magenta_degreeMinVal);
float Magenta_degreeMaxVal = PREFIX(Magenta_degreeMaxVal);
float Magenta_hueVal = PREFIX(Magenta_hueVal);
float Magenta_satVal = PREFIX(Magenta_satVal);
float Magenta_brightnessVal = PREFIX(Magenta_brightnessVal);

float Purple_degreeMinVal = PREFIX(Purple_degreeMinVal);
float Purple_degreeMaxVal = PREFIX(Purple_degreeMaxVal);
float Purple_hueVal = PREFIX(Purple_hueVal);
float Purple_satVal = PREFIX(Purple_satVal);
float Purple_brightnessVal = PREFIX(Purple_brightnessVal);

float Blue_degreeMinVal = PREFIX(Blue_degreeMinVal);
float Blue_degreeMaxVal = PREFIX(Blue_degreeMaxVal);
float Blue_hueVal = PREFIX(Blue_hueVal);
float Blue_satVal = PREFIX(Blue_satVal);
float Blue_brightnessVal = PREFIX(Blue_brightnessVal);

float Aqua_degreeMinVal = PREFIX(Aqua_degreeMinVal);
float Aqua_degreeMaxVal = PREFIX(Aqua_degreeMaxVal);
float Aqua_hueVal = PREFIX(Aqua_hueVal);
float Aqua_satVal = PREFIX(Aqua_satVal);
float Aqua_brightnessVal = PREFIX(Aqua_brightnessVal);

int bEnableVignette = PREFIX(bEnableVignette);
float u_vignette_amount = PREFIX(amount);
float u_vignette_feather = PREFIX(feather);
float u_vignette_highlights = PREFIX(highlights);
float u_vignette_size = PREFIX(size);
float u_vignette_roundness = PREFIX(roundness);
float u_vignette_exposure = PREFIX(exposure);
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
		brightValue = ((-255.0)*(1.0 / (0.99 + bright / 253.0) - 1.0));
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

		ret.x = clamp(color.x	 + (color.x	- L ) * alpha, 0.0, 1.0);
		ret.y = clamp(color.y + (color.y  - L) * alpha, 0.0, 1.0);
		ret.z = clamp(color.z  + (color.z	- L) * alpha, 0.0, 1.0);
		ret.a = color.a;
	}
	else
	{
		alpha = saturation;
		ret.x= clamp(L + (color.x  - L ) * (1.0 + alpha), 0.0, 1.0);
		ret.y= clamp(L + (color.y - L ) * (1.0 + alpha), 0.0, 1.0);
		ret.z= clamp(L + (color.z  - L ) * (1.0 + alpha), 0.0, 1.0);
		ret.a = color.a;
	}
	return ret;
}
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
vec3 HSL_RGBtoHSL(vec3 RGB)
{
	vec3 hsl;
	float R = RGB.r;//
	float G = RGB.g;
	float B = RGB.b;
	float Max = 0.0;
	float Min = 0.0;
	float H = 0.0;
	float S = 0.0;
	float L = 0.0;

	Min = min(R, min(G, B));
	Max = max(R, max(G, B));

	if (Min == Max)
	{
		H = 2.0 / 3.0;
		S = 0.0;
		L = R;
	}
	else
	{
		L = (Max + Min) / 2.0;

		if (L < 0.5)
			S = (Max - Min) / (Max + Min);
		else
			S = (Max - Min) / (2.0 - Max - Min);

		if (R == Max)
			H = (G - B) / (Max - Min);
		else if (G == Max)
			H = 2.0 + (B - R) / (Max - Min);
		else
			H = 4.0 + (R - G) / (Max - Min);

		H /= 6.0;
		if (H < 0.0)
			H += 1.0;
	}

	hsl.x = H * 360.0;
	hsl.y = S;
	hsl.z = L;

	return hsl;
}

//---------------------------------------------------------------------------------------//
vec3 HSL_HSLtoRGB(vec3 HSL)
{
	vec3 RGB;
	float H = HSL.x / 360.0;
	float S = HSL.y;
	float L = HSL.z;
	float R = 0.0;
	float G = 0.0;
	float B = 0.0;
	float var_1 = 0.0;
	float var_2 = 0.0;
	float tempr = 0.0;
	float tempg = 0.0;
	float tempb = 0.0;

	if (S == 0.0)
	{
		R = G = B = L;
	}
	else
	{
		if (L < 0.5)
			var_2 = L * (1.0 + S);
		else
			var_2 = (L + S) - (L * S);

		var_1 = 2.0 * L - var_2;

		tempr = H + 1.0 / 3.0;
		if (tempr > 1.0)
			tempr--;

		tempg = H;

		tempb = H - 1.0 / 3.0;
		if (tempb < 0.0)
			tempb++;

		// Red
		if (tempr < 1.0 / 6.0)
			R = var_1 + (var_2 - var_1) * 6.0 * tempr;
		else if (tempr < 0.5)
			R = var_2;
		else if (tempr < 2.0 / 3.0)
			R = var_1 + (var_2 - var_1) * ((2.0 / 3.0) - tempr) * 6.0;
		else
			R = var_1;
		// Green
		if (tempg < 1.0 / 6.0)
			G = var_1 + (var_2 - var_1) * 6.0 * tempg;
		else if (tempg < 0.5)
			G = var_2;
		else if (tempg < 2.0 / 3.0)
			G = var_1 + (var_2 - var_1) * ((2.0 / 3.0) - tempg) * 6.0;
		else
			G = var_1;
		// Blue
		if (tempb < 1.0 / 6.0)
			B = var_1 + (var_2 - var_1) * 6.0 * tempb;
		else if (tempb < 0.5)
			B = var_2;
		else if (tempb < 2.0 / 3.0)
			B = var_1 + (var_2 - var_1) * ((2.0 / 3.0) - tempb) * 6.0;
		else
			B = var_1;
	}

	RGB.r = R;
	RGB.g = G;
	RGB.b = B;

	return RGB;
}

//---------------------------------------------------------------------------------------//
float calTransperency(vec3 hsl_Val, float minDegreeVal, float maxDegreeVal)
{
	float adjustRadio = 0.0;

	if (minDegreeVal > maxDegreeVal)
	{
		if (hsl_Val.x >= minDegreeVal)
		{
			adjustRadio = (hsl_Val.x - minDegreeVal) / (360.0 - minDegreeVal);
		}
		else if (hsl_Val.x <= maxDegreeVal)
		{
			adjustRadio = 1.0 - hsl_Val.x / maxDegreeVal;
		}
		else
		{
			adjustRadio = 0.0;
		}
	}
	else
	{
		if (hsl_Val.x > minDegreeVal && hsl_Val.x < maxDegreeVal)
		{
			float dist = (hsl_Val.x - minDegreeVal);
			dist = 2.0 * dist / (maxDegreeVal - minDegreeVal);
			if (dist <= 1.0)
				adjustRadio = dist;
			else
				adjustRadio = 2.0 - dist;
		}
		else
		{
			adjustRadio = 0.0;
		}
	}

	return adjustRadio;
}
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
vec2 calculateUV(vec2 uv,vec2 ratio,vec2 resolution){	
	uv+=0.5;
	uv=uv.xy/ratio.xy;	
	uv-=0.5;
	uv=uv.xy/resolution.xy;
	return uv;
}
vec4 FUNCNAME(vec2 tc)
{
	vec2 uv = tc;
	vec4 color = INPUT1(tc);
	
	// vec4 red=vec4(0.0,0.0,1.0,1.0);//bgra
	// return red;
	vec4 retColor = color.xyza;
	vec2 u_resolution = iResolution.xy;
	//int L = 1;
	float deltaR = 1.0+tint / 2.0 + temperature;
	float deltaB = 1.0+tint / 2.0 - temperature;
	float deltaG = 1.0 - tint;
	vec4 OutColor=retColor.xyza;
	//WhiteBalance
	if(bEnableWB==1){
		OutColor.x=OutColor.x*deltaB;
		OutColor.y=OutColor.y*deltaG;
		OutColor.z=OutColor.z*deltaR;
		OutColor=clamp(OutColor, vec4(0.0), vec4(1.0));
	}	
	if(bEnableLUT==1){		
		

		//lutDim=32;
		//lutRow=4;
		//lutCol=8;
		float blueColor = OutColor.r * (lutRow * lutCol - 1.0);
	
		vec2 quad1;
		quad1.y = floor(floor(blueColor) / lutCol);
		quad1.x = floor(blueColor) - (quad1.y * lutCol);
		
		vec2 quad2;
		quad2.y = floor(ceil(blueColor) / lutCol);
		quad2.x = ceil(blueColor) - (quad2.y * lutCol);
		
		float xOff = 1.0 / lutCol;
		float yOff = 1.0 / lutRow;
		float tex_w = lutDim * lutCol;
		float tex_h = lutDim * lutRow;
		
		vec2 texPos1;
		texPos1.x = (quad1.x * xOff) + 0.5 / tex_w + ((xOff - 1.0 / tex_w) * OutColor.b);
		texPos1.y = (quad1.y * yOff) + 0.5 / tex_h + ((yOff - 1.0 / tex_h) * OutColor.g);
		
		vec2 texPos2;
		texPos2.x = (quad2.x * xOff) + 0.5 / tex_w + ((xOff - 1.0 / tex_w) * OutColor.b);
		texPos2.y = (quad2.y * yOff) + 0.5 / tex_h + ((yOff - 1.0 / tex_h) * OutColor.g);
		
		vec4 newColor1 = INPUT2(texPos1);
		vec4 newColor2 = INPUT2(texPos2);
		
		OutColor = mix(newColor1, newColor2, fract(blueColor));
		
	}
	if(bEnableColor==1){
		if (u_exposure != 0.0) // exposure
			{
				float exposureValue = u_exposure / 50.0;
				exposureValue *= 0.6;
				float powValue = pow(2.0, exposureValue);
				vec4 color = OutColor;

				OutColor = calPowColor(color, powValue);
			}

			if (u_brightness != 0.0) // brightness
			{
				float brightValue = calBrightValue(u_brightness);
				vec4 color = OutColor;

				OutColor = newBrightness(color, brightValue);
			}

			if (u_contrast != 0.0) // contrast
			{
				vec3 resultVal = calContrastValue(u_contrast);
				vec4 color = OutColor;

				OutColor = calContrastColor(color, resultVal.x, resultVal.y, resultVal.z);
			}

			if (u_vib != 0.0) // vibrance
			{
				float vibrance = u_vib / 100.0;
				vibrance *= 0.8;
				vec4 color = OutColor;
				float luma = luminance(color.rgb);
				vec4 mask = color - luma;
				mask = clamp(mask, vec4(0.0), vec4(1.0));
				float lumaMask = 1.0 - luminance(mask.rgb);

				OutColor = mixLumaAndColor(color, luma, lumaMask, vibrance);
			}

			if (u_sat != 0.0) // saturation
			{
				float saturation = u_sat / 100.0;
				vec4 color = OutColor;

				OutColor = calNewColor(color, saturation);
			}


	}
	if(bEnableLight==1){
		if (u_highLight != 0.0) // highLight
		{
			float coff = u_highLight / 100.0;
			vec4 color = OutColor;

			OutColor = calHighlight(color, coff);
		}

		if (u_shadow != 0.0) // shadow
		{
			float coff = u_shadow / 100.0;
			if (u_shadow > 0.0)
				coff *= 2.0;
			else
				coff /= 2.0;

			vec4 color = OutColor;

			OutColor = calShadow(color, coff);
		}

		if (u_whiteLevel != 0.0) // white level
		{
			float whiteCoff = u_whiteLevel / 100.0;
			vec4 color = OutColor;

			OutColor = calWhiteLevelPixel(color, whiteCoff);
		}

		if (u_blackLevel != 0.0) // black level
		{
			float blackCoff = u_blackLevel / 100.0;

			if (u_blackLevel > 0.0)
				blackCoff /= 2.0;
			else
				blackCoff *= 2.0;

			vec4 color = OutColor;

			OutColor = calBlackLevelPixel(color, blackCoff);
		}
	}
	if(bEnableHSL==1){
		if (Red_hueVal > 0.0)
		Red_hueVal *= 1.2;

		Red_satVal *= 0.01;
		Red_brightnessVal *= 0.00125;

		if (Orange_hueVal > 0.0)
			Orange_hueVal *= 1.2;

		Orange_satVal *= 0.01;
		Orange_brightnessVal *= 0.00125;

		if (Yellow_hueVal > 0.0)
			Yellow_hueVal *= 1.2;

		Yellow_satVal *= 0.01;
		Yellow_brightnessVal *= 0.00125;

		if (Green_hueVal > 0.0)
			Green_hueVal *= 1.2;
		Green_satVal *= 0.01;
		Green_brightnessVal *= 0.00125;

		if (Magenta_hueVal > 0.0)
			Magenta_hueVal *= 1.2;
		Magenta_satVal *= 0.01;
		Magenta_brightnessVal *= 0.00125;

		if (Purple_hueVal > 0.0)
			Purple_hueVal *= 1.2;
		Purple_satVal *= 0.01f;
		Purple_brightnessVal *= 0.00125;

		if (Blue_hueVal > 0.0)
			Blue_hueVal *= 1.2;
		Blue_satVal *= 0.01;
		Blue_brightnessVal *= 0.00125;

		if (Aqua_hueVal > 0.0)
			Aqua_hueVal *= 1.2;
		Aqua_satVal *= 0.01;
		Aqua_brightnessVal *= 0.00125;



		float pixelAlphaRed = 0.0;
		float pixelAlphaOrange = 0.0;
		float pixelAlphaYellow = 0.0;
		float pixelAlphaGreen = 0.0;
		float pixelAlphaMagenta = 0.0;
		float pixelAlphaPurple = 0.0;
		float pixelAlphaBlue = 0.0;
		float pixelAlphaAqua = 0.0;
		int needBreak=0;
		vec3 hsl_Val = HSL_RGBtoHSL(OutColor.zyx);//rgb
		if (Red_hueVal != 0.0 || Red_satVal != 0.0 || Red_brightnessVal != 0.0) {
				if (hsl_Val.x >= Red_degreeMinVal || hsl_Val.x <= Red_degreeMaxVal) {

					if (hsl_Val.x >= Red_degreeMinVal)
					{
						pixelAlphaRed = (hsl_Val.x - Red_degreeMinVal) / (360.0 - Red_degreeMinVal);
					}
					else if (hsl_Val.x <= Red_degreeMaxVal)
					{
						pixelAlphaRed = 1.0 - hsl_Val.x / Red_degreeMaxVal;
					}
					hsl_Val.x += Red_hueVal;
					if (hsl_Val.x < 0.0)
						hsl_Val.x += 360.0;
					else if (hsl_Val.x > 360.0)
						hsl_Val.x -= 360.0;
					hsl_Val.y *= (1.0 + Red_satVal);
					hsl_Val.z *= (1.0 + Red_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,vec2(0.0),vec2(1.0));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).zyx;
					OutColor.xyz=(OutColor.xyz)*(1.0-pixelAlphaRed)+newColor*pixelAlphaRed;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}

		}
		if ((Orange_hueVal != 0.0 || Orange_satVal != 0.0 || Orange_brightnessVal != 0.0)&&needBreak==0) {
				if (hsl_Val.x >= Orange_degreeMinVal && hsl_Val.x <= Orange_degreeMaxVal) {

					float dist = (hsl_Val.x - Orange_degreeMinVal);
					dist = 2.0 * dist / (Orange_degreeMaxVal - Orange_degreeMinVal);
					if (dist <= 1.0)
						pixelAlphaOrange = dist;
					else
						pixelAlphaOrange = 2.0 - dist;

					hsl_Val.x += Orange_hueVal;
					if (hsl_Val.x < 0.0)
						hsl_Val.x += 360.0;
					else if (hsl_Val.x > 360.0)
						hsl_Val.x -= 360.0;
					hsl_Val.y *= (1.0 + Orange_satVal);
					hsl_Val.z *= (1.0 + Orange_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,vec2(0.0),vec2(1.0));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).zyx;
					OutColor.xyz=(OutColor.xyz)*(1.0-pixelAlphaOrange)+newColor*pixelAlphaOrange;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
		if ((Yellow_hueVal != 0.0 || Yellow_satVal != 0.0 || Yellow_brightnessVal != 0.0)&&needBreak==0) {
				if (hsl_Val.x >= Yellow_degreeMinVal && hsl_Val.x <= Yellow_degreeMaxVal) {

					float dist = (hsl_Val.x - Yellow_degreeMinVal);
					dist = 2.0 * dist / (Yellow_degreeMaxVal - Yellow_degreeMinVal);
					if (dist <= 1.0)
						pixelAlphaYellow = dist;
					else
						pixelAlphaYellow = 2.0 - dist;

					hsl_Val.x += Yellow_hueVal;
					if (hsl_Val.x < 0.0)
						hsl_Val.x += 360.0;
					else if (hsl_Val.x > 360.0)
						hsl_Val.x -= 360.0;
					hsl_Val.y *= (1.0 + Yellow_satVal);
					hsl_Val.z *= (1.0 + Yellow_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,vec2(0.0),vec2(1.0));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).zyx;
					OutColor.xyz=(OutColor.xyz)*(1.0-pixelAlphaYellow)+newColor*pixelAlphaYellow;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
		if ((Green_hueVal != 0.0 || Green_satVal != 0.0 || Green_brightnessVal != 0.0)&&needBreak==0) {
				if (hsl_Val.x >= Green_degreeMinVal && hsl_Val.x <= Green_degreeMaxVal) {

					float dist = (hsl_Val.x - Green_degreeMinVal);
					dist = 2.0 * dist / (Green_degreeMaxVal - Green_degreeMinVal);
					if (dist <= 1.0)
						pixelAlphaGreen = dist;
					else
						pixelAlphaGreen = 2.0 - dist;

					hsl_Val.x += Green_hueVal;
					if (hsl_Val.x < 0.0)
						hsl_Val.x += 360.0;
					else if (hsl_Val.x > 360.0)
						hsl_Val.x -= 360.0;
					hsl_Val.y *= (1.0 + Green_satVal);
					hsl_Val.z *= (1.0 + Green_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,vec2(0.0),vec2(1.0));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).zyx;
					OutColor.xyz=(OutColor.xyz)*(1.0-pixelAlphaGreen)+newColor*pixelAlphaGreen;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
		if ((Magenta_hueVal != 0.0 || Magenta_satVal != 0.0 || Magenta_brightnessVal != 0.0)&&needBreak==0) {
				if (hsl_Val.x >= Magenta_degreeMinVal && hsl_Val.x <= Magenta_degreeMaxVal) {

					float dist = (hsl_Val.x - Magenta_degreeMinVal);
					dist = 2.0 * dist / (Magenta_degreeMaxVal - Magenta_degreeMinVal);
					if (dist <= 1.0)
						pixelAlphaMagenta = dist;
					else
						pixelAlphaMagenta = 2.0 - dist;

					hsl_Val.x += Magenta_hueVal;
					if (hsl_Val.x < 0.0)
						hsl_Val.x += 360.0;
					else if (hsl_Val.x > 360.0)
						hsl_Val.x -= 360.0;
					hsl_Val.y *= (1.0 + Magenta_satVal);
					hsl_Val.z *= (1.0 + Magenta_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,vec2(0.0),vec2(1.0));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).zyx;
					OutColor.xyz=(OutColor.xyz)*(1.0-pixelAlphaMagenta)+newColor*pixelAlphaMagenta;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
		if ((Purple_hueVal != 0.0 || Purple_satVal != 0.0 || Purple_brightnessVal != 0.0)&&needBreak==0) {
				if (hsl_Val.x >= Purple_degreeMinVal && hsl_Val.x <= Purple_degreeMaxVal) {

					float dist = (hsl_Val.x - Purple_degreeMinVal);
					dist = 2.0 * dist / (Purple_degreeMaxVal - Purple_degreeMinVal);
					if (dist <= 1.0)
						pixelAlphaPurple = dist;
					else
						pixelAlphaPurple = 2.0 - dist;

					hsl_Val.x += Purple_hueVal;
					if (hsl_Val.x < 0.0)
						hsl_Val.x += 360.0;
					else if (hsl_Val.x > 360.0)
						hsl_Val.x -= 360.0;
					hsl_Val.y *= (1.0 + Purple_satVal);
					hsl_Val.z *= (1.0 + Purple_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,vec2(0.0),vec2(1.0));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).zyx;
					OutColor.xyz=(OutColor.xyz)*(1.0-pixelAlphaPurple)+newColor*pixelAlphaPurple;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
		if ((Blue_hueVal != 0.0 || Blue_satVal != 0.0 || Blue_brightnessVal != 0.0)&&needBreak==0) {
				if (hsl_Val.x >= Blue_degreeMinVal && hsl_Val.x <= Blue_degreeMaxVal) {

					float dist = (hsl_Val.x - Blue_degreeMinVal);
					dist = 2.0 * dist / (Blue_degreeMaxVal - Blue_degreeMinVal);
					if (dist <= 1.0)
						pixelAlphaBlue = dist;
					else
						pixelAlphaBlue = 2.0 - dist;

					hsl_Val.x += Blue_hueVal;
					if (hsl_Val.x < 0.0)
						hsl_Val.x += 360.0;
					else if (hsl_Val.x > 360.0)
						hsl_Val.x -= 360.0;
					hsl_Val.y *= (1.0 + Blue_satVal);
					hsl_Val.z *= (1.0 + Blue_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,vec2(0.0),vec2(1.0));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).zyx;
					OutColor.xyz=(OutColor.xyz)*(1.0-pixelAlphaBlue)+newColor*pixelAlphaBlue;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
		if ((Aqua_hueVal != 0.0 || Aqua_satVal != 0.0 || Aqua_brightnessVal != 0.0)&&needBreak==0) {
				if (hsl_Val.x >= Aqua_degreeMinVal && hsl_Val.x <= Aqua_degreeMaxVal) {

					float dist = (hsl_Val.x - Aqua_degreeMinVal);
					dist = 2.0 * dist / (Aqua_degreeMaxVal - Aqua_degreeMinVal);
					if (dist <= 1.0)
						pixelAlphaAqua = dist;
					else
						pixelAlphaAqua = 2.0 - dist;

					hsl_Val.x += Aqua_hueVal;
					if (hsl_Val.x < 0.0)
						hsl_Val.x += 360.0;
					else if (hsl_Val.x > 360.0)
						hsl_Val.x -= 360.0;
					hsl_Val.y *= (1.0 + Aqua_satVal);
					hsl_Val.z *= (1.0 + Aqua_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,vec2(0.0),vec2(1.0));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).zyx;
					OutColor.xyz=(OutColor.xyz)*(1.0-pixelAlphaAqua)+newColor*pixelAlphaAqua;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
	}
	if(bEnableVignette==1){
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

			vec4 color = OutColor;

			OutColor = vignettePixel(color, maskValue, amountRatio, exposureRatio, coffHighlight);
		}
	}
	return vec4(OutColor.xyz,color.w);
}

