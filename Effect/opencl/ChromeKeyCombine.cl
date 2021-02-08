__kernel void MAIN(__read_only image2d_t overlay, __read_only image2d_t background, __write_only image2d_t dest_data,  __global FilterParam* param)
{
	const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST; 
	
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	float4 val ={0.0f,0.0f,0.0f,0.0f};
	float4 overlayCol = read_imagef(overlay, sampler, coordinate);
	float4 backCol =  read_imagef(background, sampler, coordinate);
	
	val.w = backCol.x*overlayCol.w;
	val.xyz = overlayCol.xyz * val.w/(overlayCol.w+0.0000000001f);
	write_imagef(dest_data, coordinate, val);
}