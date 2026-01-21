#ifndef _YUV_TO_RGB_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _YUV_TO_RGB_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "yuv_to_rgb_registers.h"

PIXEL_CONSTANT(float4, tor   ,	k_ps_yuv_to_rgb_tor);
PIXEL_CONSTANT(float4, tog   ,	k_ps_yuv_to_rgb_tog);
PIXEL_CONSTANT(float4, tob   ,	k_ps_yuv_to_rgb_tob);
PIXEL_CONSTANT(float4, consts,	k_ps_yuv_to_rgb_consts);

#elif DX_VERSION == 11

CBUFFER_BEGIN(YUVToRGBShaderPS)
	CBUFFER_CONST(YUVToRGBShaderPS,		float4, 		tor,		k_ps_yuv_to_rgb_tor)
	CBUFFER_CONST(YUVToRGBShaderPS,		float4, 		tog,		k_ps_yuv_to_rgb_tog)
	CBUFFER_CONST(YUVToRGBShaderPS,		float4, 		tob,		k_ps_yuv_to_rgb_tob)
	CBUFFER_CONST(YUVToRGBShaderPS,		float4, 		consts,		k_ps_yuv_to_rgb_consts)
CBUFFER_END

#endif

#endif
