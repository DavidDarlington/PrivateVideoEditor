#define MIN(a,b) (((a) < (b)) ? (a) : (b))
#define NEXT(x) (MIN(x+1,mLutDim - 1))
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define rgb xyz
#define rgba xyzw

const sampler_t samplerBG = CLK_NORMALIZED_COORDS_FALSE | CLK_FILTER_NEAREST;
typedef struct PR
{
	float r;
	float g;
	float b;
}PR;
	
static PR findLutPoint(__global float* lut3D, int ir, int ig, int ib)
{

	__global float* index = lut3D  + ir*12675 + ig*195 + ib*3;
	PR pr = {*(index), *(index + 1), *(index + 2)};
	return pr;
	
}
					 
__kernel void MAIN(  __read_only image2d_t src, __write_only image2d_t dest_data, __global float* lut3D, __global float* FT, __global int* GT, int width, int height, unsigned int mLutDim,int alpha)
{
	const float eps = 1.0e-10f;
	int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
	
	float2 resolution = (float2)((float)(width),(float)(height));
	
	float2 fragCoord = (float2)(get_global_id(0), get_global_id(1)) ;
	float2 tc = fragCoord/resolution.xy;
	
	float4 bgCol = read_imagef(src, samplerBG, coordinate);
	uchar r, g, b;
	
	float a = bgCol.w;
	uchar3 rgb = convert_uchar3_sat(bgCol.xyz*255.0f );
	r = rgb.x;
	g = rgb.y;
	b = rgb.z;
	
	PR c000, c001, c010, c011, c100, c101, c110, c111,c;
	float F = 256.f / mLutDim - 1.0f;
	int K = 256 / mLutDim;
	float fr, fg, fb;
	int ir, ig, ib;

	fb = *(FT + b); //FT[b];
	fg = *(FT + g); //FT[g];
	fr = *(FT + r); //FT[r];

	ib = *(GT + b); // GT[b];
	ig = *(GT + g); //GT[g];
	ir = *(GT + r);//GT[r];

	c000 = findLutPoint(lut3D, ir,ig,ib);//lut3D[ir][ig][ib];
	c111 = findLutPoint(lut3D, NEXT(ir),NEXT(ig),NEXT(ib));
	if (fr > fg) {
		if (fg > fb) {
			c100 = findLutPoint(lut3D,NEXT(ir),ig,ib);//lut3D[NEXT(ir)][ig][ib];
			c110 = findLutPoint(lut3D,NEXT(ir),NEXT(ig), ib);//lut3D[NEXT(ir)][NEXT(ig)][ib];
			c.r = (1 - fr) * c000.r + (fr - fg) * c100.r + (fg - fb) * c110.r + (fb)* c111.r;
			c.g = (1 - fr) * c000.g + (fr - fg) * c100.g + (fg - fb) * c110.g + (fb)* c111.g;
			c.b = (1 - fr) * c000.b + (fr - fg) * c100.b + (fg - fb) * c110.b + (fb)* c111.b;
		}
		else if (fr > fb) {
			c100 = findLutPoint(lut3D, NEXT(ir),ig,ib); //lut3D[NEXT(ir)][ig][ib];
			c101 = findLutPoint(lut3D, NEXT(ir), ig, NEXT(ib));//lut3D[NEXT(ir)][ig][NEXT(ib)];
			c.r = (1 - fr) * c000.r + (fr - fb) * c100.r + (fb - fg) * c101.r + (fg)* c111.r;
			c.g = (1 - fr) * c000.g + (fr - fb) * c100.g + (fb - fg) * c101.g + (fg)* c111.g;
			c.b = (1 - fr) * c000.b + (fr - fb) * c100.b + (fb - fg) * c101.b + (fg)* c111.b;
		}
		else {
			c001 = findLutPoint(lut3D, ir, ig, NEXT(ib));//lut3D[ir][ig][NEXT(ib)];
			c101 = findLutPoint(lut3D, NEXT(ir),ig, NEXT(ib)); //lut3D[NEXT(ir)][ig][NEXT(ib)];
			c.r = (1 - fb) * c000.r + (fb - fr) * c001.r + (fr - fg) * c101.r + (fg)* c111.r;
			c.g = (1 - fb) * c000.g + (fb - fr) * c001.g + (fr - fg) * c101.g + (fg)* c111.g;
			c.b = (1 - fb) * c000.b + (fb - fr) * c001.b + (fr - fg) * c101.b + (fg)* c111.b;
			}
	}
	else {
		if (fb > fg) {
			c001 = findLutPoint(lut3D, ir, ig, NEXT(ib)); //lut3D[ir][ig][NEXT(ib)];
			c011 = findLutPoint(lut3D, ir, NEXT(ig), NEXT(ib)); //lut3D[ir][NEXT(ig)][NEXT(ib)];
			c.r = (1 - fb) * c000.r + (fb - fg) * c001.r + (fg - fr) * c011.r + (fr)* c111.r;
			c.g = (1 - fb) * c000.g + (fb - fg) * c001.g + (fg - fr) * c011.g + (fr)* c111.g;
			c.b = (1 - fb) * c000.b + (fb - fg) * c001.b + (fg - fr) * c011.b + (fr)* c111.b;
		}
	    else if (fb > fr) {
			c010 = findLutPoint(lut3D, ir, NEXT(ig), ib);//lut3D[ir][NEXT(ig)][ib];
			c011 = findLutPoint(lut3D, ir, NEXT(ig), NEXT(ib)); //lut3D[ir][NEXT(ig)][NEXT(ib)];
			c.r = (1 - fg) * c000.r + (fg - fb) * c010.r + (fb - fr) * c011.r + (fr)* c111.r;
			c.g = (1 - fg) * c000.g + (fg - fb) * c010.g + (fb - fr) * c011.g + (fr)* c111.g;
			c.b = (1 - fg) * c000.b + (fg - fb) * c010.b + (fb - fr) * c011.b + (fr)* c111.b;
		}
		else {
			c010 = findLutPoint(lut3D, ir, NEXT(ig), ib);// lut3D[ir][NEXT(ig)][ib];
			c110 = findLutPoint(lut3D, NEXT(ir), NEXT(ig), ib); //lut3D[NEXT(ir)][NEXT(ig)][ib];
			c.r = (1 - fg) * c000.r + (fg - fr) * c010.r + (fr - fb) * c110.r + (fb)* c111.r;
			c.g = (1 - fg) * c000.g + (fg - fr) * c010.g + (fr - fb) * c110.g + (fb)* c111.g;
			c.b = (1 - fg) * c000.b + (fg - fr) * c010.b + (fr - fb) * c110.b + (fb)* c111.b;
				}
	}
	
	vec4 outputCol =  (vec4)(0.0f,0.0f, 0.0f, a);

	outputCol.xyz = (vec3)( c.r, c.g, c.b)/255.0f;
    float f_alpha = (float)(alpha)/100.0f;
    float inv_alpha = 1.0f - f_alpha;
    outputCol=bgCol * inv_alpha + outputCol * f_alpha;
	write_imagef(dest_data, coordinate, outputCol);
}
