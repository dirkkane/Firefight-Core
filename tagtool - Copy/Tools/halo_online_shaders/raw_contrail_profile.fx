#ifndef _RAW_CONTRAIL_PROFILE_FX_
#define _RAW_CONTRAIL_PROFILE_FX_

#if DX_VERSION == 11

struct s_raw_contrail_profile
{
	float4 pos;
	uint2 vel;
	uint2 rnd;
	uint2 misc;
	uint2 misc2;
	uint misc3;
	uint col;
	uint col2;
	uint padding;
};

#endif

#endif
