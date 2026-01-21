// These are the constants which we don't want to overwrite.  They need to 
// be declared here, whether or not we use them, so that the shader compiler 
// will not auto-assign things to them.
#include "hlsl_constant_persist.fx"

//#ifndef pc

#ifndef PARTICLE_NO_PROPERTY_EVALUATE
	#include "function.fx"	// For evaluating Guerilla functions
#endif	//#ifndef PARTICLE_NO_PROPERTY_EVALUATE

#include "particle_property.fx"

#ifndef PARTICLE_NO_PROPERTY_EVALUATE

// The s_property struct is implemented internally with bitfields to save constant space.
// The EXTRACT_BITS macro should take 2-5 assembly instructions depending on whether the bits
// lie at the beginning/middle/end of the allowed range.

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

#endif	//#ifndef PARTICLE_NO_PROPERTY_EVALUATE

#ifdef PARTICLE_READ_DISABLE_FOR_DEBUGGING
// Choose something which won't cause the particle lifetime to be up...
extern float4 unknown_value : register(k_register_camera_forward);
#endif

#include "particle_state_list.fx"

#if DX_VERSION == 9
PARAM_STRUCT(s_all_state, g_all_state);
#endif

float get_state_value(const s_particle_state particle_state, int index)
{
	if (index==_state_particle_age)
	{
		return particle_state.m_age;
	}
	else if (index>= _state_particle_correlation_1 && index <= _state_particle_correlation_4)
	{
		return particle_state.m_random[index-_state_particle_correlation_1];
	}
	else if (index>= _state_particle_random_seed_5 && index <= _state_particle_random_seed_8)
	{
		return particle_state.m_random2[index-_state_particle_random_seed_5];
	}
	else if (index==_state_particle_emit_time)
	{
		return particle_state.m_birth_time;
	}
	else	// a state which is independent of particle
	{
		return g_all_state.m_inputs[index].m_value;
	}
}

#ifndef PARTICLE_NO_PROPERTY_EVALUATE
// This generates multiple inlined calls to evaluate and get_state_value, which are 
// large functions.  If the inlining becomes an issue, we can use the loop 
// trick documented below.
float particle_evaluate(const s_particle_state particle_state, int type)
{
	s_property property= g_all_properties[type];
	if (get_is_constant(property))
	{
		return get_constant_value(property);
	}
	else
	{
		float input= get_state_value(particle_state, get_input_index_green(property));
		float output;
		if (get_function_index_red(property)!= _type_identity)	// hack for ranged, since 0 isn't used
		{
			float interpolate= get_state_value(particle_state, get_input_index_red(property));
			output= evaluate_scalar_ranged(get_function_index_green(property), get_function_index_red(property), input, 
				interpolate);
		}
		else
		{
			output= evaluate_scalar(get_function_index_green(property), input);
		}
		if (get_modifier_index(property)!= _modifier_none)
		{
			float modify_by= get_state_value(particle_state, get_input_index_modifier(property));
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

float3 particle_map_to_color_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_color_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

float2 particle_map_to_vector2d_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_vector2d_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

float3 particle_map_to_vector3d_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_vector3d_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

#ifndef PC_CPU
   typedef float preevaluated_functions[_index_max];
   preevaluated_functions preevaluate_particle_functions(s_particle_state STATE)
#else
   void preevaluate_particle_functions(s_particle_state STATE, float* pre_evaluated_scalar)
#endif
{
	// The explicit initializations below are necessary to avoid uninitialized
	// variable errors.  I believe the excess initializations are stripped out.
#ifndef PC_CPU
	float pre_evaluated_scalar[_index_max]= {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, };
	#ifndef pc
	   [loop]
	#endif
#endif
	for (int loop_counter= 0; loop_counter< _index_max; ++loop_counter)
	{
		pre_evaluated_scalar[loop_counter]= particle_evaluate(STATE, loop_counter);
	}
#ifndef PC_CPU
	return pre_evaluated_scalar;
#endif
}
#endif	//#ifndef PARTICLE_NO_PROPERTY_EVALUATE


//#endif	// #ifndef pc

