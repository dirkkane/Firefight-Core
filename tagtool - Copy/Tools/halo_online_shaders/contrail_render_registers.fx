/*
CONTRAIL_RENDER_REGISTERS.FX
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
12/5/2005 11:50:57 AM (davcook)
	
*/

#if DX_VERSION == 9

#include "contrail_render_registers.h"

VERTEX_CONSTANT(float4, hidden_from_compiler, k_vs_contrail_render_hidden_from_compiler)	// the compiler will complain if these are literals

#elif DX_VERSION == 11

#include "contrail_strip.fx"

CBUFFER_BEGIN(ContrailStrip)
	CBUFFER_CONST(ContrailStrip,	s_strip,	g_strip,		k_contrail_strip)
CBUFFER_END

#endif
