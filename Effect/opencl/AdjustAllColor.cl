#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.1415926535897932f
#define MIN(a,b) (((a) < (b)) ? (a) : (b))
#define NEXT(x) (MIN(x+1,mLutDim - 1))

const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;
const sampler_t sampler1 = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;
const sampler_t samplerBG = CLK_NORMALIZED_COORDS_FALSE | CLK_FILTER_NEAREST;

typedef struct PR
{
	float r;
	float g;
	float b;
}PR;
	
static PR findLutPoint(__global float* lut3D, int ir, int ig, int ib)
{

	__global float* index = lut3D  + ir*12675 + ig*195 + ib*3;
	PR pr = {*(index), *(index + 1), *(index + 2)};
	return pr;
	
}

float enHanceColor(float color, float coff)
{
	float adjust = coff * color;
	float val = 1.0f - (1.0f - adjust) * (1.0f - color);

	return val;
}
vec4 calPowColor(vec4 color, float exposure)
{
	vec4 ret = color * exposure;
	ret.w = color.w;
	//ret = clamp(ret, (vec4)(0.0f), (vec4)(1.0f));

	return ret;
}
float luminance(vec3 color)
{
	float fmin = min(min(color.z, color.y), color.x);
	float fmax = max(max(color.z, color.y), color.x);

	return (fmin + fmax) / 2.0f;
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
		//brightValue = ((-255.0f)*(1.0f / (0.99f + bright / 253.0f) - 1.0f));
		brightValue *= 0.6f;
	}

	return brightValue;
}
vec4 newBrightness(vec4 color, float bright)
{
	vec4 ret;

	if (bright > 0.0f)
		ret = color * bright;
	else
		ret = color + bright;

	ret.w = color.w;
	//ret = clamp(ret, (vec4)(0.0f), (vec4)(1.0f));

	return ret;
}
vec3 calContrastValue(float contrast)
{
	float contrastValue = 0.0f;
	int contrastVal = 0;
	int nHigh = 0;
	int nStretch = 0;
	vec3 ret;

	if (contrast > 0.0f)
		contrastValue = 1.0f / (1.0f - contrast / 255.0) - 1.0f;
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
vec4 calContrastColor(vec4 color, float contrastVal, float nHigh, float nStretch)
{
	vec4 ret;

    if (contrastVal > 0.0)
	{
		if (color.z <= contrastVal)
			ret.z = 0.0;
		else if (color.z > nHigh)
			ret.z = 1.0;
		else
			ret.z = (color.z - contrastVal) / nStretch;

		if (color.y <= contrastVal)
			ret.y = 0.0;
		else if (color.y > nHigh)
			ret.y = 1.0;
		else
			ret.y = (color.y - contrastVal) / nStretch;

		if (color.x <= contrastVal)
			ret.x = 0.0;
		else if (color.x > nHigh)
			ret.x = 1.0;
		else
			ret.x = (color.x - contrastVal) / nStretch;
	}
	else
	{
		ret.x = (color.x * nStretch) - contrastVal;
		ret.y = (color.y * nStretch) - contrastVal;
		ret.z = (color.z * nStretch) - contrastVal;
	}

	ret.w = color.w;
	//ret = clamp(ret, vec4(0.0), vec4(1.0));

	return ret;
}
vec4 mixLumaAndColor(vec4 color, float lumaValue, float lumaMask, float vibrance)
{
	vec4 ret;

	float radio = 1.0f + vibrance * lumaMask;
	float repersed = 1.0f - radio;

	ret = color * radio + lumaValue * repersed;
	ret = clamp(ret, (vec4)(0.0f), (vec4)(1.0f));
	ret.w = color.w;

	return ret;
}
vec4 calNewColor(vec4 color, float saturation)
{
	float rgbMax = max(color.z, max(color.y, color.x));
	float rgbMin = min(color.z, min(color.y, color.x));
	float delta = rgbMax - rgbMin;

	if (delta == 0.0f)
		return color;

	float dValue = rgbMax + rgbMin;
	float L = dValue / 2.0f;
	float S = 0.0f;

	if (L < 0.5f)
		S = delta / dValue;
	else
		S = delta / (2.0f - dValue);

	float alpha = 0.0f;
	vec4 ret;

	if (saturation >= 0.0f)
	{
		if ((saturation + S) >= 1.0f)
			alpha = S;
		else
			alpha = 1.0f - saturation;

		alpha = 1.0f / alpha - 1.0f;

		ret.x = clamp(color.x	 + (color.x	- L ) * alpha, 0.0f, 1.0f);
		ret.y = clamp(color.y + (color.y  - L) * alpha, 0.0f, 1.0f);
		ret.z = clamp(color.z  + (color.z	- L) * alpha, 0.0f, 1.0f);
		ret.w = color.w;
	}
	else
	{
		alpha = saturation;
		ret.x= clamp(L + (color.x  - L ) * (1.0f + alpha), 0.0f, 1.0f);
		ret.y= clamp(L + (color.y - L ) * (1.0f + alpha), 0.0f, 1.0f);
		ret.z= clamp(L + (color.z  - L ) * (1.0f + alpha), 0.0f, 1.0f);
		ret.w = color.w;
	}
	return ret;
}
vec4 calHighlight(vec4 color, float highLight)
{
	vec4 ret;
	float lumaince = highLight * (max(color.z, max(color.y, color.x)));

	ret.x = enHanceColor(color.x, lumaince);
	ret.y = enHanceColor(color.y, lumaince);
	ret.z = enHanceColor(color.z, lumaince);
	ret.w = color.w;

	ret = clamp(ret, (vec4)(0.0f), (vec4)(1.0f));

	return ret;
}
vec4 calShadow(vec4 color, float shadow)
{
	vec4 ret;
	float lumaince = shadow * (1.0f - max(color.x, max(color.y, color.z)));

	ret.x = enHanceColor(color.x, lumaince);
	ret.y = enHanceColor(color.y, lumaince);
	ret.z = enHanceColor(color.z, lumaince);
	ret.w = color.w;

	ret = clamp(ret, (vec4)(0.0f), (vec4)(1.0f));

	return ret;
}
vec4 calWhiteLevelPixel(vec4 color, float level)
{
	vec4 ret;
	float lumaince = level * (max(color.x, max(color.y, color.z)));

	ret.x = enHanceColor(color.x, lumaince);
	ret.y = enHanceColor(color.y, lumaince);
	ret.z = enHanceColor(color.z, lumaince);

	if (lumaince > 0.0f)
	{
		ret.x = enHanceColor(ret.x, lumaince);
		ret.y = enHanceColor(ret.y, lumaince);
		ret.z = enHanceColor(ret.z, lumaince);
	}

	ret.w = color.w;

	ret = clamp(ret, (vec4)(0.0f), (vec4)(1.0f));

	return ret;
}
vec4 calBlackLevelPixel(vec4 color, float level)
{
	vec4 ret;
	float lumaince = level * (1.0f - max(color.x, max(color.y, color.z)));

	ret.x = enHanceColor(color.x, lumaince);
	ret.y = enHanceColor(color.y, lumaince);
	ret.z = enHanceColor(color.z, lumaince);
	ret.w = color.w;

	ret = clamp(ret, (vec4)(0.0f), (vec4)(1.0f));

	return ret;
}
vec3 HSL_RGBtoHSL(vec3 RGB)
{
	vec3 hsl;
	float R = RGB.x;//
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

		H /= 6.0f;
		if (H < 0.0f)
			H += 1.0f;
	}

	hsl.x = H * 360.0f;
	hsl.y = S;
	hsl.z = L;

	return hsl;
}
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
			tempr=tempr-1.0f;

		tempg = H;

		tempb = H - 1.0f / 3.0f;
		if (tempb < 0.0f)
			tempb=tempb+1.0f;

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

	RGB.x = R;
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
float generateGradient(vec2 pos, vec2 center, float featherRatio, float sizeRatio, float roundNess)
{
	float maskVal = 1.0f;
	float a = 0.2f* center.x * (1.0f + 4.0f * sizeRatio);
	float b = 0.2f * center.y * (1.0f + 4.0f * sizeRatio);
	float diff = fabs(a - b) * roundNess;

	if (diff >= 0.0f)
	{
		if (a > b)
			a -= diff;
		else if (fabs(a - b)<1.0e-5f)//a==b
		{
			a = a;
			b = b;
		}
		else
			b -= diff;
	}

	float bandPixel = featherRatio * ((a > b ? a : b) / 2.0f) + 3.0f;
	float arguFactor = PI / bandPixel;

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
float highLightColor(float color, float coff)
{
	float adjust = coff * color;
	float val = 1.0f- (1.0 - adjust) * (1.0f - color);

	return val;
}
vec4 vignettePixel(vec4 color, float maskValue, float amountVal, float exposureVal, float highlights)
{
	vec4 ret;

	float R = color.x;
	float G = color.y;
	float B = color.z;

	float outR = (1.0f + amountVal) * R;
	float outG = (1.0f + amountVal) * G;
	float outB = (1.0f + amountVal) * B;

	float factor1 = maskValue * exposureVal;
	float factor2 = maskValue * 2.0f;
	factor2 = factor2 - 1.0f;
	factor2 = 0.5f * (1.0f - factor2);

	R = R * factor1 + outR * factor2;
	G = G * factor1 + outG * factor2;
	B = B * factor1 + outB * factor2;

	if (maskValue < 1.0f)
	{
		float factor = 1.0f - maskValue;
		factor = pow(factor, 2.0f);
		float lumaince = factor * highlights * (1.0f - (R + G + B) / 3.0f);
		R = highLightColor(R, lumaince);
		G = highLightColor(G, lumaince);
		B = highLightColor(B, lumaince);
	}

	ret.x = clamp(R, 0.0f, 1.0f);
	ret.y = clamp(G, 0.0f, 1.0f);
	ret.z = clamp(B, 0.0f, 1.0f);
	ret.w = color.w;

	return ret;
}
__kernel void AdjustAllColor(__read_only image2d_t src,__write_only image2d_t dst,
                             __global float* lut3D, __global float* FT, __global int* GT,__global AdjustColorFilterParam*params,
                             int width, int height, unsigned int mLutDim)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int W = width;
	int H =height;
	float2 u_resolution = (float2)((float)(width),(float)(height));	
	float2 uv=(float2)(get_global_id(0), get_global_id(1))+(float2)(0.5f,0.5f);
	float2 tc=uv/u_resolution;

	if (coord.x >= W || coord.y >= H)
		return;
	float tint=params->tint/200.0f;
	float temperature=params->temperature/200.0f;
	int bEnableWB=params->bEnableWB;
	int bEnableLUT=params->bEnableLUT;
	int lutRow=params->lutRow;
	int lutCol=params->lutCol;
	int lutDim=params->lutDim;
	int bEnableColor=params->bEnableColor;
	float u_exposure=params->u_exposure;
	float u_brightness=params->u_brightness;
	float u_contrast=params->u_contrast;
	float u_vib=params->u_vib;
	float u_sat=params->u_sat;
	int bEnableLight=params->bEnableLight;
	float u_highLight=params->u_highLight;
	float u_shadow=params->u_shadow;
	float u_whiteLevel=params->u_whiteLevel;
	float u_blackLevel=params->u_blackLevel;
	int bEnableHSL=params->bEnableHSL;
	float Red_hueVal=params->Red_hueVal;
	float Red_satVal=params->Red_satVal;
	float Red_brightnessVal=params->Red_brightnessVal;
	float Orange_hueVal=params->Orange_hueVal;
	float Orange_satVal=params->Orange_satVal;
	float Orange_brightnessVal=params->Orange_brightnessVal;
	float Yellow_hueVal=params->Yellow_hueVal;
	float Yellow_satVal=params->Yellow_satVal;
	float Yellow_brightnessVal=params->Yellow_brightnessVal;
	float Green_hueVal=params->Green_hueVal;
	float Green_satVal=params->Green_satVal;
	float Green_brightnessVal=params->Green_brightnessVal;
	float Magenta_hueVal=params->Magenta_hueVal;
	float Magenta_satVal=params->Magenta_satVal;
	float Magenta_brightnessVal=params->Magenta_brightnessVal;
	float Purple_hueVal=params->Purple_hueVal;
	float Purple_satVal=params->Purple_satVal;
	float Purple_brightnessVal=params->Purple_brightnessVal;
	float Blue_hueVal=params->Blue_hueVal;
	float Blue_satVal =params->Blue_hueVal;
	float Blue_brightnessVal=params->Blue_brightnessVal;		
	float Aqua_hueVal =params->Aqua_hueVal;
	float Aqua_satVal =params->Aqua_satVal;
	float Aqua_brightnessVal=params->Aqua_brightnessVal;
	float Red_degreeMinVal =params->Red_degreeMinVal;
	float Red_degreeMaxVal=params->Red_degreeMaxVal;
	float Orange_degreeMinVal=params->Orange_degreeMinVal;
	float Orange_degreeMaxVal=params->Orange_degreeMaxVal;
	float Yellow_degreeMinVal=params->Yellow_degreeMinVal;
	float Yellow_degreeMaxVal=params->Yellow_degreeMaxVal;
	float Green_degreeMinVal=params->Green_degreeMinVal;
	float Green_degreeMaxVal=params->Green_degreeMaxVal;
	float Magenta_degreeMinVal=params->Magenta_degreeMinVal;
	float Magenta_degreeMaxVal=params->Magenta_degreeMaxVal;
	float Purple_degreeMinVal=params->Purple_degreeMinVal;
	float Purple_degreeMaxVal=params->Purple_degreeMaxVal;
	float Blue_degreeMinVal=params->Blue_degreeMinVal;
	float Blue_degreeMaxVal=params->Blue_degreeMaxVal;
	float Aqua_degreeMinVal=params->Aqua_degreeMinVal;
	float Aqua_degreeMaxVal=params->Aqua_degreeMaxVal;
	float u_vignette_size=params->u_vignette_size;

	int bEnableVignette=params->bEnableVignette;
	float u_vignette_amount=params->u_vignette_amount;
	float u_vignette_feather=params->u_vignette_feather;
	float u_vignette_highlights=params->u_vignette_highlights;
	float u_vignette_roundness= params->u_vignette_roundness;
	float u_vignette_exposure = params->u_vignette_exposure;
	
	int bEnableAutoColor = params->bEnableAutoColor;
	float value = params->value;
	float blue_gamma = params->blue_gamma;
	float green_gamma = params->green_gamma;
	float red_gamma = params->red_gamma;
	int minVal = params->minVal;
	int maxVal = params->maxVal;

	float deltaR = 1.0f+tint / 2.0f + temperature;
	float deltaB = 1.0f+tint / 2.0f - temperature;
	float deltaG = 1.0f - tint;
	float4 input = read_imagef(src, sampler, coord);
	float4 OutColor=input;
	
	if(bEnableAutoColor == 1){
		float4 CorrectColor = (float4)(0.0f);
		float3 gamma = (float3)(red_gamma,green_gamma,blue_gamma);
		CorrectColor.xyz = clamp(pow(input.xyz,gamma),0.0f,1.0f);
		if(minVal != maxVal){
			float min_val = (float)(minVal)/255.0f;
			float max_val = (float)(maxVal)/255.0f;
			CorrectColor.x = CorrectColor.x < min_val?0.0f:(CorrectColor.x>max_val?1.0f:((CorrectColor.x - min_val)/(max_val-min_val)));
			CorrectColor.y = CorrectColor.y < min_val?0.0f:(CorrectColor.y>max_val?1.0f:((CorrectColor.y - min_val)/(max_val-min_val)));
			CorrectColor.z = CorrectColor.z < min_val?0.0f:(CorrectColor.z>max_val?1.0f:((CorrectColor.z - min_val)/(max_val-min_val)));				
			CorrectColor.xyz = clamp(pow(CorrectColor.xyz,0.5f),0.0f,1.0f);
		}
		float min_threshold_value = 5.0f/255.0f;
		float max_threshold_value = 250.0f/255.0f;
		if(input.x < min_threshold_value || input.x > max_threshold_value)
			CorrectColor.x = input.x;
		if(input.y < min_threshold_value || input.y > max_threshold_value)
			CorrectColor.y = input.y;
		if(input.z < min_threshold_value || input.z > max_threshold_value)
			CorrectColor.z = input.z;
		OutColor.xyz = mix(input.xyz,CorrectColor.xyz,value);
	}
	if(bEnableWB==1){
		OutColor.x = OutColor.x  *deltaR;
		OutColor.y = OutColor.y * deltaG;	
		OutColor.z = OutColor.z * deltaB;
		OutColor = clamp(OutColor, (float4)(0.0f), (float4)(1.0f));
	}	
	if(bEnableLUT==1){
        uchar r, g, b;	    
	    uchar3 rgb = convert_uchar3_sat(OutColor.xyz*255.0f );
	    r = rgb.x;
	    g = rgb.y;
	    b = rgb.z;
	
	    PR c000, c001, c010, c011, c100, c101, c110, c111,c;
	    float F = 256.f / (float)(mLutDim) - 1.0f;
	    int K = 256 / mLutDim;
	    float fr, fg, fb;
	    int ir, ig, ib;

	    fb = *(FT + b); //FT[b];
	    fg = *(FT + g); //FT[g];
	    fr = *(FT + r); //FT[r];

	    ib = *(GT + b); // GT[b];
	    ig = *(GT + g); //GT[g];
	    ir = *(GT + r);//GT[r];

	    c000 = findLutPoint(lut3D, ir,ig,ib);//lut3D[ir][ig][ib];
	    c111 = findLutPoint(lut3D, NEXT(ir),NEXT(ig),NEXT(ib));
        if (fr > fg) {
            if (fg > fb) {
                c100 = findLutPoint(lut3D,NEXT(ir),ig,ib);//lut3D[NEXT(ir)][ig][ib];
                c110 = findLutPoint(lut3D,NEXT(ir),NEXT(ig), ib);//lut3D[NEXT(ir)][NEXT(ig)][ib];
                c.r = (1 - fr) * c000.r + (fr - fg) * c100.r + (fg - fb) * c110.r + (fb)* c111.r;
                c.g = (1 - fr) * c000.g + (fr - fg) * c100.g + (fg - fb) * c110.g + (fb)* c111.g;
                c.b = (1 - fr) * c000.b + (fr - fg) * c100.b + (fg - fb) * c110.b + (fb)* c111.b;
            }
            else if (fr > fb) {
                c100 = findLutPoint(lut3D, NEXT(ir),ig,ib); //lut3D[NEXT(ir)][ig][ib];
                c101 = findLutPoint(lut3D, NEXT(ir), ig, NEXT(ib));//lut3D[NEXT(ir)][ig][NEXT(ib)];
                c.r = (1 - fr) * c000.r + (fr - fb) * c100.r + (fb - fg) * c101.r + (fg)* c111.r;
                c.g = (1 - fr) * c000.g + (fr - fb) * c100.g + (fb - fg) * c101.g + (fg)* c111.g;
                c.b = (1 - fr) * c000.b + (fr - fb) * c100.b + (fb - fg) * c101.b + (fg)* c111.b;
            }
            else {
                c001 = findLutPoint(lut3D, ir, ig, NEXT(ib));//lut3D[ir][ig][NEXT(ib)];
                c101 = findLutPoint(lut3D, NEXT(ir),ig, NEXT(ib)); //lut3D[NEXT(ir)][ig][NEXT(ib)];
                c.r = (1 - fb) * c000.r + (fb - fr) * c001.r + (fr - fg) * c101.r + (fg)* c111.r;
                c.g = (1 - fb) * c000.g + (fb - fr) * c001.g + (fr - fg) * c101.g + (fg)* c111.g;
                c.b = (1 - fb) * c000.b + (fb - fr) * c001.b + (fr - fg) * c101.b + (fg)* c111.b;
                }
        }
        else {
            if (fb > fg) {
                c001 = findLutPoint(lut3D, ir, ig, NEXT(ib)); //lut3D[ir][ig][NEXT(ib)];
                c011 = findLutPoint(lut3D, ir, NEXT(ig), NEXT(ib)); //lut3D[ir][NEXT(ig)][NEXT(ib)];
                c.r = (1 - fb) * c000.r + (fb - fg) * c001.r + (fg - fr) * c011.r + (fr)* c111.r;
                c.g = (1 - fb) * c000.g + (fb - fg) * c001.g + (fg - fr) * c011.g + (fr)* c111.g;
                c.b = (1 - fb) * c000.b + (fb - fg) * c001.b + (fg - fr) * c011.b + (fr)* c111.b;
            }
            else if (fb > fr) {
                c010 = findLutPoint(lut3D, ir, NEXT(ig), ib);//lut3D[ir][NEXT(ig)][ib];
                c011 = findLutPoint(lut3D, ir, NEXT(ig), NEXT(ib)); //lut3D[ir][NEXT(ig)][NEXT(ib)];
                c.r = (1 - fg) * c000.r + (fg - fb) * c010.r + (fb - fr) * c011.r + (fr)* c111.r;
                c.g = (1 - fg) * c000.g + (fg - fb) * c010.g + (fb - fr) * c011.g + (fr)* c111.g;
                c.b = (1 - fg) * c000.b + (fg - fb) * c010.b + (fb - fr) * c011.b + (fr)* c111.b;
            }
            else {
                c010 = findLutPoint(lut3D, ir, NEXT(ig), ib);// lut3D[ir][NEXT(ig)][ib];
                c110 = findLutPoint(lut3D, NEXT(ir), NEXT(ig), ib); //lut3D[NEXT(ir)][NEXT(ig)][ib];
                c.r = (1 - fg) * c000.r + (fg - fr) * c010.r + (fr - fb) * c110.r + (fb)* c111.r;
                c.g = (1 - fg) * c000.g + (fg - fr) * c010.g + (fr - fb) * c110.g + (fb)* c111.g;
                c.b = (1 - fg) * c000.b + (fg - fr) * c010.b + (fr - fb) * c110.b + (fb)* c111.b;
            }
        }
	    OutColor.xyz = (vec3)( c.r, c.g, c.b)/255.0f;
	}
	if(bEnableColor==1){
		if (u_exposure != 0.0f) // exposure
			{
				float exposureValue = u_exposure / 50.0f;
				exposureValue *= 0.6f;
				float powValue = pow(2.0f, exposureValue);
				vec4 color = OutColor;

				OutColor = calPowColor(color, powValue);
			}

			if (u_brightness != 0.0f) // brightness
			{
				float brightValue = calBrightValue(u_brightness);
				vec4 color = OutColor;

				OutColor = newBrightness(color, brightValue);
			}

			if (u_contrast != 0.0f) // contrast
			{
				vec3 resultVal = calContrastValue(u_contrast);
				vec4 color = OutColor;

				OutColor = calContrastColor(color, resultVal.x, resultVal.y, resultVal.z);
			}

			if (u_vib != 0.0f) // vibrance
			{
				float vibrance = u_vib / 100.0f;
				vibrance *= 0.8;
				vec4 color = OutColor;
				float luma = luminance(color.rgb);
				vec4 mask = color - luma;
				mask = clamp(mask, (vec4)(0.0f), (vec4)(1.0f));
				float lumaMask = 1.0f - luminance(mask.rgb);

				OutColor = mixLumaAndColor(color, luma, lumaMask, vibrance);
			}

			if (u_sat != 0.0f) // saturation
			{
				float saturation = u_sat / 200.0f;
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
		if (Red_hueVal > 0.0f)
		Red_hueVal *= 1.2f;

		Red_satVal *= 0.01f;
		Red_brightnessVal *= 0.00125f;

		if (Orange_hueVal > 0.0f)
			Orange_hueVal *= 1.2f;

		Orange_satVal *= 0.01f;
		Orange_brightnessVal *= 0.00125f;

		if (Yellow_hueVal > 0.0f)
			Yellow_hueVal *= 1.2f;

		Yellow_satVal *= 0.01f;
		Yellow_brightnessVal *= 0.00125f;

		if (Green_hueVal > 0.0f)
			Green_hueVal *= 1.2f;
		Green_satVal *= 0.01f;
		Green_brightnessVal *= 0.00125f;

		if (Magenta_hueVal > 0.0f)
			Magenta_hueVal *= 1.2f;
		Magenta_satVal *= 0.01f;
		Magenta_brightnessVal *= 0.00125f;

		if (Purple_hueVal > 0.0f)
			Purple_hueVal *= 1.2f;
		Purple_satVal *= 0.01f;
		Purple_brightnessVal *= 0.00125f;

		if (Blue_hueVal > 0.0f)
			Blue_hueVal *= 1.2f;
		Blue_satVal *= 0.01f;
		Blue_brightnessVal *= 0.00125f;

		if (Aqua_hueVal > 0.0f)
			Aqua_hueVal *= 1.2f;
		Aqua_satVal *= 0.01f;
		Aqua_brightnessVal *= 0.00125f;

		float pixelAlphaRed = 0.0f;
		float pixelAlphaOrange = 0.0f;
		float pixelAlphaYellow = 0.0f;
		float pixelAlphaGreen = 0.0f;
		float pixelAlphaMagenta = 0.0f;
		float pixelAlphaPurple = 0.0f;
		float pixelAlphaBlue = 0.0f;
		float pixelAlphaAqua = 0.0f;
		int needBreak=0;
		vec3 hsl_Val = HSL_RGBtoHSL(OutColor.xyz);//rgb
		if (Red_hueVal != 0.0f || Red_satVal != 0.0f || Red_brightnessVal != 0.0f) {
				if (hsl_Val.x >= Red_degreeMinVal || hsl_Val.x <= Red_degreeMaxVal) {

					if (hsl_Val.x >= Red_degreeMinVal)
					{
						pixelAlphaRed = (hsl_Val.x - Red_degreeMinVal) / (360.0f - Red_degreeMinVal);
					}
					else if (hsl_Val.x <= Red_degreeMaxVal)
					{
						pixelAlphaRed = 1.0f - hsl_Val.x / Red_degreeMaxVal;
					}
					hsl_Val.x += Red_hueVal;
					if (hsl_Val.x < 0.0f)
						hsl_Val.x += 360.0f;
					else if (hsl_Val.x > 360.0f)
						hsl_Val.x -= 360.0f;
					hsl_Val.y *= (1.0f + Red_satVal);
					hsl_Val.z *= (1.0f + Red_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,(vec2)(0.0f),(vec2)(1.0f));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).xyz;
					OutColor.xyz=(OutColor.xyz)*(1.0f-pixelAlphaRed)+newColor*pixelAlphaRed;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}

		}
		if ((Orange_hueVal != 0.0f || Orange_satVal != 0.0f || Orange_brightnessVal != 0.0f)&&needBreak==0) {
				if (hsl_Val.x >= Orange_degreeMinVal && hsl_Val.x <= Orange_degreeMaxVal) {

					float dist = (hsl_Val.x - Orange_degreeMinVal);
					dist = 2.0f * dist / (Orange_degreeMaxVal - Orange_degreeMinVal);
					if (dist <= 1.0f)
						pixelAlphaOrange = dist;
					else
						pixelAlphaOrange = 2.0f - dist;

					hsl_Val.x += Orange_hueVal;
					if (hsl_Val.x < 0.0f)
						hsl_Val.x += 360.0f;
					else if (hsl_Val.x > 360.0f)
						hsl_Val.x -= 360.0f;
					hsl_Val.y *= (1.0f + Orange_satVal);
					hsl_Val.z *= (1.0f + Orange_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,(vec2)(0.0f),(vec2)(1.0f));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).xyz;
					OutColor.xyz=(OutColor.xyz)*(1.0f-pixelAlphaOrange)+newColor*pixelAlphaOrange;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
		if ((Yellow_hueVal != 0.0f || Yellow_satVal != 0.0f || Yellow_brightnessVal != 0.0f)&&needBreak==0) {
				if (hsl_Val.x >= Yellow_degreeMinVal && hsl_Val.x <= Yellow_degreeMaxVal) {

					float dist = (hsl_Val.x - Yellow_degreeMinVal);
					dist = 2.0f * dist / (Yellow_degreeMaxVal - Yellow_degreeMinVal);
					if (dist <= 1.0f)
						pixelAlphaYellow = dist;
					else
						pixelAlphaYellow = 2.0f - dist;

					hsl_Val.x += Yellow_hueVal;
					if (hsl_Val.x < 0.0f)
						hsl_Val.x += 360.0f;
					else if (hsl_Val.x > 360.0f)
						hsl_Val.x -= 360.0f;
					hsl_Val.y *= (1.0f + Yellow_satVal);
					hsl_Val.z *= (1.0f + Yellow_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,(vec2)(0.0f),(vec2)(1.0f));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).xyz;
					OutColor.xyz=(OutColor.xyz)*(1.0f-pixelAlphaYellow)+newColor*pixelAlphaYellow;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
		if ((Green_hueVal != 0.0f || Green_satVal != 0.0f || Green_brightnessVal != 0.0f)&&needBreak==0) {
				if (hsl_Val.x >= Green_degreeMinVal && hsl_Val.x <= Green_degreeMaxVal) {

					float dist = (hsl_Val.x - Green_degreeMinVal);
					dist = 2.0f * dist / (Green_degreeMaxVal - Green_degreeMinVal);
					if (dist <= 1.0f)
						pixelAlphaGreen = dist;
					else
						pixelAlphaGreen = 2.0f - dist;

					hsl_Val.x += Green_hueVal;
					if (hsl_Val.x < 0.0f)
						hsl_Val.x += 360.0f;
					else if (hsl_Val.x > 360.0f)
						hsl_Val.x -= 360.0f;
					hsl_Val.y *= (1.0f + Green_satVal);
					hsl_Val.z *= (1.0f + Green_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,(vec2)(0.0f),(vec2)(1.0f));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).xyz;
					OutColor.xyz=(OutColor.xyz)*(1.0f-pixelAlphaGreen)+newColor*pixelAlphaGreen;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
		if ((Magenta_hueVal != 0.0f || Magenta_satVal != 0.0f || Magenta_brightnessVal != 0.0f)&&needBreak==0) {
				if (hsl_Val.x >= Magenta_degreeMinVal && hsl_Val.x <= Magenta_degreeMaxVal) {

					float dist = (hsl_Val.x - Magenta_degreeMinVal);
					dist = 2.0f * dist / (Magenta_degreeMaxVal - Magenta_degreeMinVal);
					if (dist <= 1.0f)
						pixelAlphaMagenta = dist;
					else
						pixelAlphaMagenta = 2.0f - dist;

					hsl_Val.x += Magenta_hueVal;
					if (hsl_Val.x < 0.0f)
						hsl_Val.x += 360.0f;
					else if (hsl_Val.x > 360.0f)
						hsl_Val.x -= 360.0f;
					hsl_Val.y *= (1.0f + Magenta_satVal);
					hsl_Val.z *= (1.0f + Magenta_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,(vec2)(0.0f),(vec2)(1.0f));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).xyz;
					OutColor.xyz=(OutColor.xyz)*(1.0f-pixelAlphaMagenta)+newColor*pixelAlphaMagenta;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
		if ((Purple_hueVal != 0.0f || Purple_satVal != 0.0f || Purple_brightnessVal != 0.0f)&&needBreak==0) {
				if (hsl_Val.x >= Purple_degreeMinVal && hsl_Val.x <= Purple_degreeMaxVal) {

					float dist = (hsl_Val.x - Purple_degreeMinVal);
					dist = 2.0f * dist / (Purple_degreeMaxVal - Purple_degreeMinVal);
					if (dist <= 1.0f)
						pixelAlphaPurple = dist;
					else
						pixelAlphaPurple = 2.0f - dist;

					hsl_Val.x += Purple_hueVal;
					if (hsl_Val.x < 0.0f)
						hsl_Val.x += 360.0f;
					else if (hsl_Val.x > 360.0f)
						hsl_Val.x -= 360.0f;
					hsl_Val.y *= (1.0f + Purple_satVal);
					hsl_Val.z *= (1.0f + Purple_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,(vec2)(0.0f),(vec2)(1.0f));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).xyz;
					OutColor.xyz=(OutColor.xyz)*(1.0f-pixelAlphaPurple)+newColor*pixelAlphaPurple;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
		if ((Blue_hueVal != 0.0f || Blue_satVal != 0.0f || Blue_brightnessVal != 0.0f)&&needBreak==0) {
				if (hsl_Val.x >= Blue_degreeMinVal && hsl_Val.x <= Blue_degreeMaxVal) {

					float dist = (hsl_Val.x - Blue_degreeMinVal);
					dist = 2.0f * dist / (Blue_degreeMaxVal - Blue_degreeMinVal);
					if (dist <= 1.0f)
						pixelAlphaBlue = dist;
					else
						pixelAlphaBlue = 2.0f - dist;

					hsl_Val.x += Blue_hueVal;
					if (hsl_Val.x < 0.0f)
						hsl_Val.x += 360.0f;
					else if (hsl_Val.x > 360.0f)
						hsl_Val.x -= 360.0f;
					hsl_Val.y *= (1.0f + Blue_satVal);
					hsl_Val.z *= (1.0f + Blue_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,(vec2)(0.0f),(vec2)(1.0f));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).xyz;
					OutColor.xyz=(OutColor.xyz)*(1.0f-pixelAlphaBlue)+newColor*pixelAlphaBlue;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
		if ((Aqua_hueVal != 0.0f || Aqua_satVal != 0.0f || Aqua_brightnessVal != 0.0f)&&needBreak==0) {
				if (hsl_Val.x >= Aqua_degreeMinVal && hsl_Val.x <= Aqua_degreeMaxVal) {

					float dist = (hsl_Val.x - Aqua_degreeMinVal);
					dist = 2.0f * dist / (Aqua_degreeMaxVal - Aqua_degreeMinVal);
					if (dist <= 1.0f)
						pixelAlphaAqua = dist;
					else
						pixelAlphaAqua = 2.0f - dist;

					hsl_Val.x += Aqua_hueVal;
					if (hsl_Val.x < 0.0f)
						hsl_Val.x += 360.0f;
					else if (hsl_Val.x > 360.0f)
						hsl_Val.x -= 360.0f;
					hsl_Val.y *= (1.0f + Aqua_satVal);
					hsl_Val.z *= (1.0f + Aqua_brightnessVal);
					hsl_Val.yz=clamp(hsl_Val.yz,(vec2)(0.0f),(vec2)(1.0f));
					vec3 newColor=HSL_HSLtoRGB(hsl_Val).xyz;
					OutColor.xyz=(OutColor.xyz)*(1.0f-pixelAlphaAqua)+newColor*pixelAlphaAqua;
					needBreak=1;
					//return vec4(OutColor.xyz,color.w);
				}
		}
	}
	if(bEnableVignette==1){
		if (u_vignette_amount != 0.0f || u_vignette_exposure != 0.0f)
		{
			float amountRatio = u_vignette_amount / 100.0f;
			float featherRatio = u_vignette_feather / 100.0f;
			float coffHighlight = u_vignette_highlights / 100.0f;
			float sizeRatio = u_vignette_size / 100.0f;
			float roundRatio = u_vignette_roundness / 100.0f;
			float exposureRatio = u_vignette_exposure / 100.0f;
			vec2 position;
			vec2 center;

			coffHighlight = (2.0f * coffHighlight - 1.0f) * fabs(amountRatio);
			exposureRatio = pow(2.0f, exposureRatio);

			position.x = (float)(coord.x);
			position.y = (float)(coord.y);

			center.x = W / 2.0f;
			center.y = H / 2.0f;

			float maskValue = generateGradient(position, center, featherRatio, sizeRatio, roundRatio);

			vec4 color = OutColor;

			OutColor = vignettePixel(color, maskValue, amountRatio, exposureRatio, coffHighlight);
		}
	}

	OutColor.w = input.w;
	//OutColor=(float4)(1.0f,0.0f,0.0f,1.0f);//rgb
	write_imagef(dst, coord, OutColor);
}

