#define ROUND(x) (floor(x + 0.5))
const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP | CLK_FILTER_LINEAR; 
float4 supersampling(__read_only image2d_t src_data,float h,float w,int gid_x,int gid_y){
	int index_start=(int)(gid_x*w);
	int index_end=(int)(ROUND((gid_x+1.0f)*w));	
	float wx=0.0f;
	float wy=0.0f;
	float n=0.0f;
	float rr=0.0f;
	float gg=0.0f;
	float bb=0.0f;
	float alpha=0.0f; 
	for(int j=index_start;j<index_end;j++){
		if (j < gid_x*w) {
			wx = j - gid_x*w + 1.0f;
		}
	
		else {
			if (j + 1.0f > (gid_x + 1.0f)*w)
				wx = (gid_x + 1.0f)*w - j;
			else wx = 1.0f;
		}
	
		for (int k = (int)(gid_y * h); k < (int)(ROUND((gid_y + 1.0f)*h)); k++){
			
				if (k < gid_y * h) {
					wy = k - gid_y * h + 1.0f;
				}
				else {
					if (k + 1.0f > (gid_y + 1.0f)*h) {
						wy = (gid_y + 1.0f)*h - k;
					}
					else wy = 1.0f;
				}
				n += wy * wx;
				float2 temCoord = (float2)((float)(j), (float)(k));
				float4 color = read_imagef(src_data, sampler,temCoord);
				
				rr += wx * wy*color.z;
				gg += wx * wy*color.y;
				bb += wx * wy*color.x;
				alpha += wx * wy*color.w;
		}
	
	}
	return (float4)((float)(bb/n),(float)(gg/n),(float)(rr/n),(float)(alpha/n));
}

__kernel  void MAIN(
      __read_only image2d_t src_data,          //Image Dimensions
      __write_only image2d_t dest_data,        //Data in global memory
	  __global FilterParam* param,
	  int reSizeType//if it equal to 0, it means resize to fullscreen;, //if it equal to 1, it will keep the original scale ratio after resized. 
	 )
	 {
		
	   int origW = param->width[0];
	   int origH = param->height[0];
	   int newW = param->width[1];
	   int newH = param->height[1];
	   
	   // int origW = 1280;
	   // int origH = 720;
	   // int newW = 320;
	   // int newH = 180;
	   int gid_x=get_global_id(0);
	   int gid_y=get_global_id(1);
	   float2 coordinate = (float2)(get_global_id(0), get_global_id(1)) + (float2)(0.5f);
	   
	   int2 outCoordinate = (int2)(get_global_id(0), get_global_id(1));
	   
	   float2 norCoor = ((float2)(get_global_id(0), get_global_id(1)) + (float2)(0.5f))/(float2)(newW,newH);
	   
	   float2 origCenter = (float2)(newW,newH)/2.0f;
	   
	   float nW = newW;
	   float nH = newH;
	   float oW = origW;
	   float oH = origH;
	   float2 temCoord = (float2)(0.0f);
	   float4 color= (float4)(0.0f); 
	   float matt; 
	   
	  
	if(reSizeType == 0)
	{		
		float h=oH/nH;
		float w=oW/nW;
		
		float4 result_color=supersampling( src_data,h, w, gid_x, gid_y);
		
		result_color=clamp(result_color,(float4)(0.0f), (float4)(1.0f));
		//result_color=(float4)(1.0f,0.0f,0.0f,1.0f);
		write_imagef(dest_data, outCoordinate, result_color);		
	}
	else{
		if(oH/oW>nH/nW){
			float blackWidth = ( nW-(oW*nH/oH) )/2.0f;
			float h=oH/nH;
			//float w=oW*nH/oH; 
			float w=oH/nH; 
			if( (float)coordinate.x <(blackWidth+oW*nH/oH )){
				float4 result_color=supersampling( src_data,h, w, gid_x, gid_y);
				result_color=clamp(result_color,(float4)(0.0f), (float4)(1.0f));
				outCoordinate.x+=(int)(blackWidth);
				write_imagef(dest_data, outCoordinate, result_color);
			}
		}else{
			float blackHeight = 0.5f*(nH - oH*nW/oW); 
			//float h=oH*nW/oW;
			float h=oW/nW;
			float w=oW/nW;
			if((float)coordinate.y <(blackHeight + oH*nW/oW)){
				float4 result_color=supersampling( src_data,h, w, gid_x, gid_y);
				result_color=clamp(result_color,(float4)(0.0f), (float4)(1.0f));
				
				outCoordinate.y+=(int)(blackHeight);
				write_imagef(dest_data, outCoordinate, result_color);				
			}
		}
		
	}	 
}