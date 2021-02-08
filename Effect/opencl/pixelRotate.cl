__kernel  void MAIN(
      __read_only image2d_t src_data,          //Image Dimensions
      __write_only image2d_t dest_data,        //Data in global memory
	  __global FilterParam* param,
	  int rotateType)   //0:clockwise 90;1:clockwise 180;2:clockwise 270;3:flip X; 4:flip Y
						
{
	
   sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE |CLK_ADDRESS_CLAMP_TO_EDGE |  CLK_FILTER_LINEAR;
   
   int origW = param->width[0];
   int origH = param->height[0];
   int newW = param->width[1];
   int newH = param->height[1];
   
   int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
   float2 corf = (float2)(get_global_id(0), get_global_id(1)) + 0.5f;
   
   float nW = newW;
   float nH = newH;
   float oW = origW;
   float oH = origH;
   float2 temCoord = (float2)(0.0f);
   float4 color= (float4)(0.0f); 
   temCoord = (float2)((corf.x)*(float)(origW)/newW, (corf.y)*(float)(origH)/newH)/(float2)(origW,origH);
   
   switch(rotateType )
   {
	case(0):
			temCoord = (float2)(temCoord.y,1.0f - temCoord.x);
			break;
	case(1):
			temCoord = 1.0f - temCoord;
			break;
	case(2):
			temCoord =  (float2)(1.0f - temCoord.y,temCoord.x);
			break;
	case(3):
			temCoord =  (float2)(1.0f - temCoord.x,temCoord.y); 
			break;
	case(4):
			temCoord =  (float2)(temCoord.x,1.0f - temCoord.y); 
			break;
	default:
			temCoord = (float2)(temCoord.y,1.0f - temCoord.x);
   }
 
	color = read_imagef(src_data, sampler,temCoord);
	
	write_imagef(dest_data, coordinate, color);
}