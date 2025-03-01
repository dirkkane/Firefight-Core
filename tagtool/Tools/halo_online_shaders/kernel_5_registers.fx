#ifndef _KERNEL_5_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _KERNEL_5_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "kernel_5_registers.h"

PIXEL_CONSTANT(float4, kernel[5], k_ps_kernel_5_kernel);		// 5 tap kernel, (x offset, y offset, weight),  offsets should be premultiplied by pixel_size

#elif DX_VERSION == 11

CBUFFER_BEGIN(Kernel5PS)
	CBUFFER_CONST_ARRAY(Kernel5PS,	float4,		kernel, [5],	k_ps_kernel_5_kernel)
CBUFFER_END

#endif

#endif
