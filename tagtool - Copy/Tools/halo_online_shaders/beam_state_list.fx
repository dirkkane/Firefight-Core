#ifndef _BEAM_STATE_LIST_FX_
#define _BEAM_STATE_LIST_FX_

// Match with c_beam_definition::e_appearance_flags
#define _beam_double_sided_bit			0	//_double_sided_bit, 
#define _beam_origin_faded_bit			1	//_origin_faded_bit, 
#define _beam_edge_faded_bit			2	//_edge_faded_bit, 
#define _beam_fogged_bit				3	//_fogged_bit, 


// Match with c_beam_state::e_input
#define _profile_capped_percentile		0	//_profile_capped_percentile
#define _profile_uncapped_percentile	1	//_profile_uncapped_percentile
#define _game_time						2	//_game_time
#define _system_age						3	//_system_age 
#define _beam_random					4	//_beam_random 
#define _beam_correlation_1				5	//_beam_correlation_1
#define _beam_correlation_2				6	//_beam_correlation_2
#define _beam_length					7	//_beam_length
#define _system_lod						8	//_system_lod 
#define _effect_a_scale					9	//_effect_a_scale
#define _effect_b_scale					10	//_effect_b_scale
#define _invalid						11	//_invalid
#define _state_total_count				12	//k_total_count
		
		
// Match with s_overall_state in c_beam_gpu::set_shader_state()
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
	PADDED(float, 1, m_offset)
	PADDED(float, 1, m_num_profiles)
	PADDED(float, 1, m_percentile_step)
	PADDED(float, 1, m_capped_length)
	PADDED(float, 1, m_cap_percentage)
	PADDED(float, 2, m_uv_tiling_rate)
	PADDED(float, 2, m_uv_scroll_rate)
	PADDED(float, 1, m_game_time)
	PADDED(float, 3, m_origin)
	PADDED(float, 3, m_direction)
	s_fade m_fade;
	s_gpu_single_state m_inputs[_state_total_count];
};

#endif