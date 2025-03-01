// These are the constants which we don't want to overwrite.  They need to 
// be declared here, whether or not we use them, so that the shader compiler 
// will not auto-assign things to them.
#include "hlsl_constant_persist.fx"
#include "contrail_registers.fx"

//#ifndef pc

#include "function.fx"	// For evaluating Guerilla functions

#define _register_group_properties		3
#define _register_group_memexport		4

#include "contrail_profile.fx"
#include "contrail_state.fx"

#if DX_VERSION == 9
PARAM_STRUCT(s_overall_state, g_all_state);
#endif

float get_state_value(const s_profile_state profile_state, int index)
{
	if (index== _state_profile_age)
	{
		return profile_state.m_age;
	}
	else if (index<= _state_profile_correlation_4)
	{
		return profile_state.m_random[index-_state_profile_correlation_1];
	}
	else	// a state which is independent of profile
	{
		return g_all_state.m_inputs[index].m_value;
	}
}

#include "contrail_property.fx"

float get_constant_value(s_property p)		{ return p.m_innards.x; }
int get_is_constant(s_property p)			{ return EXTRACT_BITS(p.m_innards.y, 21, 22); }	// 1 bit always
int get_function_index_green(s_property p)	{ return EXTRACT_BITS(p.m_innards.z, 17, 22); }	// 5 bits often	
int get_input_index_green(s_property p)		{ return EXTRACT_BITS(p.m_innards.w, 17, 22); }	// 5 bits often	
int get_function_index_red(s_property p)	{ return EXTRACT_BITS(p.m_innards.y, 0, 5); }	// 5 bits often	
int get_input_index_red(s_property p)		{ return EXTRACT_BITS(p.m_innards.y, 5, 10); }	// 5 bits rarely	
int get_color_index_lo(s_property p)		{ return EXTRACT_BITS(p.m_innards.w, 0, 3); }	// 3 bits rarely	
int get_color_index_hi(s_property p)		{ return EXTRACT_BITS(p.m_innards.w, 3, 6); }	// 3 bits rarely	
int get_modifier_index(s_property p)		{ return EXTRACT_BITS(p.m_innards.z, 0, 2); }	// 2 bits often	
int get_input_index_modifier(s_property p)	{ return EXTRACT_BITS(p.m_innards.z, 2, 7); }	// 5 bits rarely	

#if DX_VERSION == 9
BEGIN_REGISTER_GROUP(properties)
PARAM_ARRAY(s_property, g_all_properties, [_index_max]);
END_REGISTER_GROUP(properties)
#endif

// This generates multiple inlined calls to evaluate and get_state_value, which are 
// large functions.  If the inlining becomes an issue, we can use the loop 
// trick documented below.
float profile_evaluate(const s_profile_state profile_state, int type)
{
	s_property property= g_all_properties[type];
	if (get_is_constant(property))
	{
		return get_constant_value(property);
	}
	else
	{
		float input= get_state_value(profile_state, get_input_index_green(property));
		float output;
		if (get_function_index_red(property)!= _type_identity)	// hack for ranged, since 0 isn't used
		{
			float interpolate= get_state_value(profile_state, get_input_index_red(property));
			output= evaluate_scalar_ranged(get_function_index_green(property), get_function_index_red(property), input, 
				interpolate);
		}
		else
		{
			output= evaluate_scalar(get_function_index_green(property), input);
		}
		if (get_modifier_index(property)!= _modifier_none)
		{
			float modify_by= get_state_value(profile_state, get_input_index_modifier(property));
			if (get_modifier_index(property)== _modifier_add)
			{
				output+= modify_by;
			}
			else // if (get_modifier_index(property)== _modifier_multiply)
			{
				output*= modify_by;
			}
		}
		return output;
	}
}

float3 contrail_map_to_color_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_color_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

float2 contrail_map_to_vector2d_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_vector2d_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

float3 contrail_map_to_vector3d_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_vector3d_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}


#ifndef PC_CPU
   typedef float preevaluated_functions[_index_max];
   preevaluated_functions preevaluate_contrail_functions(s_profile_state STATE)
#else
   void preevaluate_contrail_functions(s_profile_state STATE, float* pre_evaluated_scalar)
#endif
{
	// The explicit initializations below are necessary to avoid uninitialized
	// variable errors.  I believe the excess initializations are stripped out.
#ifndef PC_CPU
   float pre_evaluated_scalar[_index_max]= {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, };
   #ifndef pc
	   [loop]
	#endif
#endif
	for (int loop_counter= 0; loop_counter< _index_max; ++loop_counter)
	{
		pre_evaluated_scalar[loop_counter]= profile_evaluate(STATE, loop_counter);
	}
#ifndef PC_CPU
	return pre_evaluated_scalar;
#endif
}

//#endif	// #ifndef pc