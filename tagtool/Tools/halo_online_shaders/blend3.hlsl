#line 2 "source\rasterizer\hlsl\blend3.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(tex0_sampler, 0);
LOCAL_SAMPLER_2D(tex1_sampler, 1);
LOCAL_SAMPLER_2D(tex2_sampler, 2);

float4 default_ps(screen_output IN) : SV_Target
{
	float4 base_sample= sample2D(tex0_sampler, IN.texcoord);
	float4 star_sample= sample2D(tex0_sampler, IN.texcoord);

	float4 color;
	
	color.rgb=	scale.r * base_sample.rgb +
				scale.g * sample2D(tex1_sampler, IN.texcoord).rgb;
				
	color.a= base_sample.a;
				  
	return color;
}
