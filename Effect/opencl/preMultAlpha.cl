
__kernel  void MAIN(
      __read_only image2d_t src_data,          //Image Dimensions
      __write_only image2d_t dest_data,        //Data in global memory     
	  __global FilterParam* param,
       int alphaType)  
				
{
   sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE |  CLK_FILTER_NEAREST;
   int origW = param->width[0];
   int origH = param->height[0];
   int newW = param->width[1];
   int newH = param->height[1];
   int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
   float2 temCoord = (float2)(0.0f);
   float4 color= read_imagef(src_data, sampler,coordinate);
   float4 outcolor=color;
   
   if(alphaType==1){
       outcolor=(float4)(color.xyz*color.w, color.w);
    }
    if(alphaType==2){
        outcolor.w=1.0f;
    }
    write_imagef(dest_data, coordinate, outcolor );
}