#ifndef _BEAM_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _BEAM_REGISTERS_FX_
#endif

#if DX_VERSION == 11

#include "beam_property.fx"
#include "beam_state_list.fx"
#include "beam_strip.fx"
#include "raw_beam_profile_state.fx"
#include "function_definition.fx"

CBUFFER_BEGIN(Beam)
	CBUFFER_CONST_ARRAY(Beam,	s_property,				g_all_properties, [_index_max],						k_beam_all_properties)
	CBUFFER_CONST_ARRAY(Beam,	s_function_definition,	g_all_functions, [_maximum_overall_function_count],	k_beam_all_functions)
	CBUFFER_CONST_ARRAY(Beam,	float4,					g_all_colors, [_maximum_overall_color_count],		k_beam_all_colors)	
CBUFFER_END

CBUFFER_BEGIN(BeamState)
	CBUFFER_CONST(BeamState,	s_overall_state,		g_all_state,										k_beam_state_all_state)
CBUFFER_END					
					
CBUFFER_BEGIN(BeamStrip)					
	CBUFFER_CONST(BeamStrip,	s_strip,				g_strip,											k_beam_strip)
CBUFFER_END
					
CBUFFER_BEGIN(BeamIndex)					
	CBUFFER_CONST(BeamIndex,	uint2,					beam_index_range,									k_beam_index_range)
CBUFFER_END	
	
RW_STRUCTURED_BUFFER(cs_beam_profile_state_buffer,		k_cs_beam_profile_state_buffer,		s_raw_beam_profile_state,		0)
STRUCTURED_BUFFER(vs_beam_profile_state_buffer,			k_vs_beam_profile_state_buffer,		s_raw_beam_profile_state,		16)

#define CS_BEAM_UPDATE_THREADS 64

#endif

#endif
