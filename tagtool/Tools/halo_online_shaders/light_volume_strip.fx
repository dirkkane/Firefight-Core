#ifndef _LIGHT_VOLUME_STRIP_FX_
#define _LIGHT_VOLUME_STRIP_FX_

// Match with s_strip in c_light_volume_gpu::set_shader_strip()
#define k_max_rows_per_strip	8 
struct s_strip
{
	PADDED(float, 1, m_total_profile_count)
	float m_row[k_max_rows_per_strip];
};
#ifdef DEFINE_CPP_CONSTANTS
#undef k_max_rows_per_strip
#endif

#endif
