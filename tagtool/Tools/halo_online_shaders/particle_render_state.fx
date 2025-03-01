#ifndef _PARTICLE_RENDER_STATE_FX_
#define _PARTICLE_RENDER_STATE_FX_

struct s_motion_blur_state
{
	PADDED(float, 3, m_observer_velocity)
	PADDED(float, 3, m_observer_rotation)
	PADDED(float, 1, m_motion_blur_aspect_scale)
};

struct s_sprite_definition
{
	float4 m_corner;
};

struct s_fade
{
	float4 m__near_range__near_cutoff__edge_range__edge_cutoff;
#ifndef DEFINE_CPP_CONSTANTS
#define m_near_range		m_fade.m__near_range__near_cutoff__edge_range__edge_cutoff.x
#define m_near_cutoff		m_fade.m__near_range__near_cutoff__edge_range__edge_cutoff.y
#define m_edge_range		m_fade.m__near_range__near_cutoff__edge_range__edge_cutoff.z
#define m_edge_cutoff		m_fade.m__near_range__near_cutoff__edge_range__edge_cutoff.w
#endif
};

struct s_render_state
{
	PADDED(float, 1, m_main_flags)
	PADDED(float, 1, m_appearance_flags)
	PADDED(float, 1, m_animation_flags)
	PADDED(float, 1, m_first_person)	// available for further runtime flags
	PADDED(float, 1, m_curvature)
	PADDED(float, 2, m_uv_scroll_rate)
	PADDED(float, 1, m_game_time)
	PADDED(float, 1, m_billboard_type)
	PADDED(float, 1, m_vertex_count)
	s_fade m_fade;
};

#define _max_mesh_variants 15

// These structures are for support of mesh variants (particle models).  They need to match the declaration of:
//		c_particle_model_definition::s_gpu_variant_data
struct s_mesh_variant_definition
{
	float4 m_data;
#ifndef DEFINE_CPP_CONSTANTS
#define m_mesh_variant_start_index	m_data.x
#define m_mesh_variant_end_index	m_data.y
#endif
};

struct s_mesh_variant_list
{
#if DX_VERSION == 9
	int2 m_mesh_variant_list__count__max_size;
#elif DX_VERSION == 11
	PADDED(float, 2, m_mesh_variant_list__count__max_size)
#endif
	s_mesh_variant_definition m_mesh_variants[_max_mesh_variants];
#ifndef DEFINE_CPP_CONSTANTS
#define m_mesh_variant_count		m_mesh_variant_list__count__max_size.x
#define m_mesh_variant_max_size		m_mesh_variant_list__count__max_size.y
#endif
};

#define _max_sprite_frames 15

// These structures are for support of texture animation.  They need to match the declaration of:
//		c_particle_definition::s_gpu_frame_data
struct s_sprite_frame_definition
{
	float4 m_data;
#ifndef DEFINE_CPP_CONSTANTS
#define m_sprite_frame_uv		m_data
#endif
};

struct s_sprite_frame_list
{
#if DX_VERSION == 9
	int2 m_sprite_frame_list__count__max_size;
#elif DX_VERSION == 11
	PADDED(float, 2, m_sprite_frame_list__count__max_size)
#endif
	s_sprite_frame_definition m_sprite_frames[_max_sprite_frames];
#ifndef DEFINE_CPP_CONSTANTS
#define m_sprite_frame_count			m_sprite_frame_list__count__max_size.x
#define m_sprite_frame_max_size			m_sprite_frame_list__count__max_size.y
#endif
};

#endif
