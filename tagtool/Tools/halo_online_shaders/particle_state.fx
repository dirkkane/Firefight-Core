#include "register_group.fx"

struct s_particle_state
{
	float3	m_position;
	float3	m_velocity;
	float3	m_axis;
	float	m_physical_rotation;
	float	m_manual_rotation;
	float	m_animated_frame;
	float	m_manual_frame;
	float	m_rotational_velocity;
	float	m_frame_velocity;
	float	m_birth_time;
	float	m_inverse_lifespan;
	float	m_age;
	float4	m_color;
	float4	m_initial_color;
	float4	m_random;
	float4	m_random2;
	float	m_size;
	float	m_aspect;
	float	m_intensity;
	float	m_black_point;
	float	m_palette_v;
};

#if DX_VERSION == 9

s_particle_state read_particle_state(int index)
{
	s_particle_state STATE;
#ifndef pc
	
#ifndef PARTICLE_READ_DISABLE_FOR_DEBUGGING
	float4 pos_sample;
	float4 vel_sample;
	float4 rot_sample;
	float4 time_sample;
	float4 anm_sample;
	float4 anm2_sample;
	float4 rnd_sample;
	float4 rnd2_sample;
	float4 axis_sample;
	float4 col_sample;
	float4 col2_sample;

   #ifndef PC_CPU
	   asm {
		   vfetch pos_sample, index.x, position1
		   vfetch vel_sample, index.x, position2
		   vfetch rot_sample, index.x, texcoord2
		   vfetch time_sample, index.x, texcoord3
		   vfetch anm_sample, index.x, texcoord4
		   vfetch anm2_sample, index.x, texcoord5
		   vfetch rnd_sample, index.x, position3
		   vfetch rnd2_sample, index.x, position4
		   vfetch axis_sample, index.x, normal1
		   vfetch col_sample, index.x, color
		   vfetch col2_sample, index.x, color1
	   };
	#elif defined (PC_CPU)

      byte* p = (byte*)g_cur_vertex_input_data;

      pos_sample  =  s_gpu_storage_4x32f::unpack(  *(real_vector4d*)p );   p += sizeof(real_vector4d);   // vfetch pos_sample, index.x, position1
	   vel_sample  =  s_gpu_storage_4x16f::unpack(  *(qword*)p );           p += sizeof(qword);           // vfetch vel_sample, index.x, position2
	   rnd_sample  =  s_gpu_storage_4x16un::unpack( *(qword*)p );           p += sizeof(qword);           // vfetch rnd_sample, index.x, position3
      rnd2_sample =  s_gpu_storage_4x16un::unpack( *(qword*)p );           p += sizeof(qword);           // vfetch rnd2_sample, index.x, position4
	   rot_sample  =  s_gpu_storage_4x16un::unpack( *(qword*)p );           p += sizeof(qword);           // vfetch rot_sample, index.x, texcoord2
      time_sample =  s_gpu_storage_4x16f::unpack(  *(qword*)p );           p += sizeof(qword);           // vfetch time_sample, index.x, texcoord3
      anm_sample  =  s_gpu_storage_2x16f::unpack(  *(dword*)p );           p += sizeof(dword);           // vfetch anm_sample, index.x, texcoord4
      anm2_sample =  s_gpu_storage_2x16un::unpack( *(dword*)p );           p += sizeof(dword);           // vfetch anm2_sample, index.x, texcoord5
      axis_sample =  s_gpu_storage_dec3n::unpack(  *(dword*)p );           p += sizeof(dword);           // vfetch axis_sample, index.x, normal1
      col_sample  =  s_gpu_storage_argb8::unpack(  *(dword*)p );           p += sizeof(dword);           // vfetch col_sample, index.x, color
      col2_sample =  s_gpu_storage_argb8::unpack(  *(dword*)p );           p += sizeof(dword);           // vfetch col2_sample, index.x, color1

   #endif

#else
	float4 pos_sample= unknown_value;
	float4 vel_sample= unknown_value;
	float4 rot_sample= unknown_value;
	float4 time_sample= unknown_value;
	float4 anm_sample= unknown_value;
	float4 rnd_sample= unknown_value;
	float4 rnd2_sample= unknown_value;
	float4 axis_sample= unknown_value;
	float4 col_sample= unknown_value;
	float4 col2_sample= unknown_value;
#endif

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	STATE.m_position= pos_sample.xyz;
	STATE.m_velocity= vel_sample.xyz;
	STATE.m_axis= axis_sample.xyz;
	STATE.m_birth_time= time_sample.x;
	STATE.m_age= time_sample.z;
	STATE.m_inverse_lifespan= time_sample.y;
	STATE.m_physical_rotation= rot_sample.x;
	STATE.m_manual_rotation= rot_sample.y;
	STATE.m_animated_frame= rot_sample.z;
	STATE.m_manual_frame= rot_sample.w;
	STATE.m_rotational_velocity= anm_sample.x;
	STATE.m_frame_velocity= anm_sample.y;
	STATE.m_color= col_sample;
	STATE.m_initial_color= col2_sample;
	STATE.m_random= rnd_sample;
	STATE.m_random2= rnd2_sample;
	STATE.m_size= pos_sample.w;
	STATE.m_aspect= vel_sample.w;
	STATE.m_intensity= time_sample.w;
	STATE.m_black_point= anm2_sample.x;
	STATE.m_palette_v= anm2_sample.y;
	
#endif // #ifndef pc

	return STATE;
}



