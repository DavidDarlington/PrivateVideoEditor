const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE|  CLK_FILTER_LINEAR;
__kernel void MAIN(__read_only image2d_t src_data, __write_only image2d_t dest_data, __global FilterParam* param)
{
	float progress = param->cur_time / (float)(param->total_time);
	
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	float2 resolution = (float2)(param->width[0],param->height[0]);
	
	float2 fragCoord = (float2)(get_global_id(0)+0.5f, get_global_id(1)+0.5f);
	float2 tc = (float2)(fragCoord.x, fragCoord.y)/resolution.xy;
	
	float4 inCol = read_imagef(src_data, sampler, tc);
	
	float4 outCol = inCol*progress;
	

	write_imagef(dest_data, coordinate, outCol);
}