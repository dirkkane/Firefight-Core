/*
WIND.FX
Copyright (c) Microsoft Corporation, 2007. all rights reserved.
3/29/2007 5:52:31 PM (davcook)
	
*/

#include "wind_registers.fx"

float2 sample_wind(float2 position)
{
	// apply wind
	float2 texc= position.xy * wind_data.z + wind_data.xy;			// calculate wind texcoord
	float4 wind_vector;
#ifndef pc
	asm {
		tfetch2D wind_vector, texc, wind_texture, MinFilter=linear, MagFilter=linear, UseComputedLOD=false, UseRegisterGradients=false
	};
#else 	
	wind_vector = sample2Dlod(wind_texture, texc, 0);
#endif	
	wind_vector.xy= wind_vector.xy * wind_data2.z + wind_data2.xy;			// scale motion and add in bend
	
	return wind_vector;
}
