/*
CONTRAIL_UPDATE_REGISTERS.FX
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
12/5/2005 11:50:57 AM (davcook)
	
*/

#ifdef PC_CPU

float4 hidden_from_compiler;
float delta_time;

#elif DX_VERSION == 9

#include "contrail_update_registers.h"

VERTEX_CONSTANT(float4, hidden_from_compiler, k_vs_contrail_update_hidden_from_compiler)	// the compiler will complain if these are literals
VERTEX_CONSTANT(float, delta_time, k_vs_contrail_update_delta_time)

#elif DX_VERSION == 11

#include "contrail_property.fx"
#include "function_definition.fx"

CBUFFER_BEGIN(Contrail)
	CBUFFER_CONST_ARRAY(Contrail,	s_property,				g_all_properties, [_index_max],						k_contrail_all_properties)
	CBUFFER_CONST_ARRAY(Contrail,	s_function_definition,	g_all_functions, [_maximum_overall_function_count],	k_contrail_all_functions)
	CBUFFER_CONST_ARRAY(Contrail,	float4,					g_all_colors, [_maximum_overall_color_count],		k_contrail_all_colors)
CBUFFER_END

CBUFFER_BEGIN(ContrailUpdateVS)
	CBUFFER_CONST(ContrailUpdateVS,		float,		delta_time,					k_vs_contrail_update_delta_time)
CBUFFER_END

#define CS_CONTRAIL_UPDATE_THREADS 64

#endif
