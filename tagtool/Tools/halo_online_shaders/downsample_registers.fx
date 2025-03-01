#ifndef _DOWNSAMPLE_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _DOWNSAMPLE_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "downsample_registers.h"

PIXEL_CONSTANT(float4, intensity_vector, POSTPROCESS_EXTRA_PIXEL_CONSTANT_0);		// intensity vector (default should be NTSC weightings: 0.299, 0.587, 0.114)

#elif DX_VERSION == 11

CBUFFER_BEGIN(DownsamplePS)
	CBUFFER_CONST(DownsamplePS,		float4,		intensity_vector,		k_ps_downsample_intensity_vector)
CBUFFER_END

#endif

#endif
