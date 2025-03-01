#ifndef _PARTICLE_INDEX_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _PARTICLE_INDEX_REGISTERS_FX_
#endif

CBUFFER_BEGIN(ParticleIndex)
	CBUFFER_CONST(ParticleIndex,		uint2,		particle_index_range,	k_particle_index_range)
CBUFFER_END

#endif