#if (!defined(PC_CPU) && defined(pc))
s_particle_state read_particle_state_from_input(vertex_type vIN)
{
	s_particle_state STATE;
	
	// unpack pc values
	// D3DDECLTYPE_SHORT4N to D3DDECLTYPE_USHORT4N
	vIN.rot_sample  = 0.5 * (vIN.rot_sample + 1.0);
	vIN.rnd_sample  = 0.5 * (vIN.rnd_sample + 1.0);
	vIN.rnd2_sample = 0.5 * (vIN.rnd2_sample + 1.0);

	// D3DDECLTYPE_SHORT2N to D3DDECLTYPE_USHORT2N
	vIN.anm2_sample = 0.5 * (vIN.anm2_sample + 1.0);

	// D3DDECLTYPE_UBYTE4 to D3DDECLTYPE_DEC3N
	//vIN.axis_sample = vIN.axis_sample * 2.0f - 1.0f;
	vIN.axis_sample = (vIN.axis_sample / 255.0) * 2.0f - 1.0f;

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	STATE.m_position              = vIN.pos_sample.xyz;
	STATE.m_velocity              = vIN.vel_sample.xyz;
	STATE.m_axis                  = vIN.axis_sample.xyz;
	STATE.m_birth_time            = vIN.time_sample.x;
	STATE.m_age                   = vIN.time_sample.z;
	STATE.m_inverse_lifespan      = vIN.time_sample.y;
	STATE.m_physical_rotation     = vIN.rot_sample.x;
	STATE.m_manual_rotation       = vIN.rot_sample.y;
	STATE.m_animated_frame        = vIN.rot_sample.z;
	STATE.m_manual_frame          = vIN.rot_sample.w;
	STATE.m_rotational_velocity   = vIN.anm_sample.x;
	STATE.m_frame_velocity        = vIN.anm_sample.y;
	STATE.m_color                 = vIN.col_sample;
	STATE.m_initial_color         = vIN.col2_sample;
	STATE.m_random                = vIN.rnd_sample;
	STATE.m_random2               = vIN.rnd2_sample;
	STATE.m_size                  = vIN.pos_sample.w;
	STATE.m_aspect                = vIN.vel_sample.w;
	STATE.m_intensity             = vIN.time_sample.w;
	STATE.m_black_point           = vIN.anm2_sample.x;
	STATE.m_palette_v             = vIN.anm2_sample.y;

	return STATE;
}
#endif // (!defined(PC_CPU) && defined(pc))

#elif DX_VERSION == 11

#include "particle_pack.fx"

#ifdef COMPUTE_SHADER
	#ifdef PARTICLE_SPAWN
		#define particle_state_read_buffer cs_particle_state_spawn_buffer
	#else
		#define particle_state_read_buffer cs_particle_state_buffer
	#endif
#elif defined(VERTEX_SHADER)
	#define particle_state_read_buffer vs_particle_state_buffer
#endif

#if defined(COMPUTE_SHADER) || defined(VERTEX_SHADER)
s_particle_state read_particle_state(in int index)
{
	return unpack_particle_state(particle_state_read_buffer[index]);
}
#endif

#endif


#ifdef PARTICLE_WRITE

#if DX_VERSION == 9

#define _state_pos		0
#define _state_vel		1
#define	_state_rnd		2
#define _state_rnd2		3
#define _state_rot		4
#define _state_time		5
#define _state_anm		6
#define _state_anm2		7
#define _state_axis		8
#define _state_col		9
#define _state_col2		10
#define _state_max		11

