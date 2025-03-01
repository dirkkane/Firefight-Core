#ifndef _CONTRAIL_STATE_FX_
#define _CONTRAIL_STATE_FX_

// Match with c_contrail_definition::e_appearance_flags
#define _contrail_tint_from_lightmap_bit			0	//_tint_from_lightmap_bit, 
#define _contrail_double_sided_bit					1	//_double_sided_bit, 
#define _contrail_profile_opacity_from_scale_a_bit	2	//_profile_opacity_from_scale_a_bit, 
#define _contrail_random_u_offset_bit				3	//_random_u_offset_bit, 
#define _contrail_random_v_offset_bit				4	//_random_v_offset_bit, 
#define _contrail_origin_faded_bit					5	//_origin_faded_bit, 
#define _contrail_edge_faded_bit					6	//_edge_faded_bit, 
#define _contrail_fogged_bit						7	//_fogged_bit, 

// Match with c_contrail_state::e_input
#define _state_profile_age				0	//_profile_age
#define _state_profile_random			1	//_profile_random
#define _state_profile_correlation_1	2	//_profile_correlation_1
#define _state_profile_correlation_2	3	//_profile_correlation_2
#define _state_profile_correlation_3	4	//_profile_correlation_3
#define _state_profile_correlation_4	5	//_profile_correlation_4
#define _state_game_time				6	//_game_time
#define _state_system_age				7	//_system_age 
#define _state_contrail_random			8	//_contrail_random 
#define _state_contrail_correlation_1	9	//_contrail_correlation_1
#define _state_contrail_correlation_2	10	//_contrail_correlation_2
#define _state_location_speed			11	//_location_speed 
#define _state_system_lod				12	//_system_lod 
#define _state_effect_a_scale			13	//_effect_a_scale
#define _state_effect_b_scale			14	//_effect_b_scale
#define _state_invalid					15	//_invalid
#define _state_total_count				16	//k_total_count
	
// Match with s_overall_state in c_contrail_gpu::set_shader_state()
struct s_gpu_single_state
{
	PADDED(float, 1, m_value)
};
struct s_fade
{
	float4 m__origin_range__origin_cutoff__edge_range__edge_cutoff;
#ifndef DEFINE_CPP_CONSTANTS
#define m_origin_range		m_fade.m__origin_range__origin_cutoff__edge_range__edge_cutoff.x
#define m_origin_cutoff		m_fade.m__origin_range__origin_cutoff__edge_range__edge_cutoff.y
#define m_edge_range		m_fade.m__origin_range__origin_cutoff__edge_range__edge_cutoff.z
#define m_edge_cutoff		m_fade.m__origin_range__origin_cutoff__edge_range__edge_cutoff.w
#endif
};
struct s_overall_state
{
	PADDED(float, 1, m_profile_type)
	PADDED(float, 1, m_ngon_sides)
	PADDED(float, 1, m_appearance_flags)
	PADDED(float, 1, m_num_profiles)
	PADDED(float, 2, m_uv_tiling_rate)
	PADDED(float, 2, m_uv_scroll_rate)
	PADDED(float, 2, m_uv_offset)
	PADDED(float, 1, m_game_time)
	PADDED(float, 3, m_origin)
	s_fade m_fade;
	s_gpu_single_state m_inputs[_state_total_count];
};

#endif