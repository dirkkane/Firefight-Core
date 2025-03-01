#ifndef _COPY_TARGET_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _COPY_TARGET_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "copy_target_registers.h"

//PIXEL_CONSTANT(float2, pixel_size, c0);				// texcoord size of a single pixel (1 / (width), 1/(height))
PIXEL_CONSTANT(float4, intensity, k_ps_copy_target_intensity);		// natural, bloom, bling, persist

//PIXEL_CONSTANT(float4, test, c2);					// ###ctchou $REMOVE $DEBUG
//PIXEL_CONSTANT(float3, origin, c3);				// ###ctchou $REMOVE $DEBUG
//PIXEL_CONSTANT(float3, x_axis, c4);				// ###ctchou $REMOVE $DEBUG
//PIXEL_CONSTANT(float3, y_axis, c5);				// ###ctchou $REMOVE $DEBUG

PIXEL_CONSTANT(float4, tone_curve_constants, k_ps_copy_target_tone_curve_constants);	// max, linear, quadratic, cubic terms

#elif DX_VERSION == 11

CBUFFER_BEGIN(CopyTargetPS)
	CBUFFER_CONST(CopyTargetPS,		float4,		intensity,				k_ps_copy_target_intensity)
	CBUFFER_CONST(CopyTargetPS,		float4,		tone_curve_constants,	k_ps_copy_target_tone_curve_constants)
CBUFFER_END

#endif

#endif