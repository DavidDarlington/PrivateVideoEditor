//---------------------------------------------------------------------------------------//
// Designed by RSQ
//---------------------------------------------------------------------------------------//
int mode = PREFIX(mode);
float theta =  PREFIX(theta);
float r0 = PREFIX(r0);	
float g0 = PREFIX(g0);
float b0 = PREFIX(b0);
float r1 = PREFIX(r1);
float g1 = PREFIX(g1);
float b1 = PREFIX(b1);
int channelChoose = PREFIX(channelChoose);

vec4 FUNCNAME(vec2 tc)
{
	vec4 controlChannel = INPUT(tc).bgra;
	vec4 outputCol = vec4(0.0);
	vec2 center = vec2(0.5);
	float r = 0.7;
	theta = -theta;
	float theta0 = radians(theta);
	
	vec2 xy0 = center + r*vec2(cos(theta0),sin(theta0));
	
	float theta1 = radians(theta + 180.0);
	
	vec2 xy1 = center + r*vec2(cos(theta1),sin(theta1));
	
	vec3 decayColor = length(tc - xy0)/1.4 * vec3(r0, g0, b0)  + length(tc - xy1)/1.4 * vec3(r1, g1, b1);
	if(0 == mode) // fill color 
	{
		if( 0 == channelChoose)
		{
			outputCol = vec4(vec3(r0,g0,b0), controlChannel.x);
		}else if(1 == channelChoose)
		{
			outputCol = vec4(vec3(r0,g0,b0), controlChannel.y);
		}else if(2 == channelChoose)
		{
			outputCol = vec4(vec3(r0,g0,b0), controlChannel.z);
		}else{
			outputCol = vec4(vec3(r0,g0,b0), controlChannel.a);
		}
	
	}else 
	{
		if( 0 == channelChoose)
		{
			outputCol = vec4(decayColor, controlChannel.x);
			
		}else if(1 == channelChoose)
		{
			 outputCol = vec4(decayColor, controlChannel.y);
			 
		}else if(2 == channelChoose)
		{
			outputCol = vec4(decayColor, controlChannel.z);
			
		}else{
			
			outputCol = vec4(decayColor, controlChannel.a);	
		}
		
	}
	return outputCol.bgra;
}