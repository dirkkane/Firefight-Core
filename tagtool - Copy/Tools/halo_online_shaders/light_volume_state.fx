#ifndef _LIGHT_VOLUME_STATE_FX_
#define _LIGHT_VOLUME_STATE_FX_

// Match with c_light_volume_definition::e_appearance_flags

// Match with c_light_volume_state::e_input
#define _profile_percentile			0	//_profile_percentile
#define _game_time					1	//_game_time
#define _system_age					2	//_system_age 
#define _light_volume_random		3	//_light_volume_random 
#define _light_volume_correlation_1	4	//_light_volume_correlation_1
#define _light_volume_correlation_2	5	//_light_volume_correlation_2
#define _system_lod					6	//_system_lod 
#define _effect_a_scale				7	//_effect_a_scale
#define _effect_b_scale				8	//_effect_b_scale
#define _invalid					9	//_invalid
#define _state_total_count			10	//k_total_count
		
// Match with s_overall_state in c_light_volume_gpu::set_shader_state()
struct s_gpu_single_state
{
	PADDED(float, 1, m_value)
};
struct s_overall_state
{
	PADDED(float, 1, m_appearance_flags)
	PADDED(float, 1, m_brightness_ratio)
	PADDED(float, 1, m_offset)
	PADDED(float, 1, m_num_profiles)
	PADDED(float, 1, m_profile_distance)
	PADDED(float, 1, m_profile_length)
	PADDED(float, 3, m_origin)
	PADDED(float, 3, m_direction)
	s_gpu_single_state m_inputs[_state_total_count];
};

// Match with c_editable_property_base::e_output_modifier
#define _modifier_none			0	//_output_modifier_none
#define _modifier_add			1	//_output_modifier_add
#define _modifier_multiply		2	//_output_modifier_multiply

#endif