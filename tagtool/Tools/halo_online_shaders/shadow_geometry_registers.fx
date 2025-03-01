#ifndef _SHADOW_GEOMETRY_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _SHADOW_GEOMETRY_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "shadow_geometry_registers.h"

PIXEL_CONSTANT(float4, shadow_color, 	k_ps_shadow_geometry_color)

#elif DX_VERSION == 11

CBUFFER_BEGIN(ShadowGeometryPS)
	CBUFFER_CONST(ShadowGeometryPS,		float4,		shadow_color,		k_ps_shadow_geometry_color)
CBUFFER_END

#endif

#endif