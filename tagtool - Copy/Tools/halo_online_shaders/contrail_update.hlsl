/*
CONTRAIL_UPDATE.HLSL
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
11/11/2005 11:38:58 AM (davcook)

Shaders for contrail physics, state updates
*/

#if DX_VERSION == 11
// @compute_shader
#endif

#include "global.fx"
#include "contrail_update_registers.fx"	// must come before contrail_common.fx
#include "contrail_registers.fx"

#if ((DX_VERSION == 9) && (defined(VERTEX_SHADER))) || ((DX_VERSION == 11) && defined(COMPUTE_SHADER)) || defined(PC_CPU)

#define MEMEXPORT_ENABLED 1

#include "hlsl_vertex_types.fx"
#include "contrail_common.fx"

//This comment causes the shader compiler to be invoked for certain types
//@generate s_contrail_vertex

typedef s_contrail_vertex s_profile_in;
typedef void s_profile_out;

//#ifndef pc

s_profile_out contrail_main( s_profile_in IN_ )
{
	s_profile_state STATE;
#ifndef PC_CPU
	s_profile_out OUT;
#endif

	STATE= read_profile_state(IN_.index);

#ifndef PC_CPU
	float pre_evaluated_scalar[_index_max]= preevaluate_contrail_functions(STATE);
#else
	float pre_evaluated_scalar[_index_max];
	preevaluate_contrail_functions(STATE, pre_evaluated_scalar);
#endif

	// Shader compiler workaround ... the shader doesn't compile on Feb 2007 XDK unless we move this line earliery
	STATE.m_offset= contrail_map_to_vector2d_range(_index_profile_offset, 
		pre_evaluated_scalar[_index_profile_offset]);
		
	if( STATE.m_age < 1.0f )
	{
		// Update timer
		STATE.m_age+= delta_time / STATE.m_lifespan;

		// Update pos
		//STATE.m_position.xyz+= STATE.m_velocity.xyz * delta_time;
		STATE.m_position+= STATE.m_velocity * delta_time;

		// Update velocity
		STATE.m_velocity+= contrail_map_to_vector3d_range(_index_profile_self_acceleration, 
			pre_evaluated_scalar[_index_profile_self_acceleration]) * delta_time;
		
		// Update rotation (only stored as [0,1], and "frac" is necessary to avoid clamping)
		STATE.m_rotation= frac(pre_evaluated_scalar[_index_profile_rotation]);
		
		// Compute color (will be clamped [0,1] and compressed to 8-bit upon export)
		STATE.m_color.xyz= contrail_map_to_color_range(_index_profile_color, 
			pre_evaluated_scalar[_index_profile_color]);
		STATE.m_color.w= pre_evaluated_scalar[_index_profile_alpha] * pre_evaluated_scalar[_index_profile_alpha2];
			
		// Compute misc fields (better to do once here than multiple times in render)
		STATE.m_size= pre_evaluated_scalar[_index_profile_size];
		STATE.m_intensity= pre_evaluated_scalar[_index_profile_intensity];
		STATE.m_black_point= frac(pre_evaluated_scalar[_index_profile_black_point]);
		STATE.m_palette= frac(pre_evaluated_scalar[_index_profile_palette]);
		//STATE.m_offset= contrail_map_to_vector2d_range(_index_profile_offset, 
		//	pre_evaluated_scalar[_index_profile_offset]);
	}

	//return 
	write_profile_state(STATE, IN_.index);
}

//#endif	// #ifndef pc


// For EDRAM method, the main work must go in the pixel shader, since only 
// pixel shaders can write to EDRAM.
// For the MemExport method, we don't need a pixel shader at all.
// This is signalled by a "void" return type or "multipass" config?

//#ifdef pc
//float4 default_vs( vertex_type IN ) :POSITION
//{
//	return float4(1, 2, 3, 4);
//}
//#else

#if DX_VERSION == 9

#ifndef PC_CPU
float4 default_vs(vertex_type IN_) : SV_Position
#else
void default_vs( vertex_type IN_ )
#endif
{
//	asm {
//		config VsExportMode=multipass   // export only shader
//	};

//Ruffian -DLH
// We need to have a return here as the shader build wont 
// accept a VS with no out
#ifndef PC_CPU 
	return float4(1,2,3,4);
#else
	contrail_main(IN_);
#endif
}

#elif (DX_VERSION == 11) && defined(COMPUTE_SHADER)
[numthreads(CS_CONTRAIL_UPDATE_THREADS,1,1)]
void default_cs(in uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + contrail_index_range.x;
	if (index < contrail_index_range.y)
	{
		vertex_type input;
		input.index = index;
		contrail_main(input);
	}
}
#endif
//#endif

#endif

#if DX_VERSION == 9
// Should never be executed
float4 default_ps( SCREEN_POSITION_INPUT(screen_position) )
#ifndef PC_CPU
   : SV_Target0
#endif
{
	return float4(0,1,2,3);
}
#endif

