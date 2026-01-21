#ifndef _STENCIL_STIPPLE_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _STENCIL_STIPPLE_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "stencil_stipple_registers.h"

PIXEL_CONSTANT(float, block_size, k_ps_stencil_stipple_block_size);
PIXEL_CONSTANT(bool, odd_bits, k_ps_stencil_stipple_odd_bits);

#elif DX_VERSION == 11

CBUFFER_BEGIN(StencilStipplePS)
	CBUFFER_CONST(StencilStipplePS,		float,		block_size,		k_ps_stencil_stipple_block_size)
	CBUFFER_CONST(StencilStipplePS,		float3,		block_size_pad,	k_ps_stencil_stipple_block_size_pad)
	CBUFFER_CONST(StencilStipplePS,		bool,		odd_bits,		k_ps_stencil_stipple_odd_bits)
CBUFFER_END

#endif

#endif
