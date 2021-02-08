constant sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;
constant sampler_t sampler_zero = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST;
constant sampler_t sampler_nor = CLK_NORMALIZED_COORDS_TRUE|CLK_ADDRESS_CLAMP|CLK_FILTER_LINEAR;
typedef struct
{
	int width[8];
	int height[8];
	float cur_time;
	float total_time;
	float origROI[4];
	float resultROI[4];
	float angle;
}FilterParam;


__kernel void make_mark(__read_only image2d_t src, __write_only image2d_t dst, float start_B, float start_G, float start_R,
	float end_B, float end_G, float end_R, int nAlpha, int uDirect)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(dst);
	int h = get_image_height(dst);

	if (coord.x >= w || coord.y >= h)
		return;

	float3 start_color = (float3)(start_R, start_G, start_B);
	float3 end_color = (float3)(end_R, end_G, end_B);
	start_color /= 255.0f;
	end_color /= 255.0f;

	float4 val = (float4)(0, 0, 0, 0);

	if (start_color.x == end_color.x && start_color.y == end_color.y && start_color.z == end_color.z)
	{
		val.xyz = start_color;
	}
	else
	{
		switch (uDirect)
		{
		case 2:{
				   float3 dif = end_color - start_color;
				   float3 dif_step = dif / h;
				   val.xyz = start_color + dif_step*coord.y;         } break;//down

		case 3:{

				   float3 dif = end_color - start_color;
				   float3 dif_step = dif / w;
				   val.xyz = start_color + dif_step * coord.x;       } break;//left

		case 0:{
				   float3 dif = start_color - end_color;
				   float3 dif_step = dif / h;
				   val.xyz = end_color + dif_step * coord.y;       }break;//top

		case 1:{
				   float3 dif = start_color - end_color;
				   float3 dif_step = dif / w;
				   val.xyz = end_color + dif_step * coord.x;		  }break;//right

		case 5:{
				   float nDiagonal = w*w + h*h;
				   float3 nsub = end_color - start_color;
				   float fSetp = (float)(coord.x * w + (h - coord.y - 1) * h) / nDiagonal;
				   val.xyz = start_color + nsub * fSetp;              }break;//left_down

		case 4:{
				   float nDiagonal = w*w + h*h;
				   float3 nsub = start_color - end_color;
				   float fSetp = (float)(coord.x*w + coord.y*h) / nDiagonal;
				   val.xyz = end_color + nsub * fSetp;           } break;//right_down

		case 7:{
				   float nDiagonal = w*w + h*h;
				   float3 nsub = end_color - start_color;
				   float fSetp = (float)(coord.x*w + coord.y  * h) / nDiagonal;
				   val.xyz = start_color + nsub * fSetp;    			  	} break;//left_top

		case 6:{
				   float nDiagonal = w*w + h*h;
				   float3 nsub = start_color - end_color;
				   float fSetp = (float)(coord.x * w + (h - coord.y - 1) *h) / nDiagonal;
				   val.xyz = end_color + nsub * fSetp;    				} break;//right_top

		default:
			break;
                
		}
	}

	float4 input = read_imagef(src, sampler, coord);
	val.w = input.w * nAlpha / 100;
	write_imagef(dst, coord, val);
}


__kernel void dilating_1(__read_only image2d_t src, __write_only image2d_t dst, int size)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = read_imagef(src, sampler, (int2)(coord.x, coord.y));
	val.w = 0;
	for (int i = -size; i <= size; i++)
	{
		float4 b = read_imagef(src, sampler, (int2)(coord.x + i, coord.y));
		if (b.w > val.w)
		{
			val = b;
		}
	}
	write_imagef(dst, coord, val);
}


__kernel void dilating_2(__read_only image2d_t src, __write_only image2d_t dst, int size)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = read_imagef(src, sampler, (int2)(coord.x, coord.y));
	val.w = 0;

	for (int i = -size; i <= size; i++)
	{
		float4 b = read_imagef(src, sampler, (int2)(coord.x, coord.y + i));
		if (b.w > val.w)
		{
			val = b;
		}
	}

	write_imagef(dst, coord, val);
}

