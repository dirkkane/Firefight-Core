#ifndef _FXAA_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _FXAA_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "fxaa_registers.h"

VERTEX_CONSTANT(float4,	TEXEL_SIZE,	k_vs_fxaa_texel_size)

#elif DX_VERSION == 11

CBUFFER_BEGIN(FXAAVS)
	CBUFFER_CONST(FXAAVS,	float4,		TEXEL_SIZE,		k_vs_fxaa_texel_size)
CBUFFER_END

#endif

#endif
