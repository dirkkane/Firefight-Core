#line 2 "source\rasterizer\hlsl\downsample_4x4_gaussian.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

float4 default_ps(screen_output IN) : SV_Target				// ###ctchou $TODO $PERF convert this to tex2D_offset, and do a gaussian filter greater than 4x4 kernel (cheap cuz we only use it on the smaller size textures)
{
#ifdef pc
	float4 color= 0.00000001f;			// hack to keep divide by zero from happening on the nVidia cards
#else
	float4 color= 0.0f;
#endif

	// this is a 6x6 gaussian filter (slightly better than 4x4 box filter)
	color += (0.25f * 0.25f) * tex2D_offset(source_sampler, IN.texcoord, -2, -2);
	color += (0.50f * 0.25f) * tex2D_offset(source_sampler, IN.texcoord, +0, -2);
	color += (0.25f * 0.25f) * tex2D_offset(source_sampler, IN.texcoord, +2, -2);
	color += (0.50f * 0.25f) * tex2D_offset(source_sampler, IN.texcoord, -2, +0);
	color += (1.00f * 0.25f) * tex2D_offset(source_sampler, IN.texcoord, +0, +0);
	color += (0.50f * 0.25f) * tex2D_offset(source_sampler, IN.texcoord, +2, +0);
	color += (0.25f * 0.25f) * tex2D_offset(source_sampler, IN.texcoord, -2, +2);
	color += (0.50f * 0.25f) * tex2D_offset(source_sampler, IN.texcoord, +0, +2);
	color += (0.25f * 0.25f) * tex2D_offset(source_sampler, IN.texcoord, +2, +2);

	return color;
}
