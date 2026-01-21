#ifndef _SSAO_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _SSAO_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "ssao_registers.h"

VERTEX_CONSTANT(float4, TEXCOORD_SCALE, k_vs_ssao_texcoord_scale);
VERTEX_CONSTANT(float4, VS_FRUSTUM_SCALE, k_vs_ssao_frustum_scale);

PIXEL_CONSTANT(float4, SSAO_PARAMS,	k_ps_ssao_params);
PIXEL_CONSTANT(float4, PS_FRUSTUM_SCALE, k_ps_ssao_frustum_scale);
PIXEL_CONSTANT(float4, PS_REG_SSAO_MV_1, k_ps_ssao_mv_1);
PIXEL_CONSTANT(float4, PS_REG_SSAO_MV_2, k_ps_ssao_mv_2);
PIXEL_CONSTANT(float4, PS_REG_SSAO_MV_3, k_ps_ssao_mv_3);

#elif DX_VERSION == 11

CBUFFER_BEGIN(SSAOVS)
	CBUFFER_CONST(SSAOVS,	float4,		TEXCOORD_SCALE,		k_vs_ssao_texcoord_scale)
	CBUFFER_CONST(SSAOVS,	float4,		VS_FRUSTUM_SCALE,	k_vs_ssao_frustum_scale)
CBUFFER_END

CBUFFER_BEGIN(SSAOPS)
	CBUFFER_CONST(SSAOPS,	float4,		SSAO_PARAMS,		k_ps_ssao_params)
	CBUFFER_CONST(SSAOPS,	float4,		PS_FRUSTUM_SCALE,	k_ps_ssao_frustum_scale)
	CBUFFER_CONST(SSAOPS,	float4,		PS_REG_SSAO_MV_1,	k_ps_ssao_mv_1)
	CBUFFER_CONST(SSAOPS,	float4,		PS_REG_SSAO_MV_2,	k_ps_ssao_mv_2)
	CBUFFER_CONST(SSAOPS,	float4,		PS_REG_SSAO_MV_3,	k_ps_ssao_mv_3)
CBUFFER_END

#endif

#endif
