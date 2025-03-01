#line 2 "source\rasterizer\hlsl\shadow_geometry.hlsl"

#ifdef EXPLICIT_COMPILER
#define SSR_ENABLE
#endif

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "deform.fx"
#include "utilities.fx"
#include "shadow_geometry_registers.fx"

//@generate tiny_position_only

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"


void default_vs(
	in vertex_type vertex,
	out float4 position : SV_Position)
{
    float4 local_to_world_transform[3];
	if (always_true)
	{
		deform(vertex, local_to_world_transform);
	}
	
	if (always_true)
	{
		position= mul(float4(vertex.position, 1.0f), View_Projection);
	}
	else
	{
		position= float4(0,0,0,0);
	}
}

#if DX_VERSION == 9
accum_pixel default_ps(SCREEN_POSITION_INPUT(screen_position))
{
	return convert_to_render_target(shadow_color, false, false
	#ifdef SSR_ENABLE
	, 0
    #endif
    );
}
#elif DX_VERSION == 11
void default_ps(SCREEN_POSITION_INPUT(screen_position))
{
}
#endif