__kernel void erode_1(__read_only image2d_t src, __write_only image2d_t dst, int size)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = read_imagef(src, sampler, (int2)(coord.x, coord.y));

	val.w = 1;
	for (int i = -size; i <= size; i++)
	{
		float4 b = read_imagef(src, sampler_zero, (int2)(coord.x + i, coord.y));
		if (b.w < val.w)
		{
			val.w = b.w;
		}
	}
	
	write_imagef(dst, coord, val);
}


__kernel void erode_2(__read_only image2d_t src, __write_only image2d_t dst, int size)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = read_imagef(src, sampler, (int2)(coord.x, coord.y));

	val.w = 1;
	for (int i = -size; i <= size; i++)
	{
		float4 b = read_imagef(src, sampler_zero, (int2)(coord.x, coord.y + i));
		if (b.w < val.w)
		{
			val.w = b.w;
		}
	}
	write_imagef(dst, coord, val);
}


__kernel void clear(__write_only image2d_t dst)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(dst);
	int h = get_image_height(dst);

	if (coord.x >= w || coord.y >= h)
		return;
	float4 val = (float4)(0, 0, 0, 0);
	write_imagef(dst, coord, val);
}

__kernel void copy(__read_only image2d_t src, __write_only image2d_t dst)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(dst);
	int h = get_image_height(dst);

	if (coord.x >= w || coord.y >= h)
		return;
	float4 val = read_imagef(src, sampler, coord);
	write_imagef(dst, coord, val);
}
__kernel void img_set_val(__write_only image2d_t dst,int B, int G, int R)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(dst);
	int h = get_image_height(dst);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val ;
	val.x=(float)B/255.0f;
	val.y=(float)G/255.0f;
	val.z=(float)R/255.0f;
	val.w=0;
	write_imagef(dst, coord, val);
}

__kernel void img_set(__read_only image2d_t src,__write_only image2d_t dst,int B, int G, int R, int nAlpha,int temp_x_add_val,int temp_y_add_val,int roi_x,int roi_y)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(dst);
	int h = get_image_height(dst);

	if (coord.x >= w || coord.y >= h)
		return;
	float4 val=(float4)(0,0,0,0) ;
	val.w =0.0f;
	val.x=B/255.0f;
	val.y=G/255.0f;
	val.z=R/255.0f;

	int2 dst_coord = coord +(int2)(roi_x+temp_x_add_val,roi_y+temp_y_add_val);
	int2 src_coord = coord +(int2)(roi_x,roi_y);
	float4 src_a = read_imagef(src, sampler, src_coord);
	val.w = src_a.w*nAlpha/100.0f;
	val.xyz = val.xyz * val.w;
	val = clamp(val,(float4)(0.0f,0.0f,0.0f,0.0f),(float4)(1.0f,1.0f,1.0f,1.0f));
	write_imagef(dst, dst_coord, val);
}


__kernel void copy_to_dst_roi(__read_only image2d_t src,__read_only image2d_t src1, __write_only image2d_t dst, int temp_x, int temp_y)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);
	int2 shift_coord;
	shift_coord.x = coord.x+temp_x;
	shift_coord.y = coord.y+temp_y;
	if (coord.x >= w || coord.y >= h)
		return;
	float4 src_data = read_imagef(src, sampler, coord);
	float4 src1_data =read_imagef(src1, sampler, shift_coord);
	float4 val =(float4)(0,0,0,0);
	val.xyz = src_data.w*src_data.xyz+(1-src_data.w)*src1_data.xyz;
	val.w= src_data.w+(1-src_data.w)*src1_data.w;
	val.xyz /=val.w;
	val = clamp(val,(float4)(0.0f,0.0f,0.0f,0.0f),(float4)(1.0f,1.0f,1.0f,1.0f));
	write_imagef(dst, shift_coord, val);
}

