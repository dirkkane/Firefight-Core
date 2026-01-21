#ifndef _PLAYER_EMBLEM_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _PLAYER_EMBLEM_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "player_emblem_registers.h"

PIXEL_CONSTANT(float4, emblem_color_background_argb, k_ps_emblem_color_background_argb);
PIXEL_CONSTANT(float4, emblem_color_icon1_argb, k_ps_emblem_color_icon1_argb);
PIXEL_CONSTANT(float4, emblem_color_icon2_argb, k_ps_emblem_color_icon2_argb);

#elif DX_VERSION == 11

CBUFFER_BEGIN(PlayerEmblemPS)
	CBUFFER_CONST(PlayerEmblemPS,	float4,		emblem_color_background_argb,		k_ps_emblem_color_background_argb)
	CBUFFER_CONST(PlayerEmblemPS,	float4,		emblem_color_icon1_argb, 			k_ps_emblem_color_icon1_argb)
	CBUFFER_CONST(PlayerEmblemPS,	float4,		emblem_color_icon2_argb, 			k_ps_emblem_color_icon2_argb)	
CBUFFER_END

#endif

#endif
