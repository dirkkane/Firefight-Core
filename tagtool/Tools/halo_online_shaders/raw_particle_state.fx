#ifndef _RAW_PARTICLE_STATE_FX_
#define _RAW_PARTICLE_STATE_FX_

#if DX_VERSION == 11

struct s_raw_particle_state
{
	float4 pos;
	uint2 vel;
	uint2 rnd;
	uint2 rnd2;
	uint2 rot;
	uint2 time;
	uint anm;
	uint anm2;
	uint axis;
	uint col;
	uint col2;	
	uint padding;
};

#endif

#endif
