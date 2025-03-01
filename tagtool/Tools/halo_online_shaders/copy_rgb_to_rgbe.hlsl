#line 2 "source\rasterizer\hlsl\copy_RGB_to_RGBE.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

float4 default_ps(screen_output IN) : SV_Target
{
 	float4 color= sample2D(source_sampler, IN.texcoord);
	return color.rgba * scale.rgba; //RGB_to_RGBE(color.rgb * scale.rgb);
}
