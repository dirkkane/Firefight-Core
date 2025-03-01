#ifndef _PARTICLE_STATE_LIST_FX_
#define _PARTICLE_STATE_LIST_FX_

// Match with c_particle_state_list::e_particle_state_input
#define _state_particle_age							0	//_particle_age
#define _state_system_age							1	//_system_age
#define _state_particle_random_seed					2	//_particle_random_seed
#define _state_system_random_seed					3	//_system_random_seed
#define _state_particle_correlation_1				4	//_particle_correlation_1
#define _state_particle_correlation_2				5	//_particle_correlation_2
#define _state_particle_correlation_3				6	//_particle_correlation_3
#define _state_particle_correlation_4				7	//_particle_correlation_4
#define _state_system_correlation_1					8	//_system_correlation_1
#define _state_system_correlation_2					9	//_system_correlation_2
#define _state_particle_emit_time					10	//_particle_emit_time
#define _state_location_lod							11	//_location_lod
#define _state_game_time							12	//_game_time
#define _state_object_a_out							13	//_object_a_out
#define _state_object_b_out							14	//_object_b_out
#define _state_particle_rotation					15	//_particle_rotation
#define _state_location_random_seed_1				16	//_location_random_seed_1
#define _state_particle_distance_from_emitter		17	//_particle_distance_from_emitter
#define _state_particle_rotation_dot_eye_forward	18	//_particle_rotation_dot_eye_forward
#define _state_particle_rotation_dot_eye_left		19	//_particle_rotation_dot_eye_left
#define _state_invalid								20	//_invalid
#define _state_particle_random_seed_5				21	//_particle_random_seed_5
#define _state_particle_random_seed_6				22	//_particle_random_seed_6
#define _state_particle_random_seed_7				23	//_particle_random_seed_7
#define _state_particle_random_seed_8				24	//_particle_random_seed_8
#define _state_system_random_seed_3					25	//_system_random_seed_3
#define _state_system_random_seed_4					26	//_system_random_seed_4
#define _state_total_count							27	//k_total_count

// Match with s_gpu_single_state in c_particle_emitter_gpu::set_shader_update_state()
struct s_gpu_single_state
{
	PADDED(float, 1, m_value)
};
struct s_all_state
{
	s_gpu_single_state m_inputs[_state_total_count];
};

#endif
