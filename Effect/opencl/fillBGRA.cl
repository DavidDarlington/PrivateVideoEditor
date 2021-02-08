__kernel  void MAIN(
      __write_only image2d_t dest_data,        //Data in global memory
	  __global FilterParam* param,
	  float B, //[0.0 - 1.0]
	  float G, //[0.0 - 1.0]
	  float R, //[0.0 - 1.0]
	  float A) //[0.0 - 1.0]
						
{
   sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE |  CLK_FILTER_LINEAR;
   
   int origW = param->width[0];
   int origH = param->height[0];
   int newW = param->width[1];
   int newH = param->height[1];
   
   int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	
	write_imagef(dest_data, coordinate, (float4)(R, G, B, A));
}