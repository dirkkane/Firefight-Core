#ifndef _PARTICLE_STATE_BUFFER_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _PARTICLE_STATE_BUFFER_FX_
#endif

#if DX_VERSION == 11

#include "raw_particle_state.fx"

RW_STRUCTURED_BUFFER(cs_particle_state_buffer,	k_cs_particle_state_buffer,		s_raw_particle_state,		0)
STRUCTURED_BUFFER(vs_particle_state_buffer,		k_vs_particle_state_buffer,		s_raw_particle_state,		16)

#endif

#endif
