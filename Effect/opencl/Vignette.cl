
// texture coordinate
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.1415926535897932f

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
	  // Vignette parameter
	float amount,
	float feather,
	float highlights,
	float size,
	float roundness,
	float exposure
	)
{
	

	int W = param->width[0];
	int H = param->height[0];
	float2 u_resolution = (float2)(W,H);
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 uv = (vec2)(fragCoord.x + 0.5f, fragCoord.y + 0.5f)/u_resolution.xy;
	vec2 textureCoord = uv; 
	
	vec4 color = read_imagef(src_data, sampler, uv).zyxw;
	vec4 origColor = color;
	vec4 retColor = color;
	
	int imageWidth = W ;
	int imageHeight = H;

	if (amount != 0.0f || exposure != 0.0f)
	{
		float amountRatio = amount / 100.0f;
		float featherRatio = feather / 100.0f;
		float coffHighlight = highlights / 100.0f;
		float sizeRatio = size / 100.0f;
		float roundRatio = roundness / 100.0f;
		float exposureRatio = exposure / 100.0f;
		vec2 position;
		vec2 center;

		coffHighlight = (2.0f * coffHighlight - 1.0f) * fabs(amountRatio);
        exposureRatio = pow(2.0f, exposureRatio);

        position.x = textureCoord.x * (float)(imageWidth);
        position.y = textureCoord.y * (float)(imageHeight);

		center.x = (float)(imageWidth / 2);
		center.y = (float)(imageHeight / 2);

		float maskValue = generateGradient(position, center, featherRatio, sizeRatio, roundRatio);

		vec4 color = retColor;

		retColor = vignettePixel(color, maskValue, amountRatio, exposureRatio, coffHighlight);
	}

	float resultX0 = param->resultROI[0];
	float resultY0 = param->resultROI[1];
	float resultX1 = param->resultROI[2]+param->resultROI[0];
	float resultY1 = param->resultROI[3]+param->resultROI[1];
	
	float matt = step(resultX0,uv.x)*step(uv.x, resultX1)*step(resultY0,uv.y)*step(uv.y, resultY1);
	
	retColor = origColor*(1.0f - matt)  + retColor*matt; 
	
	write_imagef(dest_data, coordinate, (vec4)(retColor.zyx, color.w));

}
