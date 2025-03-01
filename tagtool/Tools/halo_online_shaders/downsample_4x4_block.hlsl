#line 2 "source\rasterizer\hlsl\downsample_4x4_block.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

float4 default_ps(screen_output IN) : SV_Target
{
	float4 color= 0.0f;

	// this is a 4x4 box filter
	color += tex2D_offset(source_sampler, IN.texcoord, -1, -1);
	color += tex2D_offset(source_sampler, IN.texcoord, +1, -1);
	color += tex2D_offset(source_sampler, IN.texcoord, -1, +1);
	color += tex2D_offset(source_sampler, IN.texcoord, +1, +1);
	color= color / 4.0f;

	return color;
}
