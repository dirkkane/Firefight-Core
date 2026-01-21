/*
WATER_REGISTERS.FX
Copyright (c) Microsoft Corporation, 2007. all rights reserved.
2/5/2007 7:58:04 PM (xwan)
	Synchanize constant register definition between cpp and fx
*/

#if DX_VERSION == 9

#include "water_registers.h"

/* water only*/
VERTEX_CONSTANT(float4, k_water_memexport_addr, k_vs_water_memexport_addr)
VERTEX_CONSTANT(float4, k_water_index_offset, k_vs_water_index_offset)

PIXEL_CONSTANT(float4, k_ps_water_view_depth_constant, CONSTANT_NAME(217))

BOOL_CONSTANT(k_is_lightmap_exist, k_ps_water_is_lightmap_exist) // todo: was 100-103 previously, but there are only 16 of them [25/01/2013 paul.smirnov]
BOOL_CONSTANT(k_is_water_interaction, k_ps_water_is_interaction)
BOOL_CONSTANT(k_is_water_tessellated, k_ps_water_is_tessellated)
BOOL_CONSTANT(k_is_camera_underwater, k_ps_water_is_camera_underwater)

SAMPLER_CONSTANT(tex_ripple_buffer_slope_height, k_ps_water_tex_ripple_buffer_slope_height)
#define vs_tex_ripple_buffer_slope_height tex_ripple_buffer_slope_height

/* tesselletion only*/
VERTEX_CONSTANT(float4, k_vs_tess_camera_position, k_vs_water_tess_camera_position)
VERTEX_CONSTANT(float4, k_vs_tess_camera_forward, k_vs_water_tess_camera_forward)
VERTEX_CONSTANT(float4, k_vs_tess_camera_diagonal, k_vs_water_tess_camera_diagonal)

/* interaction only*/
VERTEX_CONSTANT(float4, k_vs_ripple_memexport_addr, k_vs_water_ripple_memexport_addr)
VERTEX_CONSTANT(float3, k_vs_camera_position, k_vs_water_camera_position)
VERTEX_CONSTANT(float, k_vs_ripple_pattern_count, k_vs_water_ripple_pattern_count)
VERTEX_CONSTANT(float, k_vs_ripple_real_frametime_ratio, k_vs_water_ripple_real_frametime_ratio)
VERTEX_CONSTANT(float, k_vs_ripple_particle_index_start, k_vs_water_ripple_particle_index_start)
VERTEX_CONSTANT(float, k_vs_maximum_ripple_particle_number, k_vs_water_maximum_ripple_particle_number)

#ifndef pc
   BOOL_CONSTANT(k_is_under_screenshot, k_vs_water_is_under_screenshot)
#endif

SAMPLER_CONSTANT(tex_ripple_pattern, k_ps_water_tex_ripple_pattern)
SAMPLER_CONSTANT(tex_ripple_buffer_height, k_ps_water_tex_ripple_buffer_height)

/* underwater only */
SAMPLER_CONSTANT(tex_ldr_buffer, k_ps_water_tex_ldr_buffer)
SAMPLER_CONSTANT(tex_depth_buffer, k_ps_water_tex_depth_buffer)

/* share constants */
VERTEX_CONSTANT(float, k_ripple_buffer_radius, k_vs_water_ripple_buffer_radius)
VERTEX_CONSTANT(float2, k_ripple_buffer_center, k_vs_water_ripple_buffer_center)
VERTEX_CONSTANT(float4, hidden_from_compiler, k_vs_water_hidden_from_compiler)

#ifndef PC_CPU
   PIXEL_CONSTANT(float4x4, k_ps_water_view_xform_inverse, CONSTANT_NAME(213))
#endif
PIXEL_CONSTANT(float4, k_ps_water_player_view_constant, CONSTANT_NAME(218))
PIXEL_CONSTANT(float4, k_ps_camera_position, CONSTANT_NAME(219))
PIXEL_CONSTANT(float, k_ps_underwater_murkiness, CONSTANT_NAME(220))
PIXEL_CONSTANT(float3, k_ps_underwater_fog_color, CONSTANT_NAME(221))

#elif DX_VERSION == 11

#include "ripple.fx"

CBUFFER_BEGIN(WaterPS)						
	CBUFFER_CONST(WaterPS,					float4, 	k_water_view_depth_constant, 				k_ps_water_view_depth_constant)
	CBUFFER_CONST(WaterPS,					bool,		k_is_lightmap_exist, 						k_ps_water_is_lightmap_exist)
	CBUFFER_CONST(WaterPS,					bool,		k_is_water_interaction, 					k_ps_water_is_interaction)
	CBUFFER_CONST(WaterPS,					bool,		k_is_water_tessellated, 					k_ps_water_is_tessellated)
	CBUFFER_CONST(WaterPS,					bool,		k_is_camera_underwater, 					k_ps_water_is_underwater)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	tex_ripple_buffer_slope_height,		k_ps_water_tex_ripple_buffer_slope_height,		10)
