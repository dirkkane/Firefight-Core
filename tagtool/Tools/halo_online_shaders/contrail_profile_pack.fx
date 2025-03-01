#ifndef _CONTRAIL_PACK_FX_
#define _CONTRAIL_PACK_FX_

#if DX_VERSION == 11

#include "packed_vector.fx"
#include "raw_contrail_profile.fx"

s_profile_state unpack_contrail_profile(in s_raw_contrail_profile input)
{
	float4 unpacked_vel = UnpackHalf4(input.vel);
	float4 unpacked_misc = UnpackHalf4(input.misc);
	float4 unpacked_misc2 = UnpackUShort4N(input.misc2);
	float2 unpacked_misc3 = UnpackHalf2(input.misc3);	

	s_profile_state output;
	output.m_position = input.pos.xyz;
	output.m_age = input.pos.w;
	output.m_velocity = unpacked_vel.xyz;
	output.m_initial_alpha = unpacked_vel.w;
	output.m_random = UnpackUShort4N(input.rnd);
	output.m_size = unpacked_misc.x;
	output.m_intensity = unpacked_misc.y;
	output.m_offset = unpacked_misc.zw;
	output.m_rotation = unpacked_misc2.x;
	output.m_black_point = unpacked_misc2.y;
	output.m_palette = unpacked_misc2.z;
	output.m_length = unpacked_misc3.x;
	output.m_lifespan = unpacked_misc3.y;
	output.m_color = UnpackARGB8(input.col);
	output.m_initial_color = UnpackARGB8(input.col2);
	
	return output;
}

s_raw_contrail_profile pack_contrail_profile(in s_profile_state input)
{
	s_raw_contrail_profile output;
	output.pos = float4(input.m_position, input.m_age);
	output.vel = PackHalf4(float4(input.m_velocity, input.m_initial_alpha));
	output.rnd = PackUShort4N(input.m_random);
	output.misc = PackHalf4(float4(input.m_size, input.m_intensity, input.m_offset));
	output.misc2 = PackUShort4N(float4(input.m_rotation, input.m_black_point, input.m_palette, 0));
	output.misc3 = PackHalf2(float2(input.m_length, input.m_lifespan));
	output.col = PackARGB8(input.m_color);
	output.col2 = PackARGB8(input.m_initial_color);
	output.padding  = 0;
	return output;
}

#endif

#endif
