#ifndef _CUBEMAP_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _CUBEMAP_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "cubemap_registers.h"

// source texture size (width, height)
PIXEL_CONSTANT(float2, source_size, k_ps_cubemap_source_size);
PIXEL_CONSTANT(float3, forward, k_ps_cubemap_forward);
PIXEL_CONSTANT(float3, up, k_ps_cubemap_up);
PIXEL_CONSTANT(float3, left, k_ps_cubemap_left);
PIXEL_CONSTANT(float4, param, k_ps_cubemap_param);

#elif DX_VERSION == 11

CBUFFER_BEGIN(CubeMapPS)
	CBUFFER_CONST(CubeMapPS,	float2,		source_size,		k_ps_cubemap_source_size)
	CBUFFER_CONST(CubeMapPS,	float2,		source_size_pad,	k_ps_cubemap_source_size_pad)
	CBUFFER_CONST(CubeMapPS,	float3,		forward,			k_ps_cubemap_forward)
	CBUFFER_CONST(CubeMapPS,	float,		forward_pad,		k_ps_cubemap_forward_pad)
	CBUFFER_CONST(CubeMapPS,	float3,		up,					k_ps_cubemap_up)
	CBUFFER_CONST(CubeMapPS,	float,		up_pad,				k_ps_cubemap_up_pad)
	CBUFFER_CONST(CubeMapPS,	float3,		left,				k_ps_cubemap_left)
	CBUFFER_CONST(CubeMapPS,	float,		left_pad,			k_ps_cubemap_left_pad)
	CBUFFER_CONST(CubeMapPS,	float4,		param,				k_ps_cubemap_param)
CBUFFER_END

#endif

#endif
