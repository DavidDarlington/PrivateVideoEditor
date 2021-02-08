#define MIN(a,b) (((a) < (b)) ? (a) : (b))
#define NEXT(x) (MIN(x+1,mLutDim - 1))
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw

const sampler_t sampler1 = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;
const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;
					 
__kernel void LUT(__read_only image2d_t src, __read_only image2d_t texture,__write_only image2d_t dest_data,int lutDim,int lutCol,int lutRow)
{
    int2 coord = (int2)(get_global_id(0), get_global_id(1));
    float4 input = read_imagef(src, sampler, coord);   
    float4 OutColor=input;
    float f_lutDim=(float)(lutDim);
    float f_lutCol=(float)(lutCol);
    float f_lutRow=(float)(lutRow);
	float blueColor = OutColor.z * (f_lutRow * f_lutCol - 1.0f);
	
    vec2 quad1;
    quad1.y = floor(floor(blueColor) / f_lutCol);
    quad1.x = floor(blueColor) - (quad1.y * f_lutCol);
		
    vec2 quad2;
    quad2.y = floor(ceil(blueColor) / f_lutCol);
    quad2.x = ceil(blueColor) - (quad2.y * f_lutCol);
    
    float xOff = 1.0f / f_lutCol;
    float yOff = 1.0f / f_lutRow;
    float tex_w = f_lutDim * f_lutCol;
    float tex_h = f_lutDim * f_lutRow;
    
    vec2 texPos1;
    texPos1.x = (quad1.x * xOff) + 0.5 / tex_w + ((xOff - 1.0f / tex_w) * OutColor.x);
    texPos1.y = (quad1.y * yOff) + 0.5 / tex_h + ((yOff - 1.0f / tex_h) * OutColor.y);
    
    vec2 texPos2;
    texPos2.x = (quad2.x * xOff) + 0.5 / tex_w + ((xOff - 1.0f / tex_w) * OutColor.x);
    texPos2.y = (quad2.y * yOff) + 0.5 / tex_h + ((yOff - 1.0f / tex_h) * OutColor.y);
    
    
    vec4 newColor1 = read_imagef(texture, sampler1,texPos1);
    vec4 newColor2 = read_imagef(texture,sampler1,texPos2);
    float ptr = 0.0f;
    OutColor = mix(newColor1, newColor2, fract(blueColor,&ptr));  
    OutColor.w=input.w; 
    //OutColor = mix(input, (vec4)(OutColor.xyz, input.w), 1.0f);
	write_imagef(dest_data, coord, OutColor);
}
