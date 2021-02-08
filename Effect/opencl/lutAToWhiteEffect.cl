
const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST;

__kernel void lut_a_to_white_effect(__read_only image2d_t src, __write_only image2d_t dst)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(dst);
	int h = get_image_height(dst);

	if (coord.x >= w || coord.y >= h)
		return;
	float4 val = read_imagef(src, sampler, coord);
	int valw  = (int)(val.w*255);
	if(!valw)
	{
		val = (float4)(0.0f,0.0f,0.0f,1.0f);
	}
	write_imagef(dst, coord, val);
}
