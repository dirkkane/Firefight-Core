#ifndef _LIGHTSHAFTS_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _LIGHTSHAFTS_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "lightshafts_registers.h"

PIXEL_CONSTANT(float4, g_tint,       k_ps_lightshafts_tint);
PIXEL_CONSTANT(float4, g_sun_pos,    k_ps_lightshafts_sun_pos);
PIXEL_CONSTANT(float4, g_inner_size, k_ps_lightshafts_inner_size);

#elif DX_VERSION == 11

CBUFFER_BEGIN(LightshaftsPS)
	CBUFFER_CONST(LightshaftsPS,	float4,		g_tint,			k_ps_lightshafts_tint)
	CBUFFER_CONST(LightshaftsPS,	float4,		g_sun_pos,		k_ps_lightshafts_sun_pos)
	CBUFFER_CONST(LightshaftsPS,	float4,		g_inner_size,	k_ps_lightshafts_inner_size)
CBUFFER_END

#endif

#endif
