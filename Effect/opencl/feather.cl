const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE| CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;

__kernel void meanfilter_1(__read_only image2d_t src, __write_only image2d_t dst, int size,float error,float divisor)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = (float4)(0, 0, 0,0);
	int R = 2*size+1;
	float j = (float)R/11.0f;
	float k = -5.0f*j;

	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));//5
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));//10
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));

	
	val += read_imagef(src, sampler, (int2)(coord.x + size+1, coord.y))*error;
	val += read_imagef(src, sampler, (int2)(coord.x - size-1, coord.y))*error;
	val = val * divisor;
	write_imagef(dst, coord, val);
}


__kernel void meanfilter_2(__read_only image2d_t src, __write_only image2d_t dst, int size,float error,float divisor)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = (float4)(0, 0, 0,0);
	int R = 2*size+1;
	float j = (float)R/11.0f;
	float k = -5.0f*j;

	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));//5
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));//10
	val += read_imagef(src, sampler, (int2)(coord.x + floor(k+=j), coord.y));
	
	
	val += read_imagef(src, sampler, (int2)(coord.x + size+1, coord.y))*error;
	val += read_imagef(src, sampler, (int2)(coord.x - size-1, coord.y))*error;
	val = val * divisor;
	write_imagef(dst, coord, val);
}

__kernel void weighted_add( __write_only image2d_t dst,__read_only image2d_t src,__read_only image2d_t src1, float error)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 src_val= read_imagef(src, sampler, coord);
	float4 src1_val= read_imagef(src1, sampler, coord);
	float4 val= (float4)(0,0,0,0);
	val.xyz = src1_val.xyz+error*(src_val.xyz-src1_val.xyz);
	val.w=src1_val.w;
	write_imagef(dst, coord, val);
}

