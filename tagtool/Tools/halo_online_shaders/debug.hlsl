#line 1 "source\rasterizer\hlsl\debug.hlsl"

// define before render_target.fx
#ifndef LDR_ALPHA_ADJUST
#ifdef pc
#define LDR_ALPHA_ADJUST 1.0f
#else
#define LDR_ALPHA_ADJUST 1.0f/32.0f
#endif
#endif
#ifndef DARK_COLOR_MULTIPLIER
#define DARK_COLOR_MULTIPLIER 128.0f
#endif

#define LDR_ONLY

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "hlsl_vertex_types.fx"
#include "render_target.fx"

//@generate debug

struct debug_output
{
	float4 HPosition	:SV_Position;
    float4 Color		:COLOR0;
};

#ifdef VERTEX_SHADER

debug_output default_vs(vertex_type IN)
{
    debug_output OUT;

    OUT.HPosition= mul(float4(IN.position, 1.0f), View_Projection);
	OUT.Color= IN.color;
	
    return OUT;
}

#endif

// pixel fragment entry points

accum_pixel default_ps(debug_output IN)
{
    return convert_to_render_target(IN.Color, false, false
    #ifdef SSR_ENABLE
	, 0
    #endif
    );
}
