

const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;


__kernel void gaussian_1(__read_only image2d_t src, __write_only image2d_t dst, __global float* mask, int size)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = (float4)(0, 0, 0, 0);

	for (int i = -size; i <= size; i++)
	{
		val += read_imagef(src, sampler, (int2)(coord.x + i, coord.y))* mask[i + size];
	}

	//float len = 2 * size + 1;
	//val = val / len;
	//val.w = 1;
	write_imagef(dst, coord, val);
}


__kernel void gaussian_2(__read_only image2d_t src, __write_only image2d_t dst, __global float* mask, int size)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = (float4)(0, 0, 0, 0);

	for (int i = -size; i <= size; i++)
	{
		val += read_imagef(src, sampler, (int2)(coord.x, coord.y + i))* mask[i + size];
	}

	//float len = 2 * size + 1;
	//val = val / len;
	//val.w = 1;
	write_imagef(dst, coord, val);
}

__kernel void merge_1(__read_only image2d_t src, __read_only image2d_t blur, __write_only image2d_t dst, float amount)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = read_imagef(src, sampler, coord) * (1 + amount) - read_imagef(blur, sampler, coord) * amount;
	write_imagef(dst, coord, val);
}

__kernel void sum_mean_1(__read_only image2d_t src, __write_only image2d_t dst)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= 1)
		return;

	float4 val = (float4)(0, 0, 0, 0);
	for (int i = 0; i<h ; i++)
	{
		val += read_imagef(src, sampler, (int2)(coord.x, coord.y + i));
	}
	val /= h;
	write_imagef(dst, coord, val);
}

__kernel void sum_mean_2(__read_only image2d_t src, __write_only image2d_t dst)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= 1 || coord.y >= 1)
		return;

	float4 val = (float4)(0, 0, 0, 0);
	for (int i = 0; i<w;i++)
	{
		val += read_imagef(src, sampler, (int2)(coord.x + i, coord.y));
	}
	val /= w;
	write_imagef(dst, coord, val);
}

__kernel void merge_2(__read_only image2d_t src, __read_only image2d_t yuv, __write_only image2d_t dst, float mean_v,float c)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;
	
	float4 src_f = read_imagef(src, sampler, coord);	
	float4 val =(float4)(0,0,0,0);
	val.x =	src_f.x  * c + (1-c)*mean_v/255.0f;
	val.yzw = read_imagef(yuv, sampler, coord).yzw;
	write_imagef(dst, coord, val);
}


__kernel void rgb_to_ycrcb(__read_only image2d_t src,  __write_only image2d_t dst )
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = (float4){ 0.0f, 0.0f, 0.0f, 0.0f };


	float4 src_f = read_imagef(src, sampler, coord);

	val.x = src_f.x * 0.257f + src_f.y * 0.504f + src_f.z * 0.098f+16.0f/255.0f;
	val.y = src_f.x * (-0.148f) - src_f.y * 0.291f + src_f.z * 0.439f+128.0f/255.0f ;
	val.z = src_f.x * 0.439f - src_f.y *0.368f - src_f.z * 0.071f +128.0f/255.0f;
	val.w = src_f.w;

	write_imagef(dst, coord, val);

}

__kernel void ycrcb_to_rgb(__read_only image2d_t src, __write_only image2d_t dst )
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = (float4){ 0.0f, 0.0f, 0.0f, 0.0f };


	float4 src_f = read_imagef(src, sampler, coord);

	val.x = 1.164f*(src_f.x-16.0f/255.0f)   + 1.596f * (src_f.z-128.0f/255.0f);
	val.y = 1.164f*(src_f.x-16.0f/255.0f)  - 0.813f * (src_f.z - 128.0f/255.0f) - 0.392f * (src_f.y -128.0f/255.0f);
	val.z = 1.164f*(src_f.x-16.0f/255.0f) + 2.017f * (src_f.y - 128.0f/255.0f) ;
	val.w = src_f.w;

	write_imagef(dst, coord, val);

}