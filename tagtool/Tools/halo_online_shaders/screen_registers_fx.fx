#ifndef _SCREEN_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _SCREEN_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "screen_registers.h"

VERTEX_CONSTANT(float4, pixelspace_xform, 			k_vs_screen_pixelspace_xform)
VERTEX_CONSTANT(float4, screenspace_sampler_xform, 	k_vs_screen_screenspace_sampler_xform)
PIXEL_CONSTANT(float4, 	screenspace_xform,			k_ps_screen_screenspace_xform)


#elif DX_VERSION == 11

CBUFFER_BEGIN(ScreenVS)
	CBUFFER_CONST(ScreenVS,		float4,		pixelspace_xform,				k_vs_screen_pixelspace_xform)
	CBUFFER_CONST(ScreenVS,		float4,		screenspace_sampler_xform,		k_vs_screen_screenspace_sampler_xform)	
CBUFFER_END

CBUFFER_BEGIN(ScreenPS)
	CBUFFER_CONST(ScreenPS,		float4,		screenspace_xform,				k_ps_screen_screenspace_xform)
CBUFFER_END

#endif

#endif
