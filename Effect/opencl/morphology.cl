const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;

__kernel void morphology_1(__read_only image2d_t src, __write_only image2d_t dst, float size)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = read_imagef(src, sampler, (int2)(coord.x, coord.y));
	float valf;

	int radius = size;
	radius = abs(radius);
	if (size > 0.0)
	{
		valf = 0;
		for (int i = -radius; i <= radius; i++)
		{
			float4 b = read_imagef(src, sampler, (int2)(coord.x + i, coord.y));
			float c = b.x + b.y + b.z;
			if (c > valf)
			{
				valf = c;
				val = b;
			}
		}
		float4 val1;
		float4 b = read_imagef(src, sampler, (int2)(coord.x  - radius -1, coord.y));
		float c = b.x + b.y + b.z;
		if (c > valf)
		{
			valf = c;
			val1 = b;
		}
		b = read_imagef(src, sampler, (int2)(coord.x + radius + 1, coord.y));
		c = b.x + b.y + b.z;
		if (c > valf)
		{
			valf = c;
			val1 = b;
		}
		
		val = val + (val1-val)*(size - radius);
	}
	else
	{
		valf = 10000;;
		for (int i = -radius; i <= radius; i++)
		{
			float4 b = read_imagef(src, sampler, (int2)(coord.x + i, coord.y));
			float c = b.x + b.y + b.z;
			if (c < valf)
			{
				valf = c;
				val = b;
			}
		}
		float4 val1;
		float4 b = read_imagef(src, sampler, (int2)(coord.x  - radius -1, coord.y));
		float c = b.x + b.y + b.z;
		if (c < valf)
		{
			valf = c;
			val1 = b;
		}
		b = read_imagef(src, sampler, (int2)(coord.x + radius + 1, coord.y));
		c = b.x + b.y + b.z;
		if (c < valf)
		{
			valf = c;
			val1 = b;
		}
		
		val = val + (val1-val)*(size - radius);
	}

	write_imagef(dst, coord, val);
}


__kernel void morphology_2(__read_only image2d_t src, __write_only image2d_t dst, float size)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = read_imagef(src, sampler, (int2)(coord.x, coord.y));
	float valf;

	int radius = size;
	radius = abs(radius);

	if (size > 0.0)
	{
		valf = 0;
		for (int i = -radius; i <= radius; i++)
		{
			float4 b = read_imagef(src, sampler, (int2)(coord.x, coord.y + i));
			float c = b.x + b.y + b.z;
			if (c > valf)
			{
				valf = c;
				val = b;
			}
		}
	}
	else
	{
		valf = 10000;
		for (int i = -radius; i <= radius; i++)
		{
			float4 b = read_imagef(src, sampler, (int2)(coord.x, coord.y + i));
			float c = b.x + b.y + b.z;
			if (c < valf)
			{
				valf = c;
				val = b;
			}
		}
	}
	write_imagef(dst, coord, val);
}



__kernel void copy(__read_only image2d_t src, __write_only image2d_t dst)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(dst);
	int h = get_image_width(dst);

	if (coord.x >= w || coord.y >= h)
		return;
	float4 val = read_imagef(src, sampler, coord);
	write_imagef(dst, coord, val);
}

__kernel void mean_1(__read_only image2d_t src, __write_only image2d_t dst)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(dst);
	int h = get_image_width(dst);

	if (coord.x >0|| coord.y >= h)
		return;
	float4 val = {0.0f,0.0f,0.0f,0.0f};
	for(int i = 0; i<w;i++)
		val += read_imagef(src, sampler, (int2)(coord.x+i,coord.y));
	val/=w;
	int2 coord_1;
	coord_1.x = coord.y;
	coord_1.y = coord.x;
	write_imagef(dst, coord_1, val);
}
__kernel void mean_2(__read_only image2d_t src, __global float* dst)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_width(src);

	if (coord.x >0 || coord.y >0)
		return;

	float4 val = {0.0f,0.0f,0.0f,0.0f};
	for(int i = 0; i<w;i++)
		val += read_imagef(src, sampler, (int2)(coord.x,coord.y+i));
	val/=w;
	dst[0] = val.x;
}

__kernel void seg(__read_only image2d_t src, __write_only image2d_t dst,__global float* con,const float error)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(dst);
	int h = get_image_width(dst);

	if (coord.x >=w|| coord.y >= h)
		return;
	float4 val = read_imagef(src, sampler, (int2)(coord.x,coord.y));
	if(val.x<con[0])
		val.x = 0.0f;
	val*= error;
	write_imagef(dst, coord, val);
}

__kernel void add(__read_only image2d_t src, __read_only image2d_t src2,__write_only image2d_t dst)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(dst);
	int h = get_image_width(dst);

	if (coord.x >=w|| coord.y >= h)
		return;

	float4 val = read_imagef(src, sampler, coord);
	float4 val_1 = read_imagef(src2,sampler,coord);
	val+=val_1;
	write_imagef(dst, coord, val);
}

__kernel void sub(__read_only image2d_t src, __read_only image2d_t src2,__write_only image2d_t dst)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(dst);
	int h = get_image_width(dst);

	if (coord.x >=w|| coord.y >= h)
		return;

	float4 val = read_imagef(src, sampler, coord);
	float4 val_1 = read_imagef(src2,sampler,coord);
	val-=val_1;
	write_imagef(dst, coord, val);
}