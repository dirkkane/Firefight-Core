#ifndef _PARTICLE_PROPERTY_FX_
#define _PARTICLE_PROPERTY_FX_

#define _register_group_properties		3
#define _register_group_memexport		4

#define _modifier_none			0
#define _modifier_add			1
#define _modifier_multiply		2

// keep the index_ and bit_ #defines in sync!
#define _index_emitter_tint			0
#define _index_emitter_alpha		1
#define _index_emitter_size			2
#define _index_particle_color		3
#define _index_particle_intensity	4
#define _index_particle_alpha		5
#define _index_particle_scale		6
#define _index_particle_rotation	7
#define _index_particle_frame		8
#define _index_particle_black_point	9
#define _index_particle_aspect		10
#define _index_particle_self_acceleration 11
#define _index_particle_palette		12
#define _index_max					13

struct s_property 
{
	float4 m_innards;
};

#endif