struct s_memexport
{
	float4 m_stream_constant;
	float2 m_stride_offset;
};

BEGIN_REGISTER_GROUP(memexport)
PARAM_ARRAY(s_memexport, g_all_memexport, [_state_max]);
END_REGISTER_GROUP(memexport)

// The including function must define the stride_offset and stream_constant registers.
void write_particle_state(s_particle_state STATE, int index)
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
	export[_state_pos]= float4(STATE.m_position, STATE.m_size);
	export[_state_vel]= float4(STATE.m_velocity, STATE.m_aspect);
	export[_state_rot]= float4(STATE.m_physical_rotation, STATE.m_manual_rotation, STATE.m_animated_frame, STATE.m_manual_frame);
	export[_state_time]= float4(STATE.m_birth_time, STATE.m_inverse_lifespan, STATE.m_age, STATE.m_intensity);
	export[_state_anm]= float4(STATE.m_rotational_velocity, STATE.m_frame_velocity, 0.0f, 0.0f);
	export[_state_anm2]= float4(STATE.m_black_point, STATE.m_palette_v, 0.0f, 0.0f);
	export[_state_rnd]= float4(STATE.m_random);
	export[_state_rnd2]= float4(STATE.m_random2);
	export[_state_axis]= float4(STATE.m_axis, 0.0f);
	export[_state_col]= float4(STATE.m_color);
	export[_state_col2]= float4(STATE.m_initial_color);
#else
	export_v[_state_pos]= float4(STATE.m_position, STATE.m_size).toV4();
	export_v[_state_vel]= float4(STATE.m_velocity, STATE.m_aspect).toV4();
	export_v[_state_rot]= float4(STATE.m_physical_rotation, STATE.m_manual_rotation, STATE.m_animated_frame, STATE.m_manual_frame).toV4();
	export_v[_state_time]= float4(STATE.m_birth_time, STATE.m_inverse_lifespan, STATE.m_age, STATE.m_intensity).toV4();
	export_v[_state_anm]= float4(STATE.m_rotational_velocity, STATE.m_frame_velocity, 0.0f, 0.0f).toV4();
	export_v[_state_anm2]= float4(STATE.m_black_point, STATE.m_palette_v, 0.0f, 0.0f).toV4();
	export_v[_state_rnd]= float4(STATE.m_random).toV4();
	export_v[_state_rnd2]= float4(STATE.m_random2).toV4();
	export_v[_state_axis]= float4(STATE.m_axis, 0.0f).toV4();
	export_v[_state_col]= float4(STATE.m_color).toV4();
	export_v[_state_col2]= float4(STATE.m_initial_color).toV4();
#endif
	
	
	
#ifndef PARTICLE_WRITE_DISABLE_FOR_PROFILING

   #ifdef PC_CPU
      byte* p = (byte*)g_cur_vertex_output_data;
      *(real_vector4d*)p   = s_gpu_storage_4x32f::pack( export_v[_state_pos] );     p += sizeof(real_vector4d);
      *(qword*)p           = s_gpu_storage_4x16f::pack( export_v[_state_vel] );     p += sizeof(qword);
      *(qword*)p           = s_gpu_storage_4x16un::pack( export_v[_state_rnd] );    p += sizeof(qword);
      *(qword*)p           = s_gpu_storage_4x16un::pack( export_v[_state_rnd2] );   p += sizeof(qword);
      *(qword*)p           = s_gpu_storage_4x16un::pack( export_v[_state_rot] );    p += sizeof(qword);
      *(qword*)p           = s_gpu_storage_4x16f::pack( export_v[_state_time] );    p += sizeof(qword);
      *(dword*)p           = s_gpu_storage_2x16f::pack( export_v[_state_anm] );     p += sizeof(dword);
      *(dword*)p           = s_gpu_storage_2x16un::pack( export_v[_state_anm2] );   p += sizeof(dword);
      *(dword*)p           = s_gpu_storage_dec3n::pack( export_v[_state_axis] );    p += sizeof(dword);
      *(dword*)p           = s_gpu_storage_argb8::pack( export_v[_state_col] );     p += sizeof(dword);
      *(dword*)p           = s_gpu_storage_argb8::pack( export_v[_state_col2] );    p += sizeof(dword);
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

void write_particle_state(s_particle_state state, int index)
{
	cs_particle_state_buffer[index] = pack_particle_state(state);
}

#endif

#endif

#endif	//#ifdef PARTICLE_WRITE

