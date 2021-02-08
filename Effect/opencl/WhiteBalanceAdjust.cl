
const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;

__kernel void auto_white_balance(__read_only image2d_t src, __write_only image2d_t dst, float BGain, float GGain, float RGain)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(dst);
	int h = get_image_height(dst);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = (float4)(0, 0, 0, 0);
	float4 input = read_imagef(src, sampler, coord);

	val.x = input.x  *RGain;
	val.x = clamp(val.x, 0.0f, 255.0f);
	val.y = input.y * GGain;
	val.y = clamp(val.y, 0.0f, 255.0f);
	val.z = input.z * BGain;
	val.z = clamp(val.z, 0.0f, 255.0f);

	val.w = input.w;
	write_imagef(dst, coord, val);
}

