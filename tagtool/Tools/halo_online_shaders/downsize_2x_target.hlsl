#line 2 "source\rasterizer\hlsl\downsize_2x_target.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

float4 default_ps(screen_output IN) : SV_Target				// ###ctchou $TODO $PERF convert this to tex2D_offset, and do a gaussian filter greater than 4x4 kernel (cheap cuz we only use it on the smaller size textures)
{
#ifdef pc
	float3 color= 0.00000001f;			// hack to keep divide by zero from happening on the nVidia cards
#else
	float3 color= 0.0f;
#endif

/*
	// this is a 4x4 box filter
	color += convert_from_bloom_buffer(	tex2D_offset(source_sampler, IN.texcoord, -1, -1));
	color += convert_from_bloom_buffer(	tex2D_offset(source_sampler, IN.texcoord, +1, -1));
	color += convert_from_bloom_buffer(	tex2D_offset(source_sampler, IN.texcoord, -1, +1));
	color += convert_from_bloom_buffer(	tex2D_offset(source_sampler, IN.texcoord, +1, +1));
	color= color / 4.0f;
*/

	// this is a 6x6 gaussian filter (slightly better than 4x4 box filter)
	color += 0.25f * convert_from_bloom_buffer(	tex2D_offset(source_sampler, IN.texcoord, -2, -2));
	color += 0.50f * convert_from_bloom_buffer(	tex2D_offset(source_sampler, IN.texcoord, +0, -2));
	color += 0.25f * convert_from_bloom_buffer(	tex2D_offset(source_sampler, IN.texcoord, +2, -2));
	color += 0.50f * convert_from_bloom_buffer(	tex2D_offset(source_sampler, IN.texcoord, -2, +0));
	color += 1.00f * convert_from_bloom_buffer(	tex2D_offset(source_sampler, IN.texcoord, +0, +0));
	color += 0.50f * convert_from_bloom_buffer(	tex2D_offset(source_sampler, IN.texcoord, +2, +0));
	color += 0.25f * convert_from_bloom_buffer(	tex2D_offset(source_sampler, IN.texcoord, -2, +2));
	color += 0.50f * convert_from_bloom_buffer(	tex2D_offset(source_sampler, IN.texcoord, +0, +2));
	color += 0.25f * convert_from_bloom_buffer(	tex2D_offset(source_sampler, IN.texcoord, +2, +2));
	color= color / 4.0f;

	return convert_to_bloom_buffer(color);
}
