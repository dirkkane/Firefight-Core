#ifndef _DEBUG_2D_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _DEBUG_2D_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "debug_2d_registers.h"

PIXEL_CONSTANT(float4, fill_color, k_ps_debug_2d_fill_color);

#elif DX_VERSION == 11

CBUFFER_BEGIN(Debug2DPS)
	CBUFFER_CONST(Debug2DPS,	float4,		fill_color,		k_ps_debug_2d_fill_color)
CBUFFER_END

#endif

#endif
