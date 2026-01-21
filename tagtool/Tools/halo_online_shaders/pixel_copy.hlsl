#line 2 "source\rasterizer\hlsl\pixel_copy.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);
LOCAL_SAMPLER_2D(gamma_LUT, 1);

float3 sample_gamma(float3 colour)
{
    return float3(	sample2D(gamma_LUT, float2(saturate(colour.r) * (255.0f / 256.0f) + 0.001953125f, 0.5f)).r,
					sample2D(gamma_LUT, float2(saturate(colour.g) * (255.0f / 256.0f) + 0.001953125f, 0.5f)).r,
					sample2D(gamma_LUT, float2(saturate(colour.b) * (255.0f / 256.0f) + 0.001953125f, 0.5f)).r );
}

float4 default_ps(screen_output IN, SCREEN_POSITION_INPUT(vpos)) : SV_Target
{
#ifdef pc
 	float4 color = sample2D(source_sampler, IN.texcoord) * scale.x + scale.y;
		
	color.rgb = sample_gamma(color.rgb);

	return color;
 #else
	// wrap at 8x8
	vpos= vpos - 8.0 * floor(vpos / 8.0);
 
	float4 result;
	asm {
		tfetch2D result, vpos, source_sampler, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
	};
	return result;
 #endif
}
