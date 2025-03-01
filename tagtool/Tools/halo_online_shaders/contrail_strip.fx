#ifndef _CONTRAIL_STRIP_FX_
#define _CONTRAIL_STRIP_FX_

// Match with s_strip in c_contrail_gpu::set_shader_strip()
#define k_max_rows_per_strip	8 

struct s_strip
{
	float m_row[k_max_rows_per_strip];
};

#ifdef DEFINE_CPP_CONSTANTS
#undef k_max_rows_per_strip
#endif

#endif
