// author: RuanShengQiang 
// date: 2017/6/21
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw
#define PI 3.141592653589f

const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP | CLK_FILTER_LINEAR;

vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, (vec2)(tc.x, 1.0f - tc.y));
}

bool IsMoreThan(int height, int cell_height, int x, int cur_len)
{
	int len = (int)((x + 1) * height - (float)(x*x + x)* cell_height /2.0f + 0.5f);
	if (len >= cur_len)
		return true;
	else
		return false;
}
#define N 10
__kernel void MAIN(__read_only image2d_t input1, __read_only image2d_t input2, __write_only image2d_t dstImg,__global FilterParam* param)
{
	float progress = param->cur_time / param->total_time;	int W = param->width[2];	int H = param->height[2];	int w = get_global_id(0);
	int h = get_global_id(1);
	float2 resolution = (float2)(W,H);
	int2 gl_FragCoord = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	vec2 uv = ((vec2)(fragCoord.x, fragCoord.y) + (vec2)(0.5f)) /resolution.xy;
	float iPro = (3.0f* progress * progress - 2.0f * progress * progress * progress); 	//(3 * T * t * t - 2 * t * t * t) /T/T
	
	int width = W;
	int height = H;
	float4 outputCol;
	
	float4 y1 = INPUT(input1, uv);
	float4 y2 = INPUT(input2, uv);

	int block = 50;
	int n_blocks = (height + (block - 1)) / block;
	int n_rest = height % block;
	float matt = 0.0f;
	int process = 2.0f*iPro*H;
	int offset = 0;
	for(int i=0;i<n_blocks;i++)
	{
		if(process > i*block)
		{
			offset = i*block - (process - i*block);
			//y1 = INPUT(input1, uv + (float2)(0.0f, -(float)(i*block - process + block)/H) );
			//y1 = INPUT(input1, uv + (float2)(0.0f, -(float)(i*block - process)/H) );
			matt += step( (float)(offset), (float)(h))*step( (float)h, (float)(offset + block) );
		}else
		{
			matt += step( (float)(i*block) , (float)h);
		}
	}
	outputCol = mix( y2, y1, clamp(matt,0.0f,1.0f));

	write_imagef(dstImg, (int2)(w, H - h - 1), outputCol);
}