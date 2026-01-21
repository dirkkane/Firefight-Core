#line 2 "source\rasterizer\hlsl\pixel_copy.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

float4 default_ps(screen_output IN, SCREEN_POSITION_INPUT(vpos)) : SV_Target
{
#ifdef pc
 	return sample2D(source_sampler, IN.texcoord) * scale.x + scale.y;
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
