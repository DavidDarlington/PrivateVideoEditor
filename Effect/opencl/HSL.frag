
#ifdef GL_ES
precision highp float;
#endif

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


// HSL functions
//---------------------------------------------------------------------------------------//
vec3 HSL_RGBtoHSL(vec3 RGB)
{
	vec3 hsl;
	float R = RGB.r;
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
vec3 doAdjustHue(vec3 origColor, vec3 hsl_Val, float alphaVal, float hueVal)
{
	float hueValue = hueVal;
	if (hueValue > 0.0)
		hueValue *= 1.2;

	hsl_Val.x += hueValue;

	if (hsl_Val.x < 0.0)
		hsl_Val.x += 360.0;

	if (hsl_Val.x > 360.0)
		hsl_Val.x -= 360.0;

	vec3 color = HSL_HSLtoRGB(hsl_Val);

	float factor = 1.0 - alphaVal;

	vec3 ret = origColor * factor + color * alphaVal;
	ret = clamp(ret, vec3(0.0), vec3(1.0));

	return ret;
}

//---------------------------------------------------------------------------------------//
vec3 doAdjustStaturation(vec3 origColor, vec3 hsl_Val, float alphaVal, float satRadio)
{
	hsl_Val.y *= (1.0 + satRadio);
	hsl_Val.y = clamp(hsl_Val.y, 0.0, 1.0);
	vec3 color = HSL_HSLtoRGB(hsl_Val);

	float factor = 1.0 - alphaVal;

	vec3 ret = origColor * factor + color * alphaVal;
	ret = clamp(ret, vec3(0.0), vec3(1.0));

	return ret;
}

//---------------------------------------------------------------------------------------//
vec3 doAdjustBrightness(vec3 origColor, vec3 hsl_Val, float alphaVal, float brightnessRadio)
{
	hsl_Val.z *= (1.0 + brightnessRadio / 8.0);
	hsl_Val.z = clamp(hsl_Val.z, 0.0, 1.0);
	vec3 color = HSL_HSLtoRGB(hsl_Val);

	float factor = 1.0 - alphaVal;

	vec3 ret = origColor * factor + color * alphaVal;
	ret = clamp(ret, vec3(0.0), vec3(1.0));

	return ret;
}


vec4 FUNCNAME(vec2 tc)
{
	vec2 uv = tc;
	vec4 color = INPUT(tc).bgra;
	vec4 retColor = color;
	vec2 u_resolution = iResolution.xy;

    const float Red_degreeMinVal = 338.0;
    const float Red_degreeMaxVal = 25.0;
	if (Red_hueVal != 0.0 || Red_satVal != 0.0 || Red_brightnessVal != 0.0) // Red HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Red_degreeMinVal, Red_degreeMaxVal);
		vec3 newColor;

		if (Red_hueVal != 0.0)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Red_hueVal);
		else
			newColor = color.rgb;

		if (Red_satVal != 0.0)
		{
			float satRadio = Red_satVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Red_brightnessVal != 0.0)
		{
			float brightnessRadio = Red_brightnessVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = vec4(newColor, color.a);
	}

    
    const float Orange_degreeMinVal = 8.0;
    const float Orange_degreeMaxVal = 45.0;
	if (Orange_hueVal != 0.0 || Orange_satVal != 0.0 || Orange_brightnessVal != 0.0) // Orange HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Orange_degreeMinVal, Orange_degreeMaxVal);
		vec3 newColor;

		if (Orange_hueVal != 0.0)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Orange_hueVal);
		else
			newColor = color.rgb;

		if (Orange_satVal != 0.0)
		{
			float satRadio = Orange_satVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Orange_brightnessVal != 0.0)
		{
			float brightnessRadio = Orange_brightnessVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = vec4(newColor, color.a);
	}

   
    const float Yellow_degreeMinVal = 35.0;
    const float Yellow_degreeMaxVal = 100.0;
	if (Yellow_hueVal != 0.0 || Yellow_satVal != 0.0 || Yellow_brightnessVal != 0.0) // Yellow HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Yellow_degreeMinVal, Yellow_degreeMaxVal);
		vec3 newColor;

		if (Yellow_hueVal != 0.0)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Yellow_hueVal);
		else
			newColor = color.rgb;

		if (Yellow_satVal != 0.0)
		{
			float satRadio = Yellow_satVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Yellow_brightnessVal != 0.0)
		{
			float brightnessRadio = Yellow_brightnessVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = vec4(newColor, color.a);
	}

   
    const float Green_degreeMinVal = 65.5;
    const float Green_degreeMaxVal = 171.;
	if (Green_hueVal != 0.0 || Green_satVal != 0.0 || Green_brightnessVal != 0.0) // Green HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Green_degreeMinVal, Green_degreeMaxVal);
		vec3 newColor;

		if (Green_hueVal != 0.0)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Green_hueVal);
		else
			newColor = color.rgb;

		if (Green_satVal != 0.0)
		{
			float satRadio = Green_satVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Green_brightnessVal != 0.0)
		{
			float brightnessRadio = Green_brightnessVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = vec4(newColor, color.a);
	}

    const float Magenta_degreeMinVal = 281.;
    const float Magenta_degreeMaxVal = 330.;
	if (Magenta_hueVal != 0.0 || Magenta_satVal != 0.0 || Magenta_brightnessVal != 0.0) // Magenta HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Magenta_degreeMinVal, Magenta_degreeMaxVal);
		vec3 newColor;

		if (Magenta_hueVal != 0.0)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Magenta_hueVal);
		else
			newColor = color.rgb;

		if (Magenta_satVal != 0.0)
		{
			float satRadio = Magenta_satVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Magenta_brightnessVal != 0.0)
		{
			float brightnessRadio = Magenta_brightnessVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = vec4(newColor, color.a);
	}

  
    const float Purple_degreeMinVal = 258.;
    const float Purple_degreeMaxVal = 280.;
	if (Purple_hueVal != 0.0 || Purple_satVal != 0.0 || Purple_brightnessVal != 0.0) // Purple HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Purple_degreeMinVal, Purple_degreeMaxVal);
		vec3 newColor;

		if (Purple_hueVal != 0.0)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Purple_hueVal);
		else
			newColor = color.rgb;

		if (Purple_satVal != 0.0)
		{
			float satRadio = Purple_satVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Purple_brightnessVal != 0.0)
		{
			float brightnessRadio = Purple_brightnessVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = vec4(newColor, color.a);
	}

  
    const float Blue_degreeMinVal = 195.;
    const float Blue_degreeMaxVal = 250.;
	if (Blue_hueVal != 0.0 || Blue_satVal != 0.0 || Blue_brightnessVal != 0.0) // Blue HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Blue_degreeMinVal, Blue_degreeMaxVal);
		vec3 newColor;

		if (Blue_hueVal != 0.0)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Blue_hueVal);
		else
			newColor = color.rgb;

		if (Blue_satVal != 0.0)
		{
			float satRadio = Blue_satVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Blue_brightnessVal != 0.0)
		{
			float brightnessRadio = Blue_brightnessVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = vec4(newColor, color.a);
	}

  
    const float Aqua_degreeMinVal = 168.;
    const float Aqua_degreeMaxVal = 218.;
	if (Aqua_hueVal != 0.0 || Aqua_satVal != 0.0 || Aqua_brightnessVal != 0.0) // Aqua HSL
	{
		vec4 color = retColor;
		vec3 hsl_Val = HSL_RGBtoHSL(color.rgb);
		float pixelAlpha = calTransperency(hsl_Val, Aqua_degreeMinVal, Aqua_degreeMaxVal);
		vec3 newColor;

		if (Aqua_hueVal != 0.0)
			newColor = doAdjustHue(color.rgb, hsl_Val, pixelAlpha, Aqua_hueVal);
		else
			newColor = color.rgb;

		if (Aqua_satVal != 0.0)
		{
			float satRadio = Aqua_satVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustStaturation(newColor, hsl_Val, pixelAlpha, satRadio);
		}

		if (Aqua_brightnessVal != 0.0)
		{
			float brightnessRadio = Aqua_brightnessVal / 100.0;
			hsl_Val = HSL_RGBtoHSL(newColor.rgb);
			newColor = doAdjustBrightness(newColor, hsl_Val, pixelAlpha, brightnessRadio);
		}

		retColor = vec4(newColor, color.a);
	}
	
	return retColor.bgra;
}