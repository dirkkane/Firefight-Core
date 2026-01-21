#line 1 "source\rasterizer\hlsl\player_emblem_world.hlsl"
/*
player_emblem_world.hlsl
Copyright (c) Microsoft Corporation, 2007. All rights reserved.
Friday February 23, 2007, 12:05pm Stefan S.

*/

/* ---------- headers */

#include "global.fx"
#include "player_emblem.fx"
#include "deform.fx"
// the following are needed for using convert_to_render_target()
#define LDR_ONLY
#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx" //convert_to_render_target

// compile this shader for various needed vertex types
//@generate world

/* ---------- public code */

// vertex fragment entry points
// ###stefan $REVIEW  stolen from post_process.fx - declaration conflicts force this
struct s_screen_output
{
	float4 position : SV_Position;
	float2 texcoord : TEXCOORD0;
	float4 color : COLOR;
};

s_screen_output default_vs(vertex_type IN)
{
	s_screen_output out_vertex;
	
	out_vertex.texcoord= IN.texcoord;
	out_vertex.position.xyz= IN.position;
	out_vertex.position.w= 1.0f;
	out_vertex.color= float4(1.f, 1.f, 1.f, 1.f); //IN.color;
	
	return out_vertex;
}

// pixel fragment entry points

accum_pixel default_ps(s_world_vertex IN) : SV_Target
{
	float4 emblem_pixel= sample2D(tex0_sampler, IN.texcoord);
	
	return convert_to_render_target(emblem_pixel, false, false
	#ifdef SSR_ENABLE
	, 0
    #endif
    );
}
