#ifndef _FUNCTION_DEFINITION_FX_
#define _FUNCTION_DEFINITION_FX_

#define _register_group_functions	1
#define _register_group_colors		2

#define _maximum_overall_function_count 25
#define _maximum_overall_color_count 8
#define _maximum_sub_function_count 4	//k_maximum_function_count

#define _periodic_function_one									0
#define _periodic_function_zero									1
#define _periodic_function_cosine								2
#define _periodic_function_cosine_with_random_period			3
#define _periodic_function_diagonal_wave						4
#define _periodic_function_diagonal_wave_with_random_period		5
#define _periodic_function_slide								6
#define _periodic_function_slide_with_random_period				7
#define _periodic_function_noise								8
#define _periodic_function_jitter								9
#define _periodic_function_wander								10
#define _periodic_function_spark								11
#define _periodic_function_max									12

#define _transition_function_linear		0
#define _transition_function_early		1 // x^0.5
#define _transition_function_very_early	2 // x^0.25
#define _transition_function_late		3 // x^2.0
#define _transition_function_very_late	4 // x^4.0
#define _transition_function_cosine		5 // accelerates in and out
#define _transition_function_one		6
#define _transition_function_zero		7
#define _transition_function_max		8

#define _type_identity 0			//_function_type_identity,			
#define _type_constant 1			//_function_type_constant,			
#define _type_transition 2			//_function_type_transition,			
#define _type_periodic 3			//_function_type_periodic,			
#define _type_linear 4				//_function_type_linear,				
#define _type_linear_key 5			//_function_type_linear_key,			
#define _type_multi_linear_key 6	//_function_type_multi_linear_key,	
#define _type_spline 7				//_function_type_spline,				
#define _type_multi_spline 8		//_function_type_multi_spline,		
#define _type_exponent 9			//_function_type_exponent,
#define _type_spline2 10			//_function_type_spline2,

#define _output_clamped_bit 2		//_function_flag_clamped_bit
#define _output_exclusion_bit 3		//_function_flag_exclusion_bit


// Max size of type-specific function innards
struct s_innards
{
	float4 m_unused1;
	float4 m_unused2;
};

struct s_function_definition
{
	float4 m_type_domain_max_range_min_range_max;
	float4 m_flags_exclusion_min_exclusion_max;
	
#ifndef DEFINE_CPP_CONSTANTS
#define m_type			m_type_domain_max_range_min_range_max.x	
#define m_domain_max	m_type_domain_max_range_min_range_max.y	
#define m_range_min		m_type_domain_max_range_min_range_max.z	
#define m_range_max		m_type_domain_max_range_min_range_max.w	
#define m_flags			m_flags_exclusion_min_exclusion_max.x
#define m_exclusion_min	m_flags_exclusion_min_exclusion_max.y
#define m_exclusion_max	m_flags_exclusion_min_exclusion_max.z
#endif
	
	s_innards m_innards;	// cast this to appropriate type
};

#endif