__kernel void fore_backaddshadow_to_dst(__read_only image2d_t src,__read_only image2d_t buffer,__read_only image2d_t backImg, __write_only image2d_t dst, int fx, int fy,int bx,int by)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);
	int2 f_coord;
	f_coord.x = coord.x+fx;
	f_coord.y = coord.y+fy;
	
	int2 b_coord;
	b_coord.x = coord.x+bx;
	b_coord.y = coord.y+by;
		
	if (coord.x >= w || coord.y >= h)
		return;
		
	float4 src_data = read_imagef(src, sampler, f_coord);
	float4 buffer_data =read_imagef(buffer, sampler, b_coord);
	float4 backImg_data =read_imagef(backImg, sampler, b_coord);
	//In order to get the same result as CPU
	uchar4 buffer_color = (uchar4)(buffer_data.x*255.0f,buffer_data.y*255.0f,buffer_data.z*255.0f,buffer_data.w*255.0f);
	uchar4 back_color = (uchar4)(backImg_data.x*255.0f,backImg_data.y*255.0f,backImg_data.z*255.0f,backImg_data.w*255.0f);
	float4 val =(float4)(0.0f);
	val.x = (uchar)(src_data.w*back_color.x+(1-src_data.w)*buffer_color.x)/255.0f;
	val.y = (uchar)(src_data.w*back_color.y+(1-src_data.w)*buffer_color.y)/255.0f;
	val.z = (uchar)(src_data.w*back_color.z+(1-src_data.w)*buffer_color.z)/255.0f;
	val.w = (uchar)(src_data.w*back_color.w+(1-src_data.w)*buffer_color.w)/255.0f;

	write_imagef(dst, b_coord, val);
}


__kernel void copy_to_roi(__read_only image2d_t src, __write_only image2d_t dst, int val_x,int val_y)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);
	int2 shift_coord;
	shift_coord.x = coord.x+val_x;
	shift_coord.y = coord.y+val_y;
	if (coord.x >= w || coord.y >= h)
		return;
	float4 src_data = read_imagef(src, sampler, coord);
	write_imagef(dst, shift_coord, src_data);
}

__kernel void roi_copy_to(__read_only image2d_t src, __write_only image2d_t dst, int val_x,int val_y)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);
	int2 shift_coord;
	shift_coord.x = coord.x+val_x;
	shift_coord.y = coord.y+val_y;
	if (coord.x >= w || coord.y >= h)
		return;
	float4 src_data = read_imagef(src, sampler, shift_coord);
	write_imagef(dst, coord, src_data);
}

__kernel void merge(__read_only image2d_t src, __read_only image2d_t mark, __write_only image2d_t dst)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 src_data = read_imagef(src, sampler, coord);
	float4 mark_data = read_imagef(mark, sampler, coord);
	if (src_data.w == 0)
	{
		src_data = mark_data;
		if (mark_data.w == 0)
		{
			src_data = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
		}
	}

	write_imagef(dst, coord, src_data);
}

__kernel void merge2(__read_only image2d_t src, __read_only image2d_t mark, __write_only image2d_t dst)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 src_data = read_imagef(src, sampler, coord);
	float4 mark_data = read_imagef(mark, sampler, coord);

	src_data = (1- (1-src_data.w)*mark_data.w )*src_data + (1-src_data.w)*mark_data.w *mark_data;
	//src_data.w =1;
	write_imagef(dst, coord, src_data);
}

__kernel void meanfilter_1(__read_only image2d_t src, __write_only image2d_t dst, int size)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = (float4)(0, 0, 0, 0);

	for (int i = -size; i <= size; i++)
	{
		val += read_imagef(src, sampler, (int2)(coord.x + i, coord.y));
	}

	int len = 2 * size + 1;
	val = val / len;
	write_imagef(dst, coord, val);
}


__kernel void meanfilter_2(__read_only image2d_t src, __write_only image2d_t dst, int size)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = (float4)(0, 0, 0, 0);

	for (int i = -size; i <= size; i++)
	{
		val += read_imagef(src, sampler, (int2)(coord.x, coord.y + i));
	}

	int len = 2 * size + 1;
	val = val / len;
	write_imagef(dst, coord, val);
}

__kernel void meanfilter_a1(__read_only image2d_t src, __write_only image2d_t dst, int size)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = read_imagef(src, sampler_zero, (int2)(coord.x , coord.y));
	val.w = 0;
	for (int i = -size; i <= size; i++)
	{
		val.w += read_imagef(src, sampler_zero, (int2)(coord.x + i, coord.y)).w;
	}

	int len = 2 * size + 1;
	val.w = val.w / len;
	write_imagef(dst, coord, val);
}

