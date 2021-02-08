

#define M_SQRT1_3_F 0.577350
#define M_SQRT1_6_F 0.408248
#define EPSILON			0.03
#define M_SQRT1_2_F  0.707106781
#define ZERO_EPS 0.00001

vec3 rgb2lms(vec3 rgb){
    vec3 lms;
    lms.x = 0.0402 * rgb.z + 0.5783 * rgb.y + 0.3811 * rgb.x;
    lms.y = 0.0782 * rgb.z + 0.7244 * rgb.y + 0.1967 * rgb.x;
    lms.z = 0.8444 * rgb.z + 0.1288 * rgb.y + 0.0241 * rgb.x;
    return lms;
}
vec3 lms2lab(vec3 lms){
    vec3 lab;
    lab.x = M_SQRT1_3_F*(lms.x + lms.y + lms.z);
    lab.y = M_SQRT1_6_F*(lms.x + lms.y) -2.0 * M_SQRT1_6_F * lms.z;
    lab.z = M_SQRT1_2_F*(lms.x - lms.y);
    return lab;
}
vec3 lab2lms(vec3 lab){
    vec3 lms;
    lms.x = M_SQRT1_3_F * lab.x + M_SQRT1_6_F * lab.y + M_SQRT1_2_F * lab.z;
    lms.y = M_SQRT1_3_F * lab.x + M_SQRT1_6_F * lab.y - M_SQRT1_2_F * lab.z;
    lms.z = M_SQRT1_3_F * lab.x - 2.0 * M_SQRT1_6_F * lab.y ;
    return lms;
}
vec3 lms2rgb(vec3 lms){
    vec3 rgb;
    rgb.z = 0.0497 * lms.x-0.2439*lms.y+ 1.2045*lms.z;
    rgb.y = -1.2186 * lms.x+2.3809*lms.y-0.1624*lms.z;
    rgb.x = 4.4679 * lms.x-3.5873*lms.y+0.1193*lms.z;
    return rgb;
}
vec4 FUNCNAME(vec2 tc)
{	
	tc= vec2(tc.x, tc.y);//gl_FragCoord.xy/iResolution.xy;
    int Enabled = PREFIX(Enabled);
    float mean_b = PREFIX(mean_b);
    float mean_g = PREFIX(mean_g);
    float mean_r = PREFIX(mean_r);
    float stddb = PREFIX(stddb);
    float stddg = PREFIX(stddg);
    float stddr = PREFIX(stddr);
    int strength = PREFIX(strength);

    float mean_b1 = PREFIX(mean_b1);
    float mean_g1 = PREFIX(mean_g1);
    float mean_r1 = PREFIX(mean_r1);
    float stddb1 = PREFIX(stddb1);
    float stddg1 = PREFIX(stddg1);
    float stddr1 = PREFIX(stddr1);
	
	vec4 orig = INPUT(tc);
    vec3 orig_rgb = orig.zyx;
    vec3 lms = rgb2lms(orig_rgb);
    vec3 min_mat = vec3(EPSILON,EPSILON,EPSILON);
	vec3 img_lms = max(lms,min_mat);
    img_lms=log(img_lms);
    vec3 log_10 = vec3(log(10.0));
	img_lms = img_lms/log_10;
    vec3 img_lab = lms2lab(img_lms);

    vec3 koef = vec3(stddb / stddb1, stddg / stddg1, stddr / stddr1);
	
	if(stddb1 < ZERO_EPS)
		koef.x = 1.0;
	if(stddg1 < ZERO_EPS)
		koef.y = 1.0;
	if(stddr1 < ZERO_EPS)
		koef.z = 1.0;
		
	koef.xyz = clamp(koef.xyz,0.0,1.5);
    vec3 mean_src = vec3(mean_b1,mean_g1,mean_r1);
    vec3 mean_tg = vec3(mean_b, mean_g, mean_r);

    img_lab = (img_lab - mean_src)* koef;
    vec3 result = img_lab + mean_tg;
	img_lms = lab2lms(result);

	img_lms=exp(img_lms);
	img_lms = pow(img_lms, vec3(log(10.0)));
    vec3 img_rgb = lms2rgb(img_lms);
    float alpha = float(strength)/100.0;
	vec3 outColor = mix(orig_rgb, img_rgb, alpha);
	outColor = clamp(outColor,0.0,1.0);
	vec4 retColor = vec4(outColor.z,outColor.y,outColor.x,orig.w);
	return retColor;
}
