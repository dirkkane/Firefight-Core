#line 1 "source\rasterizer\hlsl\screenshot_combine.hlsl"

//@generate screen

#include "global.fx"

#define CALC_BLOOM calc_bloom_screenshot
float4 calc_bloom_screenshot(in float2 texcoord);

#define SCREENSHOT_COMBINE

#include "final_composite_base.hlsl"


float4 calc_bloom_screenshot(in float2 texcoord)
{
	// sample bloom super-smooth bspline!
	return tex2D_bspline(bloom_sampler, transform_texcoord(texcoord, bloom_sampler_xform));
}


