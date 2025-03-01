#ifndef _CROP_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _CROP_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "crop_registers.h"

PIXEL_CONSTANT( float4, texcoord_xform,		k_ps_crop_texcoord_xform);
PIXEL_CONSTANT( float4, crop_bounds,		k_ps_crop_bounds);

#elif DX_VERSION == 11

CBUFFER_BEGIN(CropPS)
	CBUFFER_CONST(CropPS,	float4,		texcoord_xform,		k_ps_crop_texcoord_xform)
	CBUFFER_CONST(CropPS,	float4,		crop_bounds,		k_ps_crop_bounds)
CBUFFER_END

#endif

#endif