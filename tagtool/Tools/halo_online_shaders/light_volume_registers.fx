#ifndef _LIGHT_VOLUME_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _LIGHT_VOLUME_REGISTERS_FX_
#endif

#if DX_VERSION == 11

#include "light_volume_property.fx"
#include "light_volume_state.fx"
#include "light_volume_strip.fx"
#include "function_definition.fx"
#include "raw_light_volume_profile.fx"

CBUFFER_BEGIN(LightVolume)
	CBUFFER_CONST_ARRAY(LightVolume,	s_property,				g_all_properties, [_index_max],						k_light_volume_all_properties)
	CBUFFER_CONST_ARRAY(LightVolume,	s_function_definition,	g_all_functions, [_maximum_overall_function_count],	k_light_volume_all_functions)
	CBUFFER_CONST_ARRAY(LightVolume,	float4,					g_all_colors, [_maximum_overall_color_count],		k_light_volume_all_colors)	
CBUFFER_END

CBUFFER_BEGIN(LightVolumeState)
	CBUFFER_CONST(LightVolumeState,		s_overall_state,		g_all_state,										k_light_volume_state_all_state)
CBUFFER_END

CBUFFER_BEGIN(LightVolumeStrip)
	CBUFFER_CONST(LightVolumeStrip,		s_strip,				g_strip,											k_light_volume_strip)
CBUFFER_END

CBUFFER_BEGIN(LightVolumeIndex)					
	CBUFFER_CONST(LightVolumeIndex,		uint2,					light_volume_index_range,							k_light_volume_index_range)
CBUFFER_END	
	
RW_STRUCTURED_BUFFER(cs_light_volume_profile_state_buffer,		k_cs_light_volume_profile_state_buffer,		s_raw_light_volume_profile,		0)
STRUCTURED_BUFFER(vs_light_volume_profile_state_buffer,			k_vs_light_volume_profile_state_buffer,		s_raw_light_volume_profile,		16)

#define CS_LIGHT_VOLUME_UPDATE_THREADS 64

#endif

#endif
