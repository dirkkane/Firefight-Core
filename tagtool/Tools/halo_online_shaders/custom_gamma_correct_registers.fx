#ifndef _CUSTOM_GAMMA_CORRECT_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _CUSTOM_GAMMA_CORRECT_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "custom_gamma_correct_registers.h"

PIXEL_CONSTANT(float4, gamma_power, k_ps_custom_gamma_correct_power);		// gamma power, stored in red channel

#elif DX_VERSION == 11

CBUFFER_BEGIN(CustomGammaCorrectPS)
	CBUFFER_CONST(CustomGammaCorrectPS,		float4,		gamma_power,		k_ps_custom_gamma_correct_power)
CBUFFER_END

#endif

#endif
