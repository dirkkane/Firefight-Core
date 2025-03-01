/*
PARTICLE_SPAWN_REGISTERS.FX
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
12/5/2005 11:50:57 AM (davcook)
	
*/

#if DX_VERSION == 9

#include "particle_spawn_registers.h"

VERTEX_CONSTANT(float4, hidden_from_compiler, k_vs_particle_spawn_hidden_from_compiler)	// the compiler will complain if these are literals

#elif DX_VERSION == 11

#include "raw_particle_state.fx"

#define CS_PARTICLE_SPAWN_THREADS 64

STRUCTURED_BUFFER(cs_particle_address_buffer,		k_cs_particle_address_buffer,		uint,					4)
STRUCTURED_BUFFER(cs_particle_state_spawn_buffer,	k_cs_particle_state_spawn_buffer,	s_raw_particle_state,	5)

#endif