VERTEX_TEXTURE_AND_SAMPLER(_2D,	vs_tex_ripple_buffer_slope_height,	k_vs_water_tex_ripple_buffer_slope_height,		3)

CBUFFER_BEGIN(WaterTessellationVS)
	CBUFFER_CONST(WaterTessellationVS,		float4, 	k_vs_tess_camera_position,					k_vs_water_tess_camera_position)
	CBUFFER_CONST(WaterTessellationVS,		float4, 	k_vs_tess_camera_forward,					k_vs_water_tess_camera_forward)
	CBUFFER_CONST(WaterTessellationVS,		float4, 	k_vs_tess_camera_diagonal,					k_vs_water_tess_camera_diagonal)
CBUFFER_END

CBUFFER_BEGIN(WaterRippleApplyVS)
	CBUFFER_CONST(WaterRippleApplyVS,		float3, 	k_vs_camera_position, 						k_vs_water_camera_position)
	CBUFFER_CONST(WaterRippleApplyVS,		float, 		k_vs_camera_position_pad,					k_vs_water_camera_position_pad)
	CBUFFER_CONST(WaterRippleApplyVS,		float, 		k_vs_ripple_pattern_count, 					k_vs_water_ripple_pattern_count)
	CBUFFER_CONST(WaterRippleApplyVS,		float3, 	k_vs_ripple_pattern_count_pad, 				k_vs_water_ripple_pattern_count_pad)
CBUFFER_END

CBUFFER_BEGIN(WaterRippleUpdateVS)
	CBUFFER_CONST(WaterRippleUpdateVS,		float, 		k_vs_ripple_real_frametime_ratio, 			k_vs_water_ripple_real_frametime_ratio)
	CBUFFER_CONST(WaterRippleUpdateVS,		float3, 	k_vs_ripple_real_frametime_ratio_pad,		k_vs_water_ripple_real_frametime_ratio_pad)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D_ARRAY,	tex_ripple_pattern,			k_ps_water_tex_ripple_pattern,	 			0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,			tex_ripple_buffer_height, 	k_ps_water_tex_ripple_buffer_height,		1)

PIXEL_TEXTURE_AND_SAMPLER(_2D,			tex_ldr_buffer, 			k_ps_water_tex_ldr_buffer,					0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,			tex_depth_buffer, 			k_ps_water_tex_depth_buffer,				1)

CBUFFER_BEGIN(WaterSharedVS)
	CBUFFER_CONST(WaterSharedVS,			float, 		k_ripple_buffer_radius, 					k_vs_water_ripple_buffer_radius)
	CBUFFER_CONST(WaterSharedVS,			float3, 	k_ripple_buffer_radius_pad,					k_vs_water_ripple_buffer_radius_pad)
	CBUFFER_CONST(WaterSharedVS,			float2, 	k_ripple_buffer_center, 					k_vs_water_ripple_buffer_center)
	CBUFFER_CONST(WaterSharedVS,			float2, 	k_ripple_buffer_center_pad,					k_vs_water_ripple_buffer_center_pad)
CBUFFER_END

CBUFFER_BEGIN(WaterSharedPS)
	CBUFFER_CONST(WaterSharedPS,			float4x4, 	k_water_view_xform_inverse, 				k_ps_water_view_xform_inverse)
	CBUFFER_CONST(WaterSharedPS,			float4, 	k_water_player_view_constant, 				k_ps_water_player_view_constant)
	CBUFFER_CONST(WaterSharedPS,			float4, 	k_ps_camera_position, 						k_ps_water_camera_position)
	CBUFFER_CONST(WaterSharedPS,			float, 		k_ps_underwater_murkiness, 					k_ps_water_underwater_murkiness)
	CBUFFER_CONST(WaterSharedPS,			float3,		k_ps_underwater_murkiness_pad, 				k_ps_water_underwater_murkiness_pad)
	CBUFFER_CONST(WaterSharedPS,			float3, 	k_ps_underwater_fog_color, 					k_ps_water_underwater_fog_color)
CBUFFER_END

CBUFFER_BEGIN(WaterRippleIndex)
	CBUFFER_CONST(WaterRippleIndex,			uint2,		ripple_index_range,							k_ripple_index_range)
CBUFFER_END
	
#define CS_RIPPLE_UPDATE_THREADS 64

RW_STRUCTURED_BUFFER(cs_ripple_buffer,		k_cs_ripple_buffer,		s_ripple,		0)
STRUCTURED_BUFFER(vs_ripple_buffer,			k_vs_ripple_buffer,		s_ripple,		16)
	
#endif
