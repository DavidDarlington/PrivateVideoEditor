#ifdef GL_ES
precision highp float;
#endif
float progress = PREFIX(global_time)/PREFIX(total_time);
vec2 resolution = iResolution;

vec4 FUNCNAME(vec2 tc)
{

  vec4 black = vec4(0.0);
  float fade = 0.5*sin(6.2831852*(progress-0.25))+0.5;
  vec4 outputCol;
  if(progress<0.5)
	outputCol = mix(INPUT1(tc),black,fade);
  else
	outputCol = mix(INPUT2(tc),black,fade);
  
  return outputCol;
}
