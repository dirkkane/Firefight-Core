#line 2 "source\rasterizer\hlsl\apply_bloom_curve.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

// scale = bloom_curve_constants

float4 default_ps(screen_output IN) : SV_Target
{
	float2 sample0= IN.texcoord; //+ 0.5 * source_pixel_size;

 	float4 color= sample2D(source_sampler, sample0);
 	color.rgb= color * DARK_COLOR_MULTIPLIER;
	
	// drop out visible values (no bloom on em)
	float maximum= max(max(color.r, color.g), color.b);
//	float overwhite= maximum-min(maximum, bloom_curve_constants.x);  // bloom_point
//	color *= (overwhite/maximum) + bloom_curve_constants.y;	// inherent_bloom					// 0.1; //0.05;

	float overwhite= max(maximum*scale.y, maximum-scale.x);
	color *= (overwhite/maximum);

	return color / DARK_COLOR_MULTIPLIER; //convert_to_render_target(color, false);
}
