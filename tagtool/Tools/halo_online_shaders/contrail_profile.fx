#include "register_group.fx"

#ifndef _CONTRAIL_PROFILE_FX_
#define _CONTRAIL_PROFILE_FX_

// Match with c_contrail_gpu anonymous enum
#define k_profiles_per_row	(16) 
#define k_row_count			64 
#ifndef PC_CPU
   static int2 g_buffer_dims= int2(k_profiles_per_row, k_row_count);
#else
   static float2 g_buffer_dims= float2(k_profiles_per_row, k_row_count);
#endif
// Match with the fields of c_contrail_gpu::s_layout.
struct s_profile_state
{
	float3	m_position;
	float3	m_velocity;
	float	m_rotation;
	float	m_lifespan;
	float	m_age;
	float4	m_color;
	float4	m_initial_color;
	float	m_initial_alpha;
	float4	m_random;
	float	m_size;
	float	m_intensity;
	float	m_black_point;
	float	m_palette;
	float2	m_offset;
	float	m_length;
	float	m_dummy;	// this works around an internal compiler error
#if (DX_VERSION == 9) && (defined(pc))
	float3	m_direction;
#endif
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
	// Match with c_contrail_gpu::e_state, and with c_contrail_gpu::queue_profile().
	// Note that because of format specifications, state fields must be carefully assigned 
	// to an appropriate sample.
	float4 pos_sample;
	float4 vel_sample;
	float4 rnd_sample;
	float4 misc_sample_4x16f;
	float4 misc_sample_4x16un;
	float4 misc_sample_2x16f;
	float4 col_sample;
	float4 col2_sample;

   #ifdef PC_CPU
      byte* p = (byte*)g_cur_vertex_input_data;
      pos_sample =         s_gpu_storage_4x32f::unpack(  *(real_vector4d*)p );   p += sizeof(real_vector4d);   // real_vector4d
      vel_sample =         s_gpu_storage_4x16f::unpack(  *(qword*)p );           p += sizeof(qword);           // qword
      rnd_sample =         s_gpu_storage_4x16un::unpack( *(qword*)p );           p += sizeof(qword);           // qword
      misc_sample_4x16f =  s_gpu_storage_4x16f::unpack(  *(qword*)p );           p += sizeof(qword);           // qword
      misc_sample_4x16un = s_gpu_storage_4x16un::unpack( *(qword*)p );           p += sizeof(qword);           // qword
      misc_sample_2x16f =  s_gpu_storage_2x16f::unpack(  *(dword*)p );           p += sizeof(dword);           // dword
      col_sample =         s_gpu_storage_argb8::unpack(  *(dword*)p );           p += sizeof(dword);           // dword
      col2_sample =        s_gpu_storage_argb8::unpack(  *(dword*)p );           p += sizeof(dword);           // dword
   #elif !defined(pc)
	   asm {
		   vfetch pos_sample, index.x, position
		   vfetch vel_sample, index.x, position1
		   vfetch rnd_sample, index.x, position2
		   vfetch misc_sample_4x16f, index.x, texcoord0
		   vfetch misc_sample_4x16un, index.x, texcoord2
		   vfetch misc_sample_2x16f, index.x, texcoord3
		   vfetch col_sample, index.x, color
		   vfetch col2_sample, index.x, color1
	   };
   #endif

#else
	float4 pos_sample= unknown_value;
	float4 vel_sample= unknown_value;
	float4 rnd_sample= unknown_value;
	float4 misc_sample_4x16f= unknown_value;
	float4 misc_sample_4x16un= unknown_value;
	float4 misc_sample_2x16f= unknown_value;
	float4 col_sample= unknown_value;
	float4 col2_sample= unknown_value;
#endif

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	STATE.m_position= pos_sample.xyz;			// s_gpu_storage_4x32f
	STATE.m_age= pos_sample.w;
	STATE.m_velocity= vel_sample.xyz;			// s_gpu_storage_4x16f --- doesn't get fetched from render
	STATE.m_initial_alpha= vel_sample.w;
	STATE.m_random= rnd_sample;					// s_gpu_storage_4x16un --- doesn't get fetched from render
	STATE.m_size= misc_sample_4x16f.x;			// s_gpu_storage_4x16f --- doesn't get fetched from update
	STATE.m_intensity= misc_sample_4x16f.y;
	STATE.m_offset= misc_sample_4x16f.zw;

	STATE.m_rotation= misc_sample_4x16un.x;		// s_gpu_storage_4x16un --- doesn't get fetched from update
	STATE.m_black_point= misc_sample_4x16un.y;
	STATE.m_palette= misc_sample_4x16un.z;
	STATE.m_length= misc_sample_2x16f.x;		// s_gpu_storage_2x16f
	STATE.m_lifespan= misc_sample_2x16f.y;
	STATE.m_color= col_sample;					// s_gpu_storage_argb8 --- doesn't get fetched from update
	STATE.m_initial_color= col2_sample;				// s_gpu_storage_argb8 --- doesn't get fetched from update
	
	return STATE;
}

#if (!defined(PC_CPU) && defined(pc))
s_profile_state read_profile_state_from_input(vertex_type vIN)
{
	s_profile_state STATE;

	float4 pos_sample;
	float4 vel_sample;
	float4 rnd_sample;
	float4 misc_sample_4x16f;
	float4 misc_sample_4x16un;
	float4 misc_sample_2x16f;
	float4 col_sample;
	float4 col2_sample;
	float3 direction;

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	if(vIN.index.x == 0) {
	   pos_sample           = vIN.pos_sample;
	   vel_sample           = vIN.vel_sample;
	   rnd_sample           = vIN.rnd_sample;
	   misc_sample_4x16f    = vIN.misc_sample_4x16f;
	   misc_sample_4x16un   = vIN.misc_sample_4x16un;
	   misc_sample_2x16f    = vIN.misc_sample_2x16f;
	   col_sample           = vIN.col_sample;
	   col2_sample          = vIN.col2_sample;
	   direction            = vIN.next_pos_sample.xyz - vIN.pos_sample.xyz;
	} else {
	   pos_sample           = vIN.next_pos_sample;
	   vel_sample           = vIN.next_vel_sample;
	   rnd_sample           = vIN.next_rnd_sample;
	   misc_sample_4x16f    = vIN.next_misc_sample_4x16f;
	   misc_sample_4x16un   = vIN.next_misc_sample_4x16un;
	   misc_sample_2x16f    = vIN.next_misc_sample_2x16f;
	   col_sample           = vIN.next_col_sample;
	   col2_sample          = vIN.next_col2_sample;
	   if(vIN.index.x == 1) {
	      direction         = vIN.next_next_pos_sample.xyz - vIN.next_pos_sample.xyz;
	   } else { // draw ending part of contrail
	      direction         = vIN.next_pos_sample.xyz - vIN.pos_sample.xyz;
	   }
	}

	// unpack pc values
	// D3DDECLTYPE_SHORT4N to D3DDECLTYPE_USHORT4N
	rnd_sample 		      = 0.5 * (rnd_sample + 1.0);
	misc_sample_4x16un   = 0.5 * (misc_sample_4x16un + 1.0);

	STATE.m_position     = pos_sample.xyz;			   // s_gpu_storage_4x32f
	STATE.m_age          = pos_sample.w;
	STATE.m_velocity     = vel_sample.xyz;			   // s_gpu_storage_4x16f --- doesn't get fetched from render
	STATE.m_initial_alpha= vel_sample.w;
	STATE.m_random       = rnd_sample;					// s_gpu_storage_4x16un --- doesn't get fetched from render
	STATE.m_size         = misc_sample_4x16f.x;	   // s_gpu_storage_4x16f --- doesn't get fetched from update
	STATE.m_intensity    = misc_sample_4x16f.y;
	STATE.m_offset       = misc_sample_4x16f.zw;
	STATE.m_rotation     = misc_sample_4x16un.x;    // s_gpu_storage_4x16un --- doesn't get fetched from update
	STATE.m_black_point  = misc_sample_4x16un.y;
	STATE.m_palette      = misc_sample_4x16un.z;
	STATE.m_length       = misc_sample_2x16f.x;		// s_gpu_storage_2x16f
	STATE.m_lifespan     = misc_sample_2x16f.y;
	STATE.m_color        = col_sample;					// s_gpu_storage_argb8 --- doesn't get fetched from update
	STATE.m_initial_color= col2_sample;		         // s_gpu_storage_argb8 --- doesn't get fetched from update
	STATE.m_direction    = direction;

	return STATE;
}
#endif // (!defined(PC_CPU) && defined(pc))

#elif DX_VERSION == 11

#include "contrail_profile_pack.fx"

#ifdef COMPUTE_SHADER
	#define contrail_profile_state_buffer cs_contrail_profile_state_buffer
#elif defined(VERTEX_SHADER)
	#define contrail_profile_state_buffer vs_contrail_profile_state_buffer
#endif

#if defined(COMPUTE_SHADER) || defined(VERTEX_SHADER)
s_profile_state read_profile_state(in int index)
{
	return unpack_contrail_profile(contrail_profile_state_buffer[index]);
}
#endif

#endif

#ifdef MEMEXPORT_ENABLED

// Match with c_contrail_gpu::e_state.
#define _state_pos			0
#define _state_vel			1
#define	_state_rnd			2
#define _state_misc_4x16f	3
#define _state_misc_4x16un	4
#define _state_misc_2x16f	5
#define _state_col			6
#define _state_col2			7
#define _state_max			8

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
   static float4 stream_helper(0, 1, 0, 0);
    __vector4 export_v[_state_max];
#endif

#ifndef PC_CPU
	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	export[_state_pos]= float4(STATE.m_position, STATE.m_age);
	export[_state_vel]= float4(STATE.m_velocity, STATE.m_initial_alpha);
	export[_state_rnd]= float4(STATE.m_random);
	export[_state_misc_4x16f]= float4(STATE.m_size, STATE.m_intensity, STATE.m_offset);
	export[_state_misc_4x16un]= float4(STATE.m_rotation, STATE.m_black_point, STATE.m_palette, 0.0f);
	export[_state_misc_2x16f]= float4(STATE.m_length, STATE.m_lifespan, 0.0f, 0.0f);
	export[_state_col]= float4(STATE.m_color);
	export[_state_col2]= float4(STATE.m_initial_color);
#else

   export_v[_state_pos]= float4(STATE.m_position, STATE.m_age).toV4();
   export_v[_state_vel]= float4(STATE.m_velocity, STATE.m_initial_alpha).toV4();
   export_v[_state_rnd]= float4(STATE.m_random).toV4();
   export_v[_state_misc_4x16f]= float4(STATE.m_size, STATE.m_intensity, STATE.m_offset).toV4();
   export_v[_state_misc_4x16un]= float4(STATE.m_rotation, STATE.m_black_point, STATE.m_palette, 0.0f).toV4();
   export_v[_state_misc_2x16f]= float4(STATE.m_length, STATE.m_lifespan, 0.0f, 0.0f).toV4();
   export_v[_state_col]= float4(STATE.m_color).toV4();
   export_v[_state_col2]= float4(STATE.m_initial_color).toV4();
   
#endif
	
#ifndef WRITE_DISABLE_FOR_PROFILING

   #ifdef PC_CPU
      byte* p = (byte*)g_cur_vertex_output_data;
      *(real_vector4d*)p = s_gpu_storage_4x32f::pack( export_v[_state_pos] );    p += sizeof(real_vector4d);   // real_vector4d
      *(qword*)p = s_gpu_storage_4x16f::pack( export_v[_state_vel] );            p += sizeof(qword);           // qword
      *(qword*)p = s_gpu_storage_4x16un::pack( export_v[_state_rnd] );           p += sizeof(qword);           // qword
      *(qword*)p = s_gpu_storage_4x16f::pack( export_v[_state_misc_4x16f] );     p += sizeof(qword);           // qword
      *(qword*)p = s_gpu_storage_4x16un::pack( export_v[_state_misc_4x16un] );   p += sizeof(qword);           // qword
      *(dword*)p = s_gpu_storage_2x16f::pack( export_v[_state_misc_2x16f] );     p += sizeof(dword);           // dword
      *(dword*)p = s_gpu_storage_argb8::pack( export_v[_state_col] );            p += sizeof(dword);           // dword
      *(dword*)p = s_gpu_storage_argb8::pack( export_v[_state_col2] );           p += sizeof(dword);           // dword
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
		   mad eA.xyzw, hidden_from_compiler.y, hidden_from_compiler.yyyy, hidden_from_compiler.yyyy
	   };
	   asm {
	   alloc export=1
		   mad eA.xyzw, hidden_from_compiler.z, hidden_from_compiler.zzzz, hidden_from_compiler.zzzz
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
void write_profile_state(in s_profile_state state, in int index)
{
	cs_contrail_profile_state_buffer[index] = pack_contrail_profile(state);
}
#endif

#endif

#endif	//#ifdef MEMEXPORT_ENABLED

#endif
