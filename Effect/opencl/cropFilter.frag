//#define GL_NEED_MIPMAPS
#ifdef GL_ES
precision highp float;
#endif
#define PI 3.1415926535897932
	
float left = float( PREFIX(left) )/100.0;
float right = float( 100 - PREFIX(right) )/100.0;
float top =  float( PREFIX(top) )/100.0;
float bottom = float( 100 - PREFIX(bottom) )/100.0;
int autoZoom = PREFIX(autoZoom);
int blurEdges = PREFIX(blurEdges);

vec2 rotateFunc(vec2 uv, vec2 center, float theta)
{
	vec2 temp;
	temp.x = dot(vec2(cos(theta), -sin(theta)), uv - center);
	temp.y = dot(vec2(sin(theta), cos(theta)), uv - center);
	return (temp+center);
}

vec4 FUNCNAME(vec2 tc) {
	
	vec2 uv= vec2(tc.x, 1.0 - tc.y);//gl_FragCoord.xy/iResolution.xy;
	vec2 resolution = iResolution.xy;
	float inputW = iResolution.x;
	float inputH = iResolution.y;
	float rdTheta = 0.0;
	vec2 intputResolution = vec2(inputW,inputH);
	vec2 ouputResolution = vec2(inputW,inputH);
	vec2 fragCoord =  resolution * uv;
	vec4 color;
	
	float blurPixel = 10.0;
	if(blurEdges == 0)
		blurPixel = 0.0001;
		
	float xLogic = 0.0;
	float yLogic = 0.0;
	float featherMatt = 0.0;
	vec4 outputColor;
	vec2 tranformCoord;
	vec2 tempLogicCoord;
	
	vec2 center = vec2(left + 0.5*(right-left));

	if(autoZoom == 1)
	{	
		
		xLogic = smoothstep(-1.0, -1.0 + blurPixel, fragCoord.x) * (1.0 - smoothstep(inputW + 1.0 - blurPixel, inputW + 1.0, fragCoord.x));
		yLogic = smoothstep(-1.0, -1.0 + blurPixel, fragCoord.y) * (1.0 - smoothstep(inputH + 1.0 - blurPixel, inputH + 1.0, fragCoord.y) );
		
		tranformCoord.x = uv.x*(right - left) + left;
		tranformCoord.y = uv.y*(bottom - top) + top;

		tranformCoord = rotateFunc(intputResolution.xy*tranformCoord,intputResolution.xy*center,rdTheta)/intputResolution.xy;
		
		float matt = step(0.0,tranformCoord.x)*step(tranformCoord.x, 1.0)*step(0.0,tranformCoord.y)*step(tranformCoord.y, 1.0);
		
		color = INPUT(vec2(tranformCoord.x, 1.0 - tranformCoord.y))*matt;
		featherMatt = yLogic*xLogic;
		outputColor = color*featherMatt;
	}else
	{
		
		xLogic = smoothstep(left, left + blurPixel/intputResolution.x, uv.x) * (1.0 - smoothstep(right - blurPixel/intputResolution.x, right, uv.x));
		yLogic = smoothstep(top, top + blurPixel/intputResolution.y, uv.y) * (1.0 - smoothstep(bottom - blurPixel/intputResolution.y, bottom, uv.y) );

		uv = rotateFunc(uv*ouputResolution.xy , ouputResolution.xy*center , rdTheta)/ouputResolution.xy;
		float matt = step(0.0,uv.x)*step(uv.x, 1.0)*step(0.0,uv.y)*step(uv.y, 1.0);
		color = INPUT(vec2(uv.x, 1.0 - uv.y))*matt;
		featherMatt = yLogic*xLogic;
		outputColor = color*featherMatt;
	}
	if( left > right || top > bottom )
        return vec4(0.0);
    else
        return outputColor;
}
