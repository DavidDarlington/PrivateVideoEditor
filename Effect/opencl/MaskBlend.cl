

__kernel void MAIN(__read_only image2d_t overlay, __read_only image2d_t background, __write_only image2d_t dest_data,  __global FilterParam* param, int type)
{
    const sampler_t samplerOVL = CLK_NORMALIZED_COORDS_TRUE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_NEAREST;
    const sampler_t samplerOVLN = CLK_NORMALIZED_COORDS_FALSE| CLK_ADDRESS_CLAMP_TO_EDGE |CLK_FILTER_NEAREST;
    int2 coordinate = (int2)(get_global_id(0), get_global_id(1));
    int overlayWidth = param->width[0];
	int overlayHeight = param->height[0];
	int backgroundWidth = param->width[1];
	int backgroundHeight = param->height[1];

    float2 resolution = (float2)((float)(param->width[1]),(float)(param->height[1]));//background
	float2 overlayRes = (float2)((float)(param->width[0]),(float)(param->height[0]));

    float2 fragCoord = (float2)(coordinate.x, coordinate.y)+0.5f;
	float2 tc = fragCoord/resolution.xy;

	float2 onePixel = (float2)(1.0f)/resolution.xy;
	
	float4 bgColor = read_imagef(background, samplerOVL, tc);


    int pixelResX = (int)(param->resultROI[0] * resolution.x + 0.5f);
	int pixelResY = (int)(param->resultROI[1] * resolution.y + 0.5f);
	int pixelResWidth = (int)(param->resultROI[2] * resolution.x + 0.5f);
	int pixelResHeight = (int)(param->resultROI[3] * resolution.y + 0.5f);
	
	int pixelOvlX = (int)(param->origROI[0] * overlayRes.x + 0.5f);
	int pixelOvlY = (int)(param->origROI[1] * overlayRes.y + 0.5f);
	int pixelOvlWidth = (int)(param->origROI[2] * overlayRes.x + 0.5f);		
	int pixelOvlHeight = (int)(param->origROI[3] * overlayRes.y + 0.5f);


    float roiX0=param->origROI[0];
    float roiX1=param->origROI[0]+param->origROI[2];
    float roiY0=param->origROI[1];
    float roiY1=param->origROI[1]+param->origROI[3];

    float resultX0 = param->resultROI[0];
	float resultY0 = param->resultROI[1];
	float resultX1 = param->resultROI[2] + param->resultROI[0];
	float resultY1 = param->resultROI[3] + param->resultROI[1];

   float2 resizeCor = (float2)( (pixelOvlWidth )/(float)(pixelResWidth ) *(fragCoord.x - pixelResX) + pixelOvlX,
							   (pixelOvlHeight )/(float)(pixelResHeight ) *(fragCoord.y - pixelResY) + pixelOvlY);
	
	float matt  = step((float)pixelOvlX,resizeCor.x)*step(resizeCor.x, (float)(pixelOvlX + pixelOvlWidth))*step((float)(pixelOvlY),resizeCor.y)*step(resizeCor.y, (float)(pixelOvlY + pixelOvlHeight) );	

    float4 ovlColor = read_imagef(overlay, samplerOVLN, resizeCor)* matt;

    float tempOpacity=0.0;
    float invOpatity=1.0;
    tempOpacity =ovlColor.w;
    invOpatity=1.0-tempOpacity;  
    float4 retColor=(float4)(1.0f,0.0f,0.0f,1.0f);
   if(type==0){       
       if((fabs(tempOpacity) < 1.0e-5f)||(fabs(bgColor.x)<1.0e-5f&&fabs(bgColor.y)<1.0e-5f&&fabs(bgColor.z)<1.0e-5f&&fabs(bgColor.w)<1.0e-5f))
            retColor=(float4)(0.0f);      
        else{
            retColor=(float4)(bgColor.xyz,tempOpacity);
           // retColor=(float4)(1.0f,0.0f,0.0f,1.0f);
           if(fabs(tempOpacity-1.0f)< 1.0e-5f){
               if(fabs(bgColor.w-1.0f)<1.0e-5f){
                   retColor.w=1.0f;
               }else{
                    int col=(int)(bgColor.w*255.0f);
                    col=col/2*2;
                    retColor.w= (float)(col)/255.0f;
               }               
           }else{
               if(fabs(bgColor.w-1.0f)<1.0e-5f)  {            
                    int col = (int)(bgColor.w*tempOpacity/(tempOpacity+ bgColor.w)*255.0f);
                    col=col/2*2+1;//odd num;
                    retColor.w= (float)(col)/255.0f;

                }else{
                    int col = (int)(bgColor.w*tempOpacity/(tempOpacity+ bgColor.w)*255.0f);
                    col=col/2*2;//even num;
                    retColor.w= (float)(col)/255.0f;
                }
           }
        }  
   }else if(type==1){
        float ratio=ovlColor.w/(ovlColor.w+bgColor.w);
        float inv_ratio=1.0f-ratio;
        retColor.xyz= clamp(bgColor.xyz*inv_ratio+ovlColor.xyz*ratio,0.0f,1.0f);
        int col=(int)(bgColor.w*255.0f);
        int ntempOpacity=(int)(tempOpacity*255.0f);
        
        if (col % 2 != 0 && ntempOpacity % 2 != 0)
            retColor.w = 1.0f;
        else
            retColor.w=clamp(ovlColor.w+bgColor.w,0.0f,1.0f);
   }else{
       retColor.xyz=ovlColor.xyz*tempOpacity+bgColor.xyz*invOpatity;
       retColor.w=clamp(ovlColor.w+invOpatity*bgColor.w,0.0f,1.0f);
   }
    write_imagef(dest_data,coordinate,retColor);
}