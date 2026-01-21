#line 2 "source\rasterizer\hlsl\kernel_5.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "kernel_5_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(target_sampler, 0);

fast4 default_ps(screen_output IN) : SV_Target
{
	float2 sample= IN.texcoord;
	
	float4 color=	kernel[0].z * sample2D(target_sampler, sample + kernel[0].xy) +
					kernel[1].z * sample2D(target_sampler, sample + kernel[1].xy) +
					kernel[2].z * sample2D(target_sampler, sample + kernel[2].xy) +
					kernel[3].z * sample2D(target_sampler, sample + kernel[3].xy) +
					kernel[4].z * sample2D(target_sampler, sample + kernel[4].xy);

	return color * scale;
}
