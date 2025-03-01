#ifndef _ROTATE_2D_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _ROTATE_2D_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "rotate_2d_registers.h"

PIXEL_CONSTANT( float2, offset, k_ps_rotate_2d_offset);

#elif DX_VERSION == 11

CBUFFER_BEGIN(Rotate2DPS)
	CBUFFER_CONST(Rotate2DPS,	float2,		offset,		k_ps_rotate_2d_offset)
CBUFFER_END

#endif

#endif