__kernel void meanfilter_T(__read_only image2d_t src, __write_only image2d_t dst, int size)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = read_imagef(src, sampler_zero, (int2)(coord.x , coord.y));
	val.w = 0;
	for (int i = -size; i <= size; i++)
	{
		val.w += read_imagef(src, sampler_zero, (int2)(coord.x + i, coord.y)).w;
	}

	int len = 2 * size + 1;
	val.w = val.w / len;
	
	int2 coord_t;
	coord_t.x = coord.y;
	coord_t.y = coord.x;
	write_imagef(dst, coord_t, val);
}

__kernel void meanfilter_a2(__read_only image2d_t src, __write_only image2d_t dst, int size)
{
	int2 coord = (int2)(get_global_id(0), get_global_id(1));
	int w = get_image_width(src);
	int h = get_image_height(src);

	if (coord.x >= w || coord.y >= h)
		return;

	float4 val = read_imagef(src, sampler_zero, (int2)(coord.x, coord.y));
	val.w = 0;
	for (int i = -size; i <= size; i++)
	{
		val.w += read_imagef(src, sampler_zero, (int2)(coord.x, coord.y + i)).w;
	}

	int len = 2 * size + 1;
	val.w = val.w / len;
	write_imagef(dst, coord, val);
}

__kernel void image_scaling(__read_only image2d_t sourceImage,__write_only image2d_t dstImage,const float widthNormalizationFactor,const float heightNormalizationFactor)
{
	int2 coord  = (int2)(get_global_id(0),get_global_id(1));
	float2 normalizedCoordinate = convert_float2(coord)*(float2)(widthNormalizationFactor,heightNormalizationFactor);
	float4 colour =read_imagef(sourceImage,sampler_nor,normalizedCoordinate);
	write_imagef(dstImage,coord,colour);
}

float4 colorDodge(float4 bgCol, float4 overlay )
{
	float4 outputColor = bgCol/(1.0f - overlay);
	
	if(overlay.x >0.99999f)
		outputColor.x = 1.0f;
	if(overlay.y >0.99999f)
		outputColor.y = 1.0f;
	if(overlay.z >0.99999f)
		outputColor.z = 1.0f;
	
	return outputColor;
}

float4 colorBurn(float4 bgCol, float4 overlay )
{
	
	float4 outputColor = 1.0f - (1.0f-bgCol) / overlay; 
			
	if(overlay.x < 0.000001f)
		outputColor.x = 0.0f;
	if(overlay.y < 0.000001f)
		outputColor.y = 0.0f;
	if(overlay.z < 0.000001f)
		outputColor.z = 0.0f;
	return outputColor;
}

float4 colorDodgeForHardMix(float4 bgCol, float4 overlay )
{
	float4 outputColor = bgCol/(1.0f - overlay);
	
	if(bgCol.x < 0.000001f)
		outputColor.x = 0.0f;
	if(bgCol.y < 0.000001f)
		outputColor.y = 0.0f;
	if(bgCol.z < 0.000001f)
		outputColor.z = 0.0f;
	
	return outputColor;
}

float4 colorBurnForHardMix(float4 bgCol, float4 overlay )
{
	
	float4 outputColor = 1.0f - (1.0f-bgCol) / overlay; 
			
	if(bgCol.x > 0.9999999f)
		outputColor.x = 1.0f;
	if(bgCol.y > 0.9999999f)
		outputColor.y = 1.0f;
	if(bgCol.z > 0.9999999f)
		outputColor.z = 1.0f;
	return outputColor;
}

//tempMatt: matt without alpha
//matt: matt with altph.

