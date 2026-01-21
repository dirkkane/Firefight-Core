/*
DECAL_REGISTERS.FX
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
12/5/2005 11:50:57 AM (davcook)
	
*/

#if DX_VERSION == 9

#include "decal_registers.h"

VERTEX_CONSTANT(float4, sprite, k_vs_decal_sprite)
BOOL_CONSTANT(pixel_kill_enabled, k_vs_decal_pixel_kill_enabled)

PIXEL_CONSTANT(float, fade, k_ps_decal_fade)

#elif DX_VERSION == 11

CBUFFER_BEGIN(DecalVS)
	CBUFFER_CONST(DecalVS,		float4,		sprite,					k_vs_decal_sprite)
	CBUFFER_CONST(DecalVS,		bool,		pixel_kill_enabled,		k_vs_decal_pixel_kill_enabled)
CBUFFER_END			
			
CBUFFER_BEGIN(DecalPS)			
	CBUFFER_CONST(DecalPS,		float,		fade,					k_ps_decal_fade)
	CBUFFER_CONST(DecalPS,		float3,		fade_pad,				k_ps_decal_fade_pad)
CBUFFER_END

#endif
