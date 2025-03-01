/*
PARTICLE_SPAWN.HLSL
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
11/11/2005 11:38:58 AM (davcook)

Shaders for particle spawning
*/

#if DX_VERSION == 11
// @compute_shader
#endif

#define PARTICLE_WRITE 1
#define PARTICLE_SPAWN

#include "global.fx"

#if ((DX_VERSION == 9) && defined(VERTEX_SHADER)) || ((DX_VERSION == 11) && defined(COMPUTE_SHADER))
#include "hlsl_vertex_types.fx"
#include "particle_spawn_registers.fx"
#if DX_VERSION == 11
#include "particle_state_buffer.fx"
#include "particle_index_registers.fx"
#endif
#include "particle_state.fx"

//This comment causes the shader compiler to be invoked for certain types
//@generate s_particle_vertex

#if !defined(pc)
float4 particle_main( vertex_type IN ) :SV_Position
{
	s_particle_state STATE= read_particle_state(IN.index);
	static int2 dims= int2(16, 448);	// Make this linked to .cpp
	int out_index= IN.address.x + IN.address.y * dims.x;
	write_particle_state(STATE, out_index);
	return 0;
}
#endif

#if defined(pc) && (DX_VERSION == 9)
float4 default_vs( vertex_type IN ) :SV_Position
{
	return float4(1, 2, 3, 4);
}
#elif DX_VERSION == 11
[numthreads(CS_PARTICLE_SPAWN_THREADS,1,1)]
void default_cs(in uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + particle_index_range.x;
	if (index < particle_index_range.y)
	{
		uint packed_address = cs_particle_address_buffer[index];
	
		uint out_index = (packed_address & 0xffff) + ((packed_address >> 16) * 16);
		cs_particle_state_buffer[out_index] = cs_particle_state_spawn_buffer[index];
	}
}
#else
void default_vs( vertex_type IN )
{
//	asm {
//		config VsExportMode=multipass   // export only shader
//	};
	particle_main(IN);
}
#endif

#else	//#ifdef VERTEX_SHADER
// Should never be executed
float4 default_ps( SCREEN_POSITION_INPUT(screen_position) ) :SV_Target0
{
	return float4(0,1,2,3);
}
#endif