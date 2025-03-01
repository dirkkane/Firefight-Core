#ifndef _IMPLICIT_HILL_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _IMPLICIT_HILL_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "implicit_hill_registers.h"

VERTEX_CONSTANT(float4, implicit_color, k_vs_implicit_hill_color);
VERTEX_CONSTANT(float4, implicit_z_scales, k_vs_implicit_hill_z_scales); // <lower_z_offset, lower_scale, upper_z_offset - lower_z_offset, upper_scale - lower_scale>
VERTEX_CONSTANT(float4, implicit_transform1, k_vs_implicit_hill_transform1);
VERTEX_CONSTANT(float4, implicit_transform2, k_vs_implicit_hill_transform2);
VERTEX_CONSTANT(float4, implicit_transform3, k_vs_implicit_hill_transform3);

VERTEX_CONSTANT(bool, implicit_use_zscales, k_vs_implicit_hill_use_zscales);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ImplicitHillVS)
	CBUFFER_CONST(ImplicitHillVS,	float4, 	implicit_color, 			k_vs_implicit_hill_color)
	CBUFFER_CONST(ImplicitHillVS,	float4, 	implicit_z_scales, 		    k_vs_implicit_hill_z_scales)
	CBUFFER_CONST(ImplicitHillVS,	float4, 	implicit_transform1, 	    k_vs_implicit_hill_transform1)
	CBUFFER_CONST(ImplicitHillVS,	float4, 	implicit_transform2, 	    k_vs_implicit_hill_transform2)
	CBUFFER_CONST(ImplicitHillVS,	float4, 	implicit_transform3, 	    k_vs_implicit_hill_transform3)
	CBUFFER_CONST(ImplicitHillVS,	bool, 		implicit_use_zscales, 	    k_vs_implicit_hill_use_zscales)
CBUFFER_END

#endif

#endif
