/*
WIND_REGISTERS.FX
Copyright (c) Microsoft Corporation, 2007. all rights reserved.
3/29/2007 5:53:07 PM (davcook)
	
*/

#if DX_VERSION == 9

#include "wind_registers.h"

VERTEX_CONSTANT(float4, wind_data, k_vs_wind_data);
VERTEX_CONSTANT(float4, wind_data2, k_vs_wind_data2);
//VERTEX_CONSTANT(float4, wind_spot, 247);

SAMPLER_CONSTANT(wind_texture, 0);			// vertex shader

#elif DX_VERSION == 11

CBUFFER_BEGIN(WindVS)
	CBUFFER_CONST(WindVS,	float4,		wind_data,		k_vs_wind_data)
	CBUFFER_CONST(WindVS,	float4,		wind_data2,		k_vs_wind_data2)
CBUFFER_END


#ifndef DEFINE_CPP_CONSTANTS
LOCAL_SAMPLER_2D(wind_texture, 0);
#endif

#endif
