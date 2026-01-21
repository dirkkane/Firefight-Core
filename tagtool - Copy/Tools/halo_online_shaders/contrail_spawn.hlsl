/*
CONTRAIL_SPAWN.HLSL
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
11/11/2005 11:38:58 AM (davcook)

Shaders for contrail spawning
*/

#if DX_VERSION == 11
// @compute_shader
#endif

#include "global.fx"

#if ((DX_VERSION == 9) && defined(VERTEX_SHADER)) || ((DX_VERSION == 11) && defined(COMPUTE_SHADER))

#define MEMEXPORT_ENABLED 1

#include "hlsl_vertex_types.fx"
#include "contrail_spawn_registers.fx"	// must come before contrail_common.fx
#include "contrail_registers.fx"
#include "contrail_profile.fx"

//This comment causes the shader compiler to be invoked for certain types
//@generate s_contrail_vertex

#if !defined(pc)
float4 contrail_main( vertex_type IN ) : SV_Position
{
	s_profile_state STATE= read_profile_state(IN.index);
	int out_index= IN.address.x + IN.address.y * g_buffer_dims.x;
	write_profile_state(STATE, out_index);
	//return float4(1, 2, 3, 4);
}

void default_vs( vertex_type IN )
{
//	asm {
//		config VsExportMode=multipass   // export only shader
//	};
	contrail_main(IN);
}
#elif DX_VERSION == 11
[numthreads(CS_CONTRAIL_SPAWN_THREADS,1,1)]
void default_cs(in uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + contrail_index_range.x;
	if (index < contrail_index_range.y)
	{
		uint packed_address = cs_contrail_address_buffer[index];
		
		uint out_index = (packed_address & 0xffff) + ((packed_address >> 16) * g_buffer_dims.x);
		cs_contrail_profile_state_buffer[out_index] = cs_contrail_profile_state_spawn_buffer[index];
	}
}
#else
float4 default_vs( vertex_type IN ) : SV_Position
{
	return float4(1, 2, 3, 4);
}
#endif

#endif //VERTEX_SHADER

#if DX_VERSION == 9
// Should never be executed
float4 default_ps( SCREEN_POSITION_INPUT(screen_position) ) : SV_Target0
{
	return float4(0,1,2,3);
}
#endif
