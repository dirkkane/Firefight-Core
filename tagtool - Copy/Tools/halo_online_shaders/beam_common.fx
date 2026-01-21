// These are the constants which we don't want to overwrite.  They need to 
// be declared here, whether or not we use them, so that the shader compiler 
// will not auto-assign things to them.
#include "hlsl_constant_persist.fx"
#include "beam_registers.fx"

#include "function.fx"	// For evaluating Guerilla functions


#define _register_group_properties		3
#define _register_group_memexport		4

// Match with c_beam_gpu anonymous enum
#define k_profiles_per_row	16 
#define k_row_count			128 
//static int2 g_buffer_dims= int2(k_profiles_per_row, k_row_count);

#if DX_VERSION == 9
PARAM(float4, g_hidden_from_compiler);
#endif

// Match with the fields of c_beam_gpu::s_layout.
struct s_profile_state
{
	float3	m_position;
	float	m_percentile;
	float2	m_offset;
	float	m_rotation;
	float4	m_color;
	float	m_thickness;
	float	m_black_point;
	float	m_palette;
	float	m_intensity;
};


#ifdef READ_DISABLE_FOR_DEBUGGING
// Choose something which won't cause the profile lifetime to be up...
extern float4 unknown_value : register(k_register_camera_forward);
#endif

#if DX_VERSION == 9

s_profile_state read_profile_state(int index)
{
	s_profile_state STATE;
	
#ifndef READ_DISABLE_FOR_DEBUGGING
	// Match with c_beam_gpu::e_state, and with c_beam_gpu::queue_profile().
	// Note that because of format specifications, state fields must be carefully assigned 
	// to an appropriate sample.
	float4 pos_sample;
	float4 misc_sample_4x16un;
	float4 misc_sample_4x16f;
	float4 col_sample;

	#ifdef PC_CPU
      byte* p = (byte*)g_cur_vertex_input_data;
      pos_sample =         s_gpu_storage_4x32f::unpack(  *(real_vector4d*)p );   p += sizeof(real_vector4d);   // real_vector4d
	  misc_sample_4x16un = s_gpu_storage_4x16un::unpack( *(qword*)p );           p += sizeof(qword);           // qword
	  misc_sample_4x16f =  s_gpu_storage_4x16f::unpack(  *(qword*)p );           p += sizeof(qword);           // qword
	  col_sample =         s_gpu_storage_argb8::unpack(  *(dword*)p );           p += sizeof(dword);           // dword
   #elif !defined(pc)
		asm {
			vfetch pos_sample, index.x, position
			vfetch misc_sample_4x16un, index.x, texcoord0
			vfetch misc_sample_4x16f, index.x, texcoord1
			vfetch col_sample, index.x, color
		};
	#endif
#else
	float4 pos_sample= unknown_value;
	float4 misc_sample_4x16un= unknown_value;
	float4 misc_sample_4x16f= unknown_value;
	float4 col_sample= unknown_value;
#endif

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	STATE.m_position= pos_sample.xyz;			// s_gpu_storage_4x32f
	STATE.m_percentile= pos_sample.w;
	STATE.m_offset= misc_sample_4x16f.zw;
	STATE.m_rotation= misc_sample_4x16un.x;		// s_gpu_storage_4x16un
	STATE.m_black_point= misc_sample_4x16un.y;
	STATE.m_palette= misc_sample_4x16un.z;
	STATE.m_thickness= misc_sample_4x16f.x;		// s_gpu_storage_2x16f
	STATE.m_intensity= misc_sample_4x16f.y;
	STATE.m_color= col_sample;					// s_gpu_storage_argb8
	
	return STATE;
}

