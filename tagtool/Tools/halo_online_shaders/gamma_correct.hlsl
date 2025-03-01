#line 2 "source\rasterizer\hlsl\gamma_correct.hlsl"

//#define USE_CUSTOM_POSTPROCESS_CONSTANTS

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "texture_xform.fx"
#include "gamma_correct_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(surface_sampler, 0);

// pixel fragment entry points
float4 default_ps(screen_output IN) : SV_Target
{
	float4 pixel=		sample2D(surface_sampler, IN.texcoord);
	pixel.rgb= pow(pixel.bgr, gamma_power.r);
	return pixel;
}
