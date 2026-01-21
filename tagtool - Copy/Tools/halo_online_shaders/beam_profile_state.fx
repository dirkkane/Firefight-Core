#ifndef _BEAM_PROFILE_STATE_FX_
#define _BEAM_PROFILE_STATE_FX_

// Match with the fields of c_beam_gpu::s_layout.
struct s_profile_state
{
	float3	m_position;
	float	m_percentile;
	float2	m_offset;
	float	m_rotation;
	float4	m_color;
	float	m_thickness;
	float	m_black_point;
	float	m_palette;
	float	m_intensity;
};

#endif
