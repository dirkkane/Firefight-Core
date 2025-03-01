#line 2 "source\rasterizer\hlsl\chud_overlay_blend.hlsl"


#define IGNORE_SKINNING_NODES

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen


LOCAL_SAMPLER_2D(original_sampler, 0);
LOCAL_SAMPLER_2D(add_sampler, 1);
LOCAL_SAMPLER_2D(chud_overlay, 2);


float4 default_ps(screen_output IN) : SV_Target
{
	float4 original= sample2D(original_sampler, IN.texcoord);
	float4 add= sample2D(add_sampler, IN.texcoord);
	float4 chud= sample2D(chud_overlay, IN.texcoord);

	float4 color;
	color.rgb= scale.rgb * original.rgb * chud.a + add.rgb + chud.rgb;
	color.a= chud.a;
	
	return color;	
}
