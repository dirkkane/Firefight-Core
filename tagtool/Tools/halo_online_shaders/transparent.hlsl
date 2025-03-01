#line 1 "source\rasterizer\hlsl\transparent.hlsl"

#ifdef EXPLICIT_COMPILER
#define SSR_ENABLE
#endif

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"

//@generate transparent
LOCAL_SAMPLER_2D(basemap_sampler, 0);

struct transparent_output
{
	float4 HPosition	:SV_Position;
	float2 Texcoord		:TEXCOORD0;
	float4 Color		:COLOR0;
};

#ifdef VERTEX_SHADER

transparent_output default_vs(vertex_type IN)
{
    transparent_output OUT;

    OUT.HPosition= mul(float4(IN.position, 1.0f), View_Projection);
	OUT.Color= IN.color;
	OUT.Texcoord= IN.texcoord;
	
    return OUT;
}

#endif

// pixel fragment entry points
accum_pixel default_ps(transparent_output IN) : SV_Target
{
	return convert_to_render_target(IN.Color * sample2D(basemap_sampler, IN.Texcoord), false, false
	#ifdef SSR_ENABLE
	, 0
    #endif
    );
}
