#define vec2 float2
#define vec4 float4
#define rgb xyz
#define rgba xyzw

#define PI 3.1415926535897932f

const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_FILTER_NEAREST;

vec4 INPUT(image2d_t src_data, vec2 tc)
{
	return read_imagef(src_data, sampler, tc);
}

__kernel void MAIN(
      __read_only image2d_t src_data,
      __write_only image2d_t dest_data,        //Data in global memory
      __global FilterParam* param,
	  int type) // type 1, top frame; type 2, bottom frame) 
{	
	int W = param->width[0];
	int H = param->height[0];

	float roiX0 = param->resultROI[0];
	float roiY0 = param->resultROI[1];
	float roiX1 = param->resultROI[2]+param->resultROI[0];
	float roiY1 = param->resultROI[3]+param->resultROI[1];
	
	vec2 u_resolution = (vec2)(W,H);
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	vec2 fragCoord = (vec2)(get_global_id(0), get_global_id(1));
	
	vec4 colour= INPUT(src_data,fragCoord);
	
	int mode = 2;
	if(mode ==1)
	{
		if(type==1)//top
		{
			if(coordinate.y%2==1){
				colour = INPUT(src_data,fragCoord-(float2)(0.0f,1.0f));
			}else
			{
				colour= INPUT(src_data,fragCoord);
			}
		}
		
		if(type == 2)//bottom
		{
			if(coordinate.y%2==0){
				colour = INPUT(src_data,fragCoord-(float2)(0.0f,1.0f));
				if(coordinate.y==0)
				{
					colour = INPUT(src_data,fragCoord+(float2)(0.0f,1.0f));
				}
			}else
			{
				colour= INPUT(src_data,fragCoord);
			}
		}
	}
	if(mode ==2)
	{
		
		if(type==1)//top
		{
			if(coordinate.y%2==1){
				colour = ( INPUT(src_data,fragCoord-(float2)(0.0f,1.0f)) + INPUT(src_data,fragCoord+(float2)(0.0f,1.0f)) )/2.0f;
				if(coordinate.y+1==H)
				{
					colour = INPUT(src_data,fragCoord-(float2)(0.0f,1.0f));
				}
			}else
			{
				colour= INPUT(src_data,fragCoord);
			}
		}
		
		if(type == 2)//bottom
		{
			if(coordinate.y%2==0){
				colour = ( INPUT(src_data,fragCoord-(float2)(0.0f,1.0f)) + INPUT(src_data,fragCoord+(float2)(0.0f,1.0f)) )/2.0f;
				if(coordinate.y==0)
				{
					colour = INPUT(src_data,fragCoord+(float2)(0.0f,1.0f));
				}
				if(coordinate.y==H-1)
				{
					colour = INPUT(src_data,fragCoord-(float2)(0.0f,1.0f));
				}
			}else
			{
				colour= INPUT(src_data,fragCoord);
			}
		}
	}
	write_imagef(dest_data, coordinate, colour);
}

