
__kernel  void MAIN(
      __read_only image2d_t src_data,          //Image Dimensions
      __write_only image2d_t dest_data,        //Data in global memory
	  __global FilterParam* param,
	  int reSizeType//if it equal to 0, it means resize to fullscreen;, //if it equal to 1, it will keep the original scale ratio after resized. 
	 )
						
{
	sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;
	int origW = param->width[0];
	int origH = param->height[0];
	int newW = param->width[1];
	int newH = param->height[1];
   
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
    float4 color= (float4)(0.0f); 
	color = read_imagef(src_data, sampler, (int2)( coordinate.x*origW/newW, coordinate.y * origH/newH ) );
	write_imagef(dest_data, coordinate, color);
}