#ifndef _PARTICLE_PACK_FX_
#define _PARTICLE_PACK_FX_

#if DX_VERSION == 11

#include "packed_vector.fx"
#include "raw_particle_state.fx"

s_particle_state unpack_particle_state(in s_raw_particle_state input)
{
	float4 unpacked_rot = UnpackUShort4N(input.rot);
	float4 unpacked_time = UnpackHalf4(input.time);
	float2 unpacked_anm = UnpackHalf2(input.anm);
	float2 unpacked_anm2 = UnpackUShort2N(input.anm2);
	float4 unpacked_vel = UnpackHalf4(input.vel);

	s_particle_state output;
	output.m_position = input.pos.xyz;
	output.m_velocity = unpacked_vel.xyz;
	output.m_axis = UnpackDec3N(input.axis);
	output.m_birth_time = unpacked_time.x;
	output.m_age = unpacked_time.z;
	output.m_inverse_lifespan = unpacked_time.y;
	output.m_physical_rotation = unpacked_rot.x;
	output.m_manual_rotation = unpacked_rot.y;
	output.m_animated_frame = unpacked_rot.z;
	output.m_manual_frame = unpacked_rot.w;
	output.m_rotational_velocity = unpacked_anm.x;
	output.m_frame_velocity = unpacked_anm.y;
	output.m_color = UnpackARGB8(input.col);
	output.m_initial_color = UnpackARGB8(input.col2);
	output.m_random = UnpackUShort4N(input.rnd);
	output.m_random2 = UnpackUShort4N(input.rnd2);
	output.m_size = input.pos.w;
	output.m_aspect = unpacked_vel.w;
	output.m_intensity = unpacked_time.w;
	output.m_black_point = unpacked_anm2.x;
	output.m_palette_v = unpacked_anm2.y;
	
	return output;
}

s_raw_particle_state pack_particle_state(in s_particle_state input)
{
	s_raw_particle_state output;
	output.pos = float4(input.m_position, input.m_size);
	output.vel = PackHalf4(float4(input.m_velocity, input.m_aspect));
	output.rnd = PackUShort4N(input.m_random);
	output.rnd2 = PackUShort4N(input.m_random2);
	output.rot = PackUShort4N(float4(input.m_physical_rotation, input.m_manual_rotation, input.m_animated_frame, input.m_manual_frame));
	output.time = PackHalf4(float4(input.m_birth_time, input.m_inverse_lifespan, input.m_age, input.m_intensity));
	output.anm = PackHalf2(float2(input.m_rotational_velocity, input.m_frame_velocity));
	output.anm2 = PackUShort2N(float2(input.m_black_point, input.m_palette_v));
	output.axis = PackDec3N(input.m_axis);
	output.col = PackARGB8(input.m_color);
	output.col2 = PackARGB8(input.m_initial_color);
	output.padding = 0;
	
	return output;
}

#endif

#endif
