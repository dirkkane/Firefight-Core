#ifndef _LIGHT_VOLUME_PROFILE_PACK_FX_
#define _LIGHT_VOLUME_PROFILE_PACK_FX_

#if DX_VERSION == 11

#include "raw_light_volume_profile.fx"
#include "packed_vector.fx"

s_profile_state unpack_light_volume_profile(in s_raw_light_volume_profile input)
{
	float2 unpacked_misc = UnpackHalf2(input.misc);

	s_profile_state output;
	output.m_position = input.pos.xyz;
	output.m_percentile = input.pos.w;
	output.m_thickness = unpacked_misc.x;
	output.m_intensity = unpacked_misc.y;
	output.m_color = UnpackARGB8(input.col);
	return output;
}

s_raw_light_volume_profile pack_light_volume_profile(in s_profile_state input)
{
	s_raw_light_volume_profile output;
	output.pos = float4(input.m_position, input.m_percentile);
	output.misc = PackHalf2(float2(input.m_thickness, input.m_intensity));
	output.col = PackARGB8(input.m_color);
	output.padding = 0;
	return output;
}

#endif

#endif
