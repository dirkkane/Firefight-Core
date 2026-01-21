#line 2 "source\rasterizer\hlsl\screenshot_combine_DOF.hlsl"
//@generate screen

#include "global.fx"


#ifndef pc
#define COMBINE_HDR_LDR combine_dof
float4 combine_dof(in float2 texcoord);
#endif // !pc


#define CALC_BLOOM calc_bloom_screenshot
float4 calc_bloom_screenshot(in float2 texcoord);

#define SCREENSHOT_COMBINE

#include "final_composite_base.hlsl"


#ifndef pc

// depth of field
#define DEPTH_BIAS			depth_constants.x
#define DEPTH_SCALE			depth_constants.y
#define FOCUS_DISTANCE		depth_constants.z
#define APERTURE			depth_constants.w
#define FOCUS_HALF_WIDTH	depth_constants2.x
#define MAX_BLUR_BLEND		depth_constants2.y
#include "DOF_filter.fx"

float4 combine_dof(in float2 texcoord)
{
	return simple_DOF_filter(texcoord, surface_sampler, LDR_gamma2, blur_sampler, depth_sampler);
}

#endif // !pc


float4 calc_bloom_screenshot(in float2 texcoord)
{
	// sample bloom super-smooth bspline!
	return tex2D_bspline(bloom_sampler, transform_texcoord(texcoord, bloom_sampler_xform));
}
