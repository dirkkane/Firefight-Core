/*
LIGHT_VOLUME_UPDATE.HLSL
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
11/11/2005 11:38:58 AM (davcook)

Shaders for light_volume physics, state updates
*/

#if DX_VERSION == 11
// @compute_shader
#endif

#include "global.fx"

#if ((DX_VERSION == 9) && defined(VERTEX_SHADER)) || ((DX_VERSION == 11) && defined(COMPUTE_SHADER)) || defined(PC_CPU)

#define MEMEXPORT_ENABLED 1

#include "hlsl_vertex_types.fx"
#include "light_volume_common.fx"
#include "light_volume_registers.fx"

//This comment causes the shader compiler to be invoked for certain types
//@generate s_light_volume_vertex

typedef s_light_volume_vertex s_profile_in;
typedef void s_profile_out;

// #ifndef pc

s_profile_out light_volume_main( s_profile_in vIN )
{
	s_profile_state STATE;
#ifndef PC_CPU
	s_profile_out OUT;
#endif

	int buffer_index= profile_index_to_buffer_index(vIN.index);
	//STATE= read_profile_state(buffer_index);	// Light volumes are stateless

	STATE.m_percentile= vIN.index / (g_all_state.m_num_profiles - 1);
	
#if defined(PC_CPU)
	float pre_evaluated_scalar[_index_max];
	preevaluate_light_volume_functions(STATE, pre_evaluated_scalar);
#else
   float pre_evaluated_scalar[_index_max]= preevaluate_light_volume_functions(STATE);
#endif

	// Update pos
	//STATE.m_position.xyz= g_all_state.m_origin + g_all_state.m_direction * (g_all_state.m_offset + g_all_state.m_profile_distance * vIN.index);
#if (DX_VERSION == 11) || (! defined(pc)) // incorrect in pc version
	STATE.m_position = g_all_state.m_origin + g_all_state.m_direction * (g_all_state.m_offset + g_all_state.m_profile_distance * vIN.index);
#endif

	// Compute color (will be clamped [0,1] and compressed to 8-bit upon export)
	STATE.m_color.xyz= light_volume_map_to_color_range(_index_profile_color, 
		pre_evaluated_scalar[_index_profile_color]);
	STATE.m_color.w= pre_evaluated_scalar[_index_profile_alpha];
		
	// Compute misc fields (better to do once here than multiple times in render)
	STATE.m_thickness= pre_evaluated_scalar[_index_profile_thickness];
	STATE.m_intensity= pre_evaluated_scalar[_index_profile_intensity];

	//return 
	write_profile_state(STATE, buffer_index);
}
// #endif	// #ifndef pc

// For EDRAM method, the main work must go in the pixel shader, since only 
// pixel shaders can write to EDRAM.
// For the MemExport method, we don't need a pixel shader at all.
// This is signalled by a "void" return type or "multipass" config?

#if (DX_VERSION == 9) && defined(pc)
float4 default_vs( vertex_type IN ) :SV_Position
{
	return float4(1, 2, 3, 4);
}
#elif DX_VERSION == 11
[numthreads(CS_LIGHT_VOLUME_UPDATE_THREADS,1,1)]
void default_cs(in uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + light_volume_index_range.x;
	if (index < light_volume_index_range.y)
	{
		s_profile_in input;
		input.index = index;
		light_volume_main(input);
	}
}
#else
void default_vs( vertex_type vIN )
{
//	asm {
//		config VsExportMode=multipass   // export only shader
//	};
	light_volume_main(vIN);
}
#endif

#else //VERTEX_SHADER

#if DX_VERSION == 9
// Should never be executed
float4 default_ps( SCREEN_POSITION_INPUT(screen_position) ) :SV_Target0
{
	return float4(0,1,2,3);
}
#endif

#endif	//#ifdef VERTEX_SHADER