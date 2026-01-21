#ifndef _SNIPER_SCOPE_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _SNIPER_SCOPE_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "sniper_scope_registers.h"

PIXEL_CONSTANT(float4, texture_params, k_ps_sniper_scope_texture_params);

#elif DX_VERSION == 11

CBUFFER_BEGIN(SniperScopePS)
	CBUFFER_CONST(SniperScopePS,	float4,		texture_params,		k_ps_sniper_scope_texture_params)
CBUFFER_END

#endif

#endif