float4 blending(float4 backGround, float4 ovl, float matt, float tempMatt, float exeMatt, int blendingMode, float opacity, int ovlAlphaPreMul)
{
	
	float4 outputColor = (float4)(0.0f);
	float4 overlay = ovl * tempMatt * exeMatt; 
	float4 bgCol = backGround;
	float tempOpacity = opacity * matt * exeMatt;
	float invTemOpacity = 1.0f - tempOpacity;
	switch(blendingMode)
	{
		case 0:// normal,
			//bgCol = (float4)(bgCol.xyz*bgCol.w, bgCol.w);			
			outputColor = overlay;
			if(ovlAlphaPreMul == 0)
			{				
                outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
			    outputColor.w = tempOpacity + invTemOpacity* bgCol.w;
                outputColor.xyz = outputColor.xyz*tempOpacity + invTemOpacity*bgCol.xyz;
                outputColor.xyz = clamp( outputColor.xyz, (float3)(0.0f), (float3)(1.0f) );
        
                return outputColor; 
			}else{
				
                outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
                outputColor.w = tempOpacity + invTemOpacity* bgCol.w;
                float fOpacity = opacity * tempMatt;
                outputColor.xyz = outputColor.xyz*fOpacity + invTemOpacity*bgCol.xyz;
                outputColor.xyz = clamp( outputColor.xyz, (float3)(0.0f), (float3)(1.0f) );        
                return outputColor;                 
			}
			
			
	
		case 1: // Darken
			outputColor = min(overlay,bgCol);
			break;
		case 2: //multiply
			outputColor = bgCol * overlay; 
			break;
		case 3: //  color burn // 1 - (1-Target) / Blend
		{
				float4 temp = (1.0f-bgCol) / overlay; 
				if(bgCol.x > 0.99999f)
					temp.x = 0.0f;
				if(bgCol.y > 0.99999f)
					temp.y = 0.0f;
				if(bgCol.z > 0.99999f)
					temp.z = 0.0f;
				outputColor = 1.0f - temp ;
		}
			break;
		case 4: // Linear burn
			outputColor = overlay + bgCol -1.0f;
			break;
		case 5: //screen
			outputColor =  1.0f - (1.0f-bgCol)*(1.0f-overlay);
			break;
		case 6: //color dodge
		{
			outputColor = bgCol/(1.0f - overlay);
		
			 if (bgCol.x < 0.00001f)
				outputColor.x = 0.0f;
			if (bgCol.y < 0.00001f)
				outputColor.y = 0.0f;
			if (bgCol.z < 0.00001f)
				outputColor.z = 0.0f;
		}
			break ;
		case 7://Linear Dodge
			outputColor = overlay + bgCol;
			break;
		case 8: //overlay // (Target > 0.5f) * (1 - (1-2*(Target-0.5)) * (1-Blend)) + (Target <= 0.5f) * ((2*Target) * Blend)
		{
			float3 a = (float3)( (bgCol.x > 0.5f?1.0f:0.0f), (bgCol.y > 0.5f?1.0f:0.0f), (bgCol.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)((bgCol.x <=  0.5f?1.0f:0.0f), (bgCol.y <=  0.5f?1.0f:0.0f), (bgCol.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a * (1.0f - (1.0f-2.0f*(bgCol.xyz-0.5f)) * (1.0f-overlay.xyz)) + b * ((2.0f*bgCol.xyz) * overlay.xyz);
		}
			break;
		case 9: //Soft Light // 
		{
			float3 a = (float3)( (overlay.x > 0.5f?1.0f:0.0f), (overlay.y > 0.5f?1.0f:0.0f),  (overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (overlay.x <=  0.5f?1.0f:0.0f), (overlay.y <=  0.5f?1.0f:0.0f),  (overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a * (2.0f*bgCol.xyz*(1.0f - overlay.xyz) + sqrt(bgCol.xyz)*(2.0f*overlay.xyz - 1.0f)) \
							+ b * (2.0f*bgCol.xyz*overlay.xyz + bgCol.xyz*bgCol.xyz*(1.0f - 2.0f*overlay.xyz));
		}
			break;	
		case 10://Hard Light //(Blend > 0.5) * (1 - (1-Target) * (1-2*(Blend-0.5))) + (Blend <= 0.5) * (Target * (2*Blend))
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a * (1.0f - (1.0f-bgCol.xyz) * (1.0f-2.0f*(overlay.xyz-0.5f))) + b * (bgCol.xyz * (2.0f*overlay.xyz));

			break;
		}		
		case 11://vivid light //// (Blend > 0.5) * (1 - (1-Target) / (2*(Blend-0.5))) + (Blend <= 0.5) * (Target / (1-2*Blend))
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			
			outputColor.xyz = b * colorBurn(bgCol,(2.0f*overlay)).xyz + a * colorDodge(bgCol, (2.0f*(overlay - 0.5f))).xyz;
			
		}
			break;
		case 12:// Linear Light//  (Blend > 0.5) * (Target + 2*(Blend-0.5)) + (Blend <= 0.5) * (Target + 2*Blend - 1)
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a* (bgCol.xyz + 2.0f*(overlay.xyz - 0.5f)) + b* (bgCol.xyz + 2.0f*overlay.xyz - 1.0f);
		}
			break;
			
		case 13: //PIN Light// (Blend > 0.5) * (max(Target,2*(Blend-0.5))) + (Blend <= 0.5) * (min(Target,2*Blend)))
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = a* (max(bgCol.xyz,2.0f*(overlay.xyz-0.5f))) + b * (min(bgCol.xyz, 2.0f*overlay.xyz));
		}
			break;
		case 14: // hardmix  (VividLight(A,B) < 128) ? 0 : 255
		{
			float3 a = (float3)( (float)(overlay.x > 0.5f?1.0f:0.0f), (float)(overlay.y > 0.5f?1.0f:0.0f),  (float)(overlay.z > 0.5f?1.0f:0.0f) );
			float3 b = (float3)( (float)(overlay.x <=  0.5f?1.0f:0.0f), (float)(overlay.y <=  0.5f?1.0f:0.0f),  (float)(overlay.z <=  0.5f?1.0f:0.0f) );
			outputColor.xyz = b * colorBurnForHardMix(bgCol,(2.0f*overlay)).xyz + a * colorDodgeForHardMix(bgCol, (2.0f*(overlay - 0.5f))).xyz;
			outputColor.xyz = (float3)( (float)(outputColor.x >= 0.5f?1.0f:0.0f), (float)(outputColor.y >= 0.5f?1.0f:0.0f),(float)(outputColor.z >= 0.5f?1.0f:0.0f));
			//outputColor.xyz = (float3)( (float)(overlay.x + bgCol.x >= 1.0f?1.0f:0.0f), (float)(overlay.y + bgCol.y >= 1.0f?1.0f:0.0f),(float)(overlay.z + bgCol.z >= 1.0f?1.0f:0.0f));
		}
			break;
			
		case 15://Difference
			outputColor = fabs( overlay - bgCol );
			break;
		case 16://exclusion // 0.5 - 2*(Target-0.5)*(Blend-0.5)
			outputColor = 0.5f - 2.0f*(overlay-0.5f)*(bgCol-0.5f);
			break;
		case 17://Lighten // max(Target,Blend)   
			outputColor = max(overlay,bgCol);
			break;
			
		case 19: // hollow in 
			outputColor = bgCol*overlay.w;
			outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
			return outputColor;
			break;
		case 20: // hollow out 
			outputColor = bgCol;
			if(bgCol.w < 0.000001f)
				outputColor = overlay;
			else 
				outputColor = bgCol*(1.0f - overlay.w);
			outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
			return outputColor;
			break;
		case 21: // backGround hollow in 
			outputColor = overlay*bgCol.w;
			outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
			return outputColor;
			break;
		case 22: // replace
			if(tempMatt * exeMatt > 0.0001f)
				return (float4)(overlay.xyz, overlay.w);
			 else 
				return bgCol;
		default:
			//bgCol = (float4)(bgCol.xyz*bgCol.w, bgCol.w);
			outputColor = overlay;		
			outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
			outputColor.w = tempOpacity + invTemOpacity* bgCol.w;
            float fOpacity = opacity * tempMatt;
			outputColor.xyz = outputColor.xyz*fOpacity + invTemOpacity*bgCol.xyz;
			outputColor.xyz = clamp( outputColor.xyz, (float3)(0.0f), (float3)(1.0f) );
	
			return outputColor; 
	}
	
	outputColor = clamp(outputColor,(float4)(0.0f), (float4)(1.0f));
	//outputColor.w = overlay.w + (1.0f - overlay.w)* bgCol.w;
	outputColor.w = tempOpacity + invTemOpacity* bgCol.w;
    float fOpacity = opacity * tempMatt;
	outputColor.xyz = outputColor.xyz*tempOpacity + invTemOpacity*bgCol.xyz;
	//outputColor.xyz = outputColor.xyz*fOpacity + invTemOpacity*bgCol.xyz;
	outputColor.xyz = clamp( outputColor.xyz, (float3)(0.0f), (float3)(1.0f) );
	
	return outputColor; 
	
}
__kernel void blend_main(__read_only image2d_t overlay, __read_only image2d_t background, __write_only image2d_t dest_data,  __global FilterParam* param, int blendingMode, float kRender_Alpha, int ovlAlphaPreMul,int ovlResize,int samperType)
{
	//ovlResize  overlay need resize 0--no resize 1--resize   samperType sampler type default nearest
	const sampler_t samplerBG = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST; 
	const sampler_t samplerOVL = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_NEAREST;
	const sampler_t samplerOVLN = CLK_NORMALIZED_COORDS_FALSE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_NEAREST;
	
	const float eps = 1.0e-10f;
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));

	int overlayWidth = param->width[0];
	int overlayHeight = param->height[0];
	int backgroundWidth = param->width[1];
	int backgroundHeight = param->height[1];


	float2 resolution = (float2)((float)(param->width[1]),(float)(param->height[1]));
	float2 overlayRes = (float2)((float)(param->width[0]),(float)(param->height[0]));
	
	float2 fragCoord = (float2)(coordinate.x, coordinate.y)+0.5f;
	float2 tc = fragCoord/resolution.xy;
	float2 tempTc = tc;
	float2 tempTcExe = tc;  
	float2 onePixel = (float2)(1.0f)/resolution.xy;
	
	float4 bgCol = read_imagef(background, samplerBG, tempTc);

	
	float4 ovlCol; 

	// when  theta is zero, using resize to avoid the one pixel tolerance at the edge.
	float pixelResX = (float)(param->resultROI[0] * resolution.x);
	float pixelResY = (float)(param->resultROI[1] * resolution.y);
	float pixelResWidth = (float)(param->resultROI[2] * resolution.x);
	float pixelResHeight = (float)(param->resultROI[3] * resolution.y);
	//no resize 
	float pixelOvlX = 0.0f;
	float pixelOvlY = 0.0f;
	float pixelOvlWidth = 0.0f;
	float pixelOvlHeight = 0.0f;
	if(ovlResize == 0){
		pixelOvlX = (float)(param->origROI[0] * overlayRes.x);
		pixelOvlY = (float)(param->origROI[1] * overlayRes.y);
		}
	else {
		//resize from original, ignore roi.x roi.y
		pixelOvlX=0.0;
		pixelOvlY=0.0;
	}
		pixelOvlWidth = (float)(param->origROI[2] * overlayRes.x);
		pixelOvlHeight = (float)(param->origROI[3] * overlayRes.y);
	
	
	if(pixelResWidth <= 2.0f || pixelResHeight <= 2.0f)
	{
		write_imagef(dest_data, coordinate, bgCol);
		return;
	}
	//
	float2 resizeCor = (float2)( (pixelOvlWidth )/(float)(pixelResWidth ) *(fragCoord.x - pixelResX) + pixelOvlX,
							   (pixelOvlHeight )/(float)(pixelResHeight ) *(fragCoord.y - pixelResY) + pixelOvlY
							  );
	
	float matt  = step((float)pixelOvlX,resizeCor.x)*step(resizeCor.x, (float)(pixelOvlX + pixelOvlWidth))*step((float)(pixelOvlY),resizeCor.y)*step(resizeCor.y, (float)(pixelOvlY + pixelOvlHeight) );	
	ovlCol = read_imagef(overlay, samplerOVLN, resizeCor);
	
	float tempMatt = matt;
	matt = matt*ovlCol.w;
	
	float4 outputCol = blending( bgCol, ovlCol, matt, tempMatt, 1.0f, blendingMode, kRender_Alpha, ovlAlphaPreMul);
	write_imagef(dest_data, coordinate, outputCol);
}