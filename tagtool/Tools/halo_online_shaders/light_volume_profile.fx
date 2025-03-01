#ifndef _LIGHT_VOLUME_PROFILE_FX_
#define _LIGHT_VOLUME_PROFILE_FX_

// Match with the fields of c_light_volume_gpu::s_layout.
struct s_profile_state
{
	float3	m_position;
	float	m_percentile;
	float4	m_color;
	float	m_thickness;
	float	m_intensity;
};

#if DX_VERSION == 9

#ifdef READ_DISABLE_FOR_DEBUGGING
// Choose something which won't cause the profile lifetime to be up...
extern float4 unknown_value : register(k_register_camera_forward);
#endif

s_profile_state read_profile_state(int index)
{
	s_profile_state STATE;
	
#ifndef READ_DISABLE_FOR_DEBUGGING
	// Match with c_light_volume_gpu::e_state, and with c_light_volume_gpu::queue_profile().
	// Note that because of format specifications, state fields must be carefully assigned 
	// to an appropriate sample.
	float4 pos_sample;
	float4 misc_sample_2x16f;
	float4 col_sample;

   #ifdef PC_CPU
      byte* p = (byte*)g_cur_vertex_input_data;
      pos_sample =         s_gpu_storage_4x32f::unpack(  *(real_vector4d*)p );   p += sizeof(real_vector4d);   // real_vector4d
      misc_sample_2x16f =  s_gpu_storage_2x16f::unpack(  *(dword*)p );           p += sizeof(dword);           // dword
      col_sample =         s_gpu_storage_argb8::unpack(  *(dword*)p );           p += sizeof(dword);           // dword
   #elif !defined(pc)
		asm {
			vfetch pos_sample, index.x, position
			vfetch misc_sample_2x16f, index.x, texcoord0
			vfetch col_sample, index.x, color
		};
	#endif
#else
	float4 pos_sample= unknown_value;
	float4 misc_sample_2x16f= unknown_value;
	float4 col_sample= unknown_value;
#endif

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	STATE.m_position= pos_sample.xyz;			// s_gpu_storage_4x32f
	STATE.m_percentile= pos_sample.w;
	STATE.m_thickness= misc_sample_2x16f.x;			// s_gpu_storage_4x16f
	STATE.m_intensity= misc_sample_2x16f.y;
	STATE.m_color= col_sample;					// s_gpu_storage_argb8
	
	return STATE;
}

#if (!defined(PC_CPU) && defined(pc))
s_profile_state read_profile_state_from_input(vertex_type vIN)
{
	s_profile_state STATE;

	float4 pos_sample;
	float4 misc_sample_2x16f;
	float4 col_sample;

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.

   pos_sample           = vIN.pos_sample;
   misc_sample_2x16f    = vIN.misc_sample_2x16f;
   col_sample           = vIN.col_sample;

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	STATE.m_position	= pos_sample.xyz;		// s_gpu_storage_4x32f
	STATE.m_percentile	= pos_sample.w;
	STATE.m_thickness	= misc_sample_2x16f.x;	// s_gpu_storage_4x16f
	STATE.m_intensity	= misc_sample_2x16f.y;
	STATE.m_color		= col_sample;			// s_gpu_storage_argb8

	return STATE;
}
#endif // (!defined(PC_CPU) && defined(pc))

#elif DX_VERSION == 11

#include "light_volume_profile_pack.fx"

#ifdef COMPUTE_SHADER
	#define light_volume_profile_state_buffer cs_light_volume_profile_state_buffer
#elif defined(VERTEX_SHADER)
	#define light_volume_profile_state_buffer vs_light_volume_profile_state_buffer
#endif

#if defined(COMPUTE_SHADER) || defined(VERTEX_SHADER)
s_profile_state read_profile_state(in int index)
{
	return unpack_light_volume_profile(light_volume_profile_state_buffer[index]);
}
#endif

#endif


#ifdef MEMEXPORT_ENABLED

// Match with c_light_volume_gpu::e_state.
#define _state_pos			0
#define _state_misc_2x16f	1
#define _state_col			2
#define _state_max			3

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

// The including function must define the stride_offset and stream_constant registers.
void write_profile_state(s_profile_state STATE, int index)
{
#ifndef PC_CPU
	static float4 stream_helper= {0, 1, 0, 0};
   float4 export[_state_max];
#else
    __vector4 export_v[_state_max];
#endif

#ifndef PC_CPU
	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	export[_state_pos]= float4(STATE.m_position, STATE.m_percentile);
	export[_state_misc_2x16f]= float4(STATE.m_thickness, STATE.m_intensity, 0.0f, 0.0f);
	export[_state_col]= float4(STATE.m_color);
#else
	export_v[_state_pos]= float4(STATE.m_position, STATE.m_percentile).toV4();
	export_v[_state_misc_2x16f]= float4(STATE.m_thickness, STATE.m_intensity, 0.0f, 0.0f).toV4();
	export_v[_state_col]= float4(STATE.m_color).toV4();
#endif


#ifndef WRITE_DISABLE_FOR_PROFILING
   #ifdef PC_CPU
      byte* p = (byte*)g_cur_vertex_output_data;
      *(real_vector4d*)p = s_gpu_storage_4x32f::pack( export_v[_state_pos] );    p += sizeof(real_vector4d);   // real_vector4d
      *(dword*)p = s_gpu_storage_2x16f::pack( export_v[_state_misc_2x16f] );     p += sizeof(dword);           // dword
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
	cs_light_volume_profile_state_buffer[index] = pack_light_volume_profile(state);
}
#endif

#endif

#endif	//#ifdef MEMEXPORT_ENABLED

#endif
