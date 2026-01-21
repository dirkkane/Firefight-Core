#ifndef _BEAM_PROFILE_PACK_FX_
#define _BEAM_PROFILE_PACK_FX_

#if DX_VERSION == 11

#include "packed_vector.fx"
#include "raw_beam_profile_state.fx"

s_profile_state unpack_beam_profile_state(in s_raw_beam_profile_state input)
{
	float4 unpacked_misc = UnpackUShort4N(input.misc);
	float4 unpacked_misc2 = UnpackHalf4(input.misc2);

	s_profile_state output;
	output.m_position = input.pos.xyz;
	output.m_percentile = input.pos.w;
	output.m_offset = unpacked_misc2.zw;
	output.m_rotation = unpacked_misc.x;
	output.m_black_point = unpacked_misc.y;
	output.m_palette = unpacked_misc.z;
	output.m_thickness = unpacked_misc2.x;
	output.m_intensity = unpacked_misc2.y;
	output.m_color = UnpackARGB8(input.col);
	
	return output;
}

s_raw_beam_profile_state pack_beam_profile_state(in s_profile_state input)
{
	s_raw_beam_profile_state output;
	output.pos = float4(input.m_position, input.m_percentile);
	output.misc = PackUShort4N(float4(input.m_rotation, input.m_black_point, input.m_palette, 0));
	output.misc2 = PackHalf4(float4(input.m_thickness, input.m_intensity, input.m_offset));
	output.col = PackARGB8(input.m_color);
	output.pad = 0;
	return output;
}

#endif

#endif
