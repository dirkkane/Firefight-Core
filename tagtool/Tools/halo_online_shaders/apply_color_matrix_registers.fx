#ifndef _APPLY_COLOR_MATRIX_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _APPLY_COLOR_MATRIX_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "apply_color_matrix_registers.h"

PIXEL_CONSTANT( float4, dest_red,	k_ps_apply_color_matrix_dest_red);
PIXEL_CONSTANT( float4, dest_green, k_ps_apply_color_matrix_dest_green);
PIXEL_CONSTANT( float4, dest_blue,	k_ps_apply_color_matrix_dest_blue);
PIXEL_CONSTANT( float4, dest_alpha, k_ps_apply_color_matrix_dest_alpha);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ApplyColorMatrixPS)
	CBUFFER_CONST(ApplyColorMatrixPS,	float4,		dest_red,		k_ps_apply_color_matrix_dest_red)
	CBUFFER_CONST(ApplyColorMatrixPS,	float4,		dest_green,		k_ps_apply_color_matrix_dest_green)
	CBUFFER_CONST(ApplyColorMatrixPS,	float4,		dest_blue,		k_ps_apply_color_matrix_dest_blue)
	CBUFFER_CONST(ApplyColorMatrixPS,	float4,		dest_alpha,		k_ps_apply_color_matrix_dest_alpha)
CBUFFER_END

#endif

#endif