#if (!defined(PC_CPU) && defined(pc))
s_profile_state read_profile_state_from_input(vertex_type vIN)
{
	s_profile_state STATE;
	
	float4 pos_sample;
	float4 misc_sample_4x16un;
	float4 misc_sample_4x16f;
	float4 col_sample;

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.

	if(vIN.index.x == 0) {
       pos_sample           = vIN.pos_sample;
       misc_sample_4x16un   = vIN.misc_sample_4x16un;
       misc_sample_4x16f    = vIN.misc_sample_4x16f;
       col_sample           = vIN.col_sample;
   } else {
       pos_sample           = vIN.next_pos_sample;
       misc_sample_4x16un   = vIN.next_misc_sample_4x16un;
       misc_sample_4x16f    = vIN.next_misc_sample_4x16f;
       col_sample           = vIN.next_col_sample;
   }

	// unpack pc values
	// D3DDECLTYPE_SHORT4N to D3DDECLTYPE_USHORT4N
	vIN.misc_sample_4x16un = 0.5 * (vIN.misc_sample_4x16un + 1.0);

	STATE.m_position= pos_sample.xyz;			// s_gpu_storage_4x32f
	STATE.m_percentile= pos_sample.w;
	STATE.m_offset= misc_sample_4x16f.zw;
	STATE.m_rotation= misc_sample_4x16un.x;		// s_gpu_storage_4x16un
	STATE.m_black_point= misc_sample_4x16un.y;
	STATE.m_palette= misc_sample_4x16un.z;
	STATE.m_thickness= misc_sample_4x16f.x;		// s_gpu_storage_2x16f
	STATE.m_intensity= misc_sample_4x16f.y;
	STATE.m_color= col_sample;					// s_gpu_storage_argb8

	return STATE;
}
#endif // (!defined(PC_CPU) && defined(pc))

#elif DX_VERSION == 11

#include "beam_profile_pack.fx"

#ifdef COMPUTE_SHADER
	#define beam_profile_state_buffer cs_beam_profile_state_buffer
#elif defined(VERTEX_SHADER)
	#define beam_profile_state_buffer vs_beam_profile_state_buffer
#endif

#if defined(COMPUTE_SHADER) || defined(VERTEX_SHADER)
s_profile_state read_profile_state(in int index)
{
	return unpack_beam_profile_state(beam_profile_state_buffer[index]);
}
#endif

#endif



//#ifdef MEMEXPORT_ENABLED

// Match with c_beam_gpu::e_state.
#define _state_pos			0
#define _state_misc_4x16un	1
#define _state_misc_4x16f	2
#define _state_col			3
#define _state_max			4

// Match with s_memexport in s_gpu_layout<t_num_states>::set_memexport()
struct s_memexport
{
	float4 m_stream_constant;
	PADDED(float, 2, m_stride_offset)
};

#if DX_VERSION == 9
BEGIN_REGISTER_GROUP(memexport)
PARAM_ARRAY(s_memexport, g_all_memexport, [_state_max]);
END_REGISTER_GROUP(memexport)
#endif


#if DX_VERSION == 9

// The including function must define the stride_offset and stream_constant registers.
void write_profile_state(s_profile_state STATE, int index)
{
#ifndef PC_CPU
	static float4 stream_helper= {0, 1, 0, 0};
   float4 export[_state_max];
#else
   static float4 stream_helper(0, 1, 0, 0);
    __vector4 export_v[_state_max];
#endif

#ifndef PC_CPU
	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	export[_state_pos]= float4(STATE.m_position, STATE.m_percentile);
	export[_state_misc_4x16un]= float4(STATE.m_rotation, STATE.m_black_point, STATE.m_palette, 0.0f);
	export[_state_misc_4x16f]= float4(STATE.m_thickness, STATE.m_intensity, STATE.m_offset);
	export[_state_col]= float4(STATE.m_color);
#else
	export_v[_state_pos]= float4(STATE.m_position, STATE.m_percentile).toV4();
	export_v[_state_misc_4x16un]= float4(STATE.m_rotation, STATE.m_black_point, STATE.m_palette, 0.0f).toV4();
	export_v[_state_misc_4x16f]= float4(STATE.m_thickness, STATE.m_intensity, STATE.m_offset).toV4();
	export_v[_state_col]= float4(STATE.m_color).toV4();
#endif

#ifndef WRITE_DISABLE_FOR_PROFILING
   #ifdef PC_CPU
      byte* p = (byte*)g_cur_vertex_output_data;
      *(real_vector4d*)p = s_gpu_storage_4x32f::pack( export_v[_state_pos] );    p += sizeof(real_vector4d);   // real_vector4d
	  *(qword*)p = s_gpu_storage_4x16un::pack( export_v[_state_misc_4x16un] );   p += sizeof(qword);           // qword
	  *(qword*)p = s_gpu_storage_4x16f::pack( export_v[_state_misc_4x16f] );     p += sizeof(qword);           // qword
	  *(dword*)p = s_gpu_storage_argb8::pack( export_v[_state_col] );            p += sizeof(dword);           // dword
   #elif !defined(pc)
		// Store result.  Some of these writes are not needed by all clients
		// (eg. rnd should only be written by spawn, not update).
		for (int state= 0; state< _state_max; ++state)
		{
			int state_index= index * g_all_memexport[state].m_stride_offset.x + g_all_memexport[state].m_stride_offset.y;
			float4 stream_constant= g_all_memexport[state].m_stream_constant;
			float4 export= export[state];
			asm {
			alloc export=1
				mad eA, state_index, stream_helper, stream_constant
				mov eM0, export
			};
		}
		// This is a workaround for a bug in >=Profile builds.  Without it, we get occasional 
		// bogus memexports from nowhere during effect-heavy scenes.
		asm {
		alloc export=1
			mad eA.xyzw, g_hidden_from_compiler.y, g_hidden_from_compiler.yyyy, g_hidden_from_compiler.yyyy
		};
		asm {
		alloc export=1
			mad eA.xyzw, g_hidden_from_compiler.z, g_hidden_from_compiler.zzzz, g_hidden_from_compiler.zzzz
		};
	#endif
#else	// do only enough writing to keep from culling any ALU calculations
	float4 all_export= float4(0,0,0,0);
    for (int state= 0; state< _state_max; ++state)
    {
		all_export+= export[state];
    }
	int state_index= index * g_all_memexport[0].m_stride_offset.x + g_all_memexport[0].m_stride_offset.y;
	float4 stream_constant= g_all_memexport[0].m_stream_constant;
	asm {
	alloc export=1
		mad eA, state_index, stream_helper, stream_constant
		mov eM0, all_export
	};
#endif
}

