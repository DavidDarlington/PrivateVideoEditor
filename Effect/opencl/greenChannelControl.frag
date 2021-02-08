//---------------------------------------------------------------------------------------//
// Designed by RSQ
//---------------------------------------------------------------------------------------//

vec4 FUNCNAME(vec2 tc)
{	
	vec4 controlChannel = INPUT2(tc);
	vec4 col = INPUT1(tc);
	vec4 outputCol = vec4(col.xyz, controlChannel.y);
	return outputCol;
}
