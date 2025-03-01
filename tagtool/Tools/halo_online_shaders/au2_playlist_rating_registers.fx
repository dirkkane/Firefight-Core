#ifndef _AU2_PLAYLIST_RATING_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _AU2_PLAYLIST_RATING_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "au2_playlist_rating_registers.h"

PIXEL_CONSTANT(float4, uv_coords, k_ps_au2_playlist_rating_uv_coords);

#elif DX_VERSION == 11

CBUFFER_BEGIN(AU2PlaylistRatingPS)
	CBUFFER_CONST(AU2PlaylistRatingPS,		float4,		uv_coords,		k_ps_au2_playlist_rating_uv_coords)
CBUFFER_END

#endif

#endif