#elif DX_VERSION == 11

#ifdef COMPUTE_SHADER
void write_profile_state(s_profile_state state, int index)
{
	cs_beam_profile_state_buffer[index] = pack_beam_profile_state(state);
}
#endif

#endif

//#endif	//#ifdef MEMEXPORT_ENABLED

#include "beam_state_list.fx"

#if DX_VERSION == 9
PARAM_STRUCT(s_overall_state, g_all_state);
#endif

float get_state_value(const s_profile_state profile_state, int index)
{
	if (index== _profile_capped_percentile)
	{
		return profile_state.m_percentile;
	}
	else if (index== _profile_uncapped_percentile)
	{
		return profile_state.m_percentile * g_all_state.m_cap_percentage;
	}
	else	// a state which is independent of profile
	{
		return g_all_state.m_inputs[index].m_value;
	}
}

#include "beam_property.fx"

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

float3 beam_map_to_color_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_color_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

float2 beam_map_to_point2d_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_point2d_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

float2 beam_map_to_vector2d_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_vector2d_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

float3 beam_map_to_vector3d_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_vector3d_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

#ifndef PC_CPU
   typedef float preevaluated_functions[_index_max];
   preevaluated_functions preevaluate_beam_functions(s_profile_state STATE)
#else
   void preevaluate_beam_functions(s_profile_state STATE, float* pre_evaluated_scalar)
#endif
{
	// The explicit initializations below are necessary to avoid uninitialized
	// variable errors.  I believe the excess initializations are stripped out.
#ifndef PC_CPU
	float pre_evaluated_scalar[_index_max]= {0, 0, 0, 0, 0, 0, 0, 0, };
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

#include "beam_strip.fx"

#if DX_VERSION == 9
PARAM_STRUCT(s_strip, g_strip);
#endif

// Take the index from the vertex input semantic and translate it into the actual lookup 
// index in the vertex buffer.
#ifndef PC_CPU
int profile_index_to_buffer_index( int profile_index )
{
	int beam_row= round(profile_index / k_profiles_per_row);
	int profile_index_within_row= floor((profile_index + 0.5) % k_profiles_per_row);
	int buffer_row= g_strip.m_row[beam_row];

	return buffer_row * k_profiles_per_row + profile_index_within_row;
}
#else

int profile_index_to_buffer_index( int profile_index )
{
	int beam_row= profile_index / k_profiles_per_row;
	int profile_index_within_row= profile_index % k_profiles_per_row;
	int buffer_row= g_strip.m_row[beam_row];
	
	return buffer_row * k_profiles_per_row + profile_index_within_row;
}
#endif



//#endif	// #ifndef